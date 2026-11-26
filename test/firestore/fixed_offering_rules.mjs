import assert from 'node:assert/strict';

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
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    ...(body && { body: JSON.stringify(body) }),
  });
  const data = await response.json();
  assert.equal(response.status, status, `${method} ${url}: ${JSON.stringify(data)}`);
  return data;
}

function firestoreFields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => {
    if (typeof value === 'number') return [key, { doubleValue: value }];
    if (typeof value === 'boolean') return [key, { booleanValue: value }];
    return [key, { stringValue: value }];
  }));
}

function write(path, data, token, status = 200) {
  return request(`${documents}/${path}`, {
    method: 'PATCH', body: { fields: firestoreFields(data) }, token, status,
  });
}

async function provider(role, status = 'active') {
  const email = `${crypto.randomUUID()}@example.test`;
  const authApi = `http://${authHost}/identitytoolkit.googleapis.com/v1`;
  const { localId: id, idToken } = await request(`${authApi}/accounts:signUp?key=fake-key`, {
    method: 'POST',
    body: { email, password: crypto.randomUUID(), returnSecureToken: true },
  });
  const type = role === 'company' ? 'company' : 'independent';
  await write(`users/${id}`, {
    id, role, status, ...(role === 'company' && { companyId: id }),
  }, 'owner');
  await write(`providers/${id}`, {
    id, providerType: type, status, isVerified: status === 'active',
  }, 'owner');
  return { id, token: idToken, type };
}

const [technician, company, otherCompany, pending] = await Promise.all([
  provider('independent_provider'),
  provider('company'),
  provider('company'),
  provider('independent_provider', 'pending_verification'),
]);
await write('categories/cat-ac', { isActive: true }, 'owner');
await write('categories/cat-inactive', { isActive: false }, 'owner');

function listing(actor, overrides = {}) {
  return {
    id: crypto.randomUUID(),
    providerId: actor.id,
    providerType: actor.type,
    categoryId: 'cat-ac',
    title: 'Split Unit Wash',
    description: 'Deep cleaning and drain inspection.',
    pricingMode: 'fixed',
    price: 25.49,
    isActive: true,
    ...overrides,
  };
}

for (const actor of [technician, company]) {
  const record = listing(actor);
  await write(`offerings/${record.id}`, record, actor.token);
  const publicRecord = await request(`${documents}/offerings/${record.id}`);
  assert.deepEqual(publicRecord.fields, firestoreFields(record));
}

// A company association alone cannot grant publishing rights to another account.
await write(`users/${otherCompany.id}`, {
  id: otherCompany.id, role: 'company', status: 'active', companyId: company.id,
}, 'owner');

const invalidCases = [
  [company, otherCompany.token, {}],
  [technician, undefined, {}],
  [pending, pending.token, {}],
  [technician, technician.token, { categoryId: 'cat-inactive' }],
  [technician, technician.token, { categoryId: 'cat-missing' }],
  [technician, technician.token, { title: '   ' }],
  ...[undefined, 0, -1, 0.001].map(price => [technician, technician.token, { price }]),
];
for (const [actor, token, overrides] of invalidCases) {
  const record = listing(actor, overrides);
  if (record.price === undefined) delete record.price;
  await write(`offerings/${record.id}`, record, token, 403);
  await request(`${documents}/offerings/${record.id}`, { token: 'owner', status: 404 });
}
console.log('Fixed offering persistence, public visibility, and rule isolation passed.');
