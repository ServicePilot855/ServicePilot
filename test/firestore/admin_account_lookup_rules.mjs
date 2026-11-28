import assert from 'node:assert/strict';

const project = 'demo-servicepilot';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
assert.match(authHost ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
assert.match(firestoreHost ?? '', /^(127\.0\.0\.1|localhost):\d+$/);

const root = `projects/${project}/databases/(default)/documents`;
const documents = `http://${firestoreHost}/v1/${root}`;

async function request(url, { method = 'GET', token, body, status = 200 } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    ...(body && { body: JSON.stringify(body) }),
  });
  const data = await response.json();
  assert.equal(response.status, status, `${method} ${url}: ${JSON.stringify(data)}`);
  return data;
}

async function account(role, status = 'active', email = `${crypto.randomUUID()}@example.test`) {
  const user = await request(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`, {
    method: 'POST',
    body: { email, password: crypto.randomUUID(), returnSecureToken: true },
  });
  await request(`${documents}/users/${user.localId}`, {
    method: 'PATCH',
    token: 'owner',
    body: {
      fields: Object.fromEntries(Object.entries({
        id: user.localId, role, status, email, fullName: 'Lookup fixture', phoneNumber: '012000000',
      }).map(([key, stringValue]) => [key, { stringValue }])),
    },
  });
  return user;
}

function lookup(id, token, status = 200) {
  return request(`${documents}:runQuery`, {
    method: 'POST',
    token,
    status,
    body: {
      structuredQuery: {
        select: { fields: [{ fieldPath: 'role' }, { fieldPath: 'status' }] },
        from: [{ collectionId: 'users' }],
        where: {
          fieldFilter: {
            field: { fieldPath: '__name__' },
            op: 'EQUAL',
            value: { referenceValue: `${root}/users/${id}` },
          },
        },
        limit: 1,
      },
    },
  });
}

const [admin, customer, suspended, unverified] = await Promise.all([
  account('admin'),
  account('homeowner'),
  account('admin', 'suspended'),
  account('homeowner', 'active', `admin-${crypto.randomUUID()}@servicepilot.app`),
]);

const [match] = await lookup(customer.localId, admin.idToken);
assert.deepEqual(match.document.fields, {
  role: { stringValue: 'homeowner' },
  status: { stringValue: 'active' },
});
const empty = await lookup('missing-account', admin.idToken);
assert.ok(empty.every(result => !result.document));
await lookup(admin.localId, customer.idToken, 403);
await lookup(customer.localId, customer.idToken, 403);
await lookup(customer.localId, suspended.idToken, 403);
await lookup(customer.localId, unverified.idToken, 403);
await lookup(customer.localId, undefined, 403);
await request(`${documents}/users/${customer.localId}`, { token: customer.idToken });

console.log('Admin lookup projection, empty result, denied roles, and owner profile access passed.');
