import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

// Run with the Firebase Auth and Firestore emulators for the demo project.
const project = 'demo-servicepilot';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
assert.match(authHost ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
assert.match(firestoreHost ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const documents = `http://${firestoreHost}/v1/projects/${project}/databases/(default)/documents`;

async function request(url, { method = 'GET', token, body, status = 200 } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      ...(token && { Authorization: `Bearer ${token}` }),
      'Content-Type': 'application/json',
    },
    ...(body && { body: JSON.stringify(body) }),
  });
  const data = await response.json();
  assert.equal(response.status, status, `${method} ${url}: ${JSON.stringify(data)}`);
  return data;
}

function fieldValue(value) {
  if (typeof value === 'number') return { integerValue: String(value) };
  if (typeof value === 'boolean') return { booleanValue: value };
  return { stringValue: value };
}

const fields = (data) => Object.fromEntries(
  Object.entries(data).map(([key, value]) => [key, fieldValue(value)]),
);

function documentWrite(path, data) {
  return {
    update: {
      name: `projects/${project}/databases/(default)/documents/${path}`,
      fields: fields(data),
    },
    currentDocument: { exists: false },
  };
}

const authApi = `http://${authHost}/identitytoolkit.googleapis.com/v1`;
const password = randomUUID();

async function authenticate(operation, email) {
  return request(`${authApi}/accounts:${operation}?key=fake-key`, {
    method: 'POST', body: { email, password, returnSecureToken: true },
  });
}

async function verifyFixtureEmail(localId, claims = {}) {
  await request(`${authApi}/projects/${project}/accounts:update`, {
    method: 'POST', token: 'owner',
    body: { localId, emailVerified: true, customAttributes: JSON.stringify(claims) },
  });
}

async function registerCompany(name) {
  const email = `${name}@example.test`;
  const { idToken, localId } = await authenticate('signUp', email);
  await request(`${documents}/users/${localId}`, { token: idToken, status: 404 });
  await request(`${documents}/providers/${localId}`, { token: idToken, status: 404 });
  await request(`${documents}:commit`, {
    method: 'POST',
    token: idToken,
    body: { writes: [
      documentWrite(`users/${localId}`, {
        id: localId, companyId: localId, fullName: name, email,
        phoneNumber: '+85511223344', role: 'company', status: 'pending_verification',
      }),
      documentWrite(`providers/${localId}`, {
        id: localId, businessName: name, providerType: 'company',
        status: 'pending_verification', isVerified: false, serviceArea: 'Dangkao',
      }),
    ] },
  });
  return { id: localId, token: idToken, email };
}

const company = await registerCompany('company-a');
const other = await registerCompany('company-b-admin');
await verifyFixtureEmail(other.id);
const otherToken = (await authenticate('signInWithPassword', other.email)).idToken;
const adminEmail = 'platform-staff@example.test';
const admin = await authenticate('signUp', adminEmail);
await verifyFixtureEmail(admin.localId, { admin: true });
const adminToken = (await authenticate('signInWithPassword', adminEmail)).idToken;

const profile = `${documents}/providers/${company.id}`;
const membership = `${documents}/users/${company.id}`;
await request(membership, { token: company.token });
await request(membership, { token: otherToken, status: 403 });
await request(membership, { token: adminToken });
const change = {
  businessName: 'Updated Company',
  description: 'Home repairs',
  serviceArea: 'Sen Sok',
  telegramUrl: 'https://t.me/company_a',
};

async function edit(data, token, status = 200, removed = []) {
  await request(`${documents}:commit`, {
    method: 'POST', token, status,
    body: { writes: [{
      update: {
        name: `projects/${project}/databases/(default)/documents/providers/${company.id}`,
        fields: fields(data),
      },
      updateMask: { fieldPaths: [...Object.keys(data), ...removed] },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: true },
    }] },
  });
}

await edit(change, company.token);
await request(profile, { status: 403 });
await edit({ ...change, status: 'active' }, company.token, 403);

await request(`${profile}?updateMask.fieldPaths=status&updateMask.fieldPaths=isVerified`, {
  method: 'PATCH', token: adminToken,
  body: { fields: { ...fields({ status: 'active' }), isVerified: { booleanValue: true } } },
});

change.serviceArea = 'Tuol Kork';
await edit(change, company.token);
await edit({ ...change, businessName: 'Unauthorized' }, otherToken, 403);
await edit({ ...change, telegramUrl: 'https://t.me.example.test/company_a' }, company.token, 403);
await edit({ ...change, rating: 5 }, company.token, 403);

const published = await request(profile);
for (const [key, value] of Object.entries(change)) {
  assert.equal(published.fields[key].stringValue, value);
}
assert.equal(published.fields.status.stringValue, 'active');
assert.equal(published.fields.isVerified.booleanValue, true);

const { telegramUrl, ...withoutTelegram } = change;
await edit(withoutTelegram, company.token, 200, ['telegramUrl']);
assert.equal((await request(profile)).fields.telegramUrl, undefined);
console.log('Company profile Firestore rules passed.');
