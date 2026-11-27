import assert from 'node:assert/strict';

const project = 'demo-servicepilot';
const { FIREBASE_AUTH_EMULATOR_HOST: auth, FIRESTORE_EMULATOR_HOST: firestore } = process.env;
assert.match(auth ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
assert.match(firestore ?? '', /^(127\.0\.0\.1|localhost):\d+$/);

const prefix = `projects/${project}/databases/(default)/documents`;
const documents = `http://${firestore}/v1/${prefix}`;

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

function toValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') return { doubleValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(toValue) } };
  if (typeof value === 'object' && value.timestampValue) return value;
  return { stringValue: String(value) };
}

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)]));
}

const write = (path, data, token, status = 200) => request(`${documents}/${path}`, {
  method: 'PATCH',
  token,
  body: { fields: fields(data) },
  status,
});

async function account(role, { status = 'active', companyId, emailVerified = false } = {}) {
  const email = `${crypto.randomUUID()}@example.test`;
  const password = crypto.randomUUID();
  const authApi = `http://${auth}/identitytoolkit.googleapis.com/v1`;
  if (emailVerified) {
    await request(`${authApi}/projects/${project}/accounts`, {
      method: 'POST', token: 'owner', body: { email, password, emailVerified },
    });
  }
  const { localId: id, idToken: token } = await request(
    `${authApi}/accounts:${emailVerified ? 'signInWithPassword' : 'signUp'}?key=fake-key`,
    {
      method: 'POST',
      body: { email, password, returnSecureToken: true },
    },
  );
  await write(`users/${id}`, {
    id,
    fullName: `${role}-${id.slice(0, 6)}`,
    email: `${id}@example.test`,
    phoneNumber: '+85512345678',
    role,
    status,
    ...(role === 'company' && { companyId: companyId ?? id }),
    ...(role === 'company_technician' && { companyId }),
  }, 'owner');
  return { id, token, email };
}

const [customer, otherCustomer, suspendedCustomer, independent, company, outsider, pendingProvider, unverifiedProvider, missingApproval, wrongCompany] = await Promise.all([
  account('homeowner'),
  account('homeowner'),
  account('homeowner', { status: 'suspended' }),
  account('independent_provider'),
  // Admin approval updates the provider profile, while the signup account can remain pending.
  account('company', { status: 'pending_verification' }),
  account('independent_provider'),
  account('independent_provider', { status: 'pending_verification' }),
  account('independent_provider'),
  account('independent_provider'),
  account('company', { companyId: 'another-company' }),
]);
const companyTech = await account('company_technician', { companyId: company.id });

// Seed provider profiles and offerings via admin ('owner').
for (const [prov, providerType, status] of [
  [independent, 'independent', 'active'],
  [company, 'company', 'active'],
  [outsider, 'independent', 'active'],
  [pendingProvider, 'independent', 'pending_verification'],
  [unverifiedProvider, 'independent', 'active'],
  [missingApproval, 'independent', 'active'],
  [wrongCompany, 'company', 'active'],
]) {
  await write(`providers/${prov.id}`, {
    id: prov.id,
    name: `Provider ${prov.id.slice(0, 5)}`,
    providerType,
    status,
    ...(prov !== missingApproval && { isVerified: status === 'active' && prov !== unverifiedProvider }),
  }, 'owner');
}

const quoteOfferingIndep = 'off-quote-indep';
const quoteOfferingComp = 'off-quote-comp';
const fixedOffering = 'off-fixed-indep';
const inactiveQuoteOffering = 'off-quote-inactive';
const pendingProviderOffering = 'off-quote-pending-prov';

await Promise.all([
  write(`offerings/${quoteOfferingIndep}`, {
    id: quoteOfferingIndep, providerId: independent.id, categoryId: 'cat-ac',
    title: 'Inverter PCB Diagnosis', description: 'Requires on-site diagnostics.',
    pricingMode: 'quote_required', isActive: true,
  }, 'owner'),
  write(`offerings/${quoteOfferingComp}`, {
    id: quoteOfferingComp, providerId: company.id, categoryId: 'cat-plumbing',
    title: 'Sewer Line Assessment', description: 'Custom blueprint inspection.',
    pricingMode: 'quoteRequired', isActive: true,
  }, 'owner'),
  write(`offerings/${fixedOffering}`, {
    id: fixedOffering, providerId: independent.id, categoryId: 'cat-ac',
    title: 'Standard Coil Wash', description: 'Fixed-price wash.',
    pricingMode: 'fixed', price: 25.0, isActive: true,
  }, 'owner'),
  write(`offerings/${inactiveQuoteOffering}`, {
    id: inactiveQuoteOffering, providerId: independent.id, categoryId: 'cat-ac',
    title: 'Retired Quote Service', description: 'No longer active.',
    pricingMode: 'quote_required', isActive: false,
  }, 'owner'),
  write(`offerings/${pendingProviderOffering}`, {
    id: pendingProviderOffering, providerId: pendingProvider.id, categoryId: 'cat-ac',
    title: 'Unverified Provider Quote', description: 'Pending provider.',
    pricingMode: 'quote_required', isActive: true,
  }, 'owner'),
]);

function quotePayload(id, overrides = {}) {
  return {
    id,
    customerId: customer.id,
    customerName: 'Homeowner One',
    providerId: independent.id,
    providerName: 'Dara Technician',
    offeringId: quoteOfferingIndep,
    offeringTitle: 'Inverter PCB Diagnosis',
    categoryId: 'cat-ac',
    categoryName: 'Air Conditioner Repair & Care',
    description: 'Outdoor inverter board clicks and displays E5 error.',
    photos: ['https://res.cloudinary.com/demo/image/upload/v1/pcb.jpg'],
    status: 'requested',
    createdAt: { timestampValue: '2026-11-27T09:00:00Z' },
    ...overrides,
  };
}

// 1. Valid quote creations for both independent provider and company.
const indepQuoteId = crypto.randomUUID();
await write(`quoteRequests/${indepQuoteId}`, quotePayload(indepQuoteId), customer.token, 200);

const compQuoteId = crypto.randomUUID();
await write(`quoteRequests/${compQuoteId}`, quotePayload(compQuoteId, {
  providerId: company.id,
  providerName: 'FixCo',
  offeringId: quoteOfferingComp,
  offeringTitle: 'Sewer Line Assessment',
  photos: [],
}), customer.token, 200);

// 2. Read permissions & isolation:
// Customer and addressed provider can read; other customers, other providers, technicians, and anon get 403.
await request(`${documents}/quoteRequests/${indepQuoteId}`, { token: customer.token, status: 200 });
await request(`${documents}/quoteRequests/${indepQuoteId}`, { token: independent.token, status: 200 });
await request(`${documents}/quoteRequests/${compQuoteId}`, { token: company.token, status: 200 });

for (const deniedToken of [otherCustomer.token, outsider.token, company.token, companyTech.token, undefined]) {
  await request(`${documents}/quoteRequests/${indepQuoteId}`, { token: deniedToken, status: 403 });
}
await request(`${documents}/quoteRequests/${compQuoteId}`, { token: companyTech.token, status: 403 });
await request(`${documents}/quoteRequests/${compQuoteId}`, { token: independent.token, status: 403 });

// Provider query scoped to their own providerId succeeds; querying another providerId fails.
function providerQuery(providerId, quoteId) {
  const equals = (fieldPath, value) => ({ fieldFilter: { field: { fieldPath }, op: 'EQUAL', value } });
  const providerFilter = equals('providerId', { stringValue: providerId });
  return {
    structuredQuery: {
      from: [{ collectionId: 'quoteRequests' }],
      where: quoteId ? {
        compositeFilter: {
          op: 'AND',
          filters: [providerFilter, equals('__name__', { referenceValue: `${prefix}/quoteRequests/${quoteId}` })],
        },
      } : providerFilter,
    },
  };
}

const queryQuotes = (provider, providerId, quoteId, status = 200) => request(`${documents}:runQuery`, {
  method: 'POST', token: provider.token, body: providerQuery(providerId, quoteId), status,
});
const quoteIds = (results) => results.flatMap(r => r.document ? [r.document.fields.id.stringValue] : []);

for (const [provider, ownQuoteId, otherProvider] of [
  [independent, indepQuoteId, company],
  [company, compQuoteId, independent],
]) {
  assert.deepEqual(quoteIds(await queryQuotes(provider, provider.id)), [ownQuoteId]);
  assert.deepEqual(quoteIds(await queryQuotes(provider, provider.id, ownQuoteId)), [ownQuoteId]);
  await queryQuotes(provider, otherProvider.id, undefined, 403);
}
await queryQuotes(independent, independent.id, compQuoteId, 403);
await queryQuotes(outsider, independent.id, undefined, 403);
assert.deepEqual(quoteIds(await queryQuotes(outsider, outsider.id)), []);

for (const provider of [pendingProvider, unverifiedProvider, missingApproval, wrongCompany]) {
  const id = crypto.randomUUID();
  await write(`quoteRequests/${id}`, quotePayload(id, { providerId: provider.id }), 'owner');
  await request(`${documents}/quoteRequests/${id}`, { token: provider.token, status: 403 });
  await queryQuotes(provider, provider.id, undefined, 403);
}

// Seeded provider IDs differ from account IDs and require a verified email match.
const verifiedSeedOwner = await account('independent_provider', { emailVerified: true });
for (const [provider, status] of [[verifiedSeedOwner, 200], [outsider, 403]]) {
  const providerId = `seed-${provider.id}`;
  const id = crypto.randomUUID();
  await write(`providers/${providerId}`, {
    id: providerId, email: provider.email, type: 'independent', status: 'active',
  }, 'owner');
  await write(`quoteRequests/${id}`, quotePayload(id, { providerId }), 'owner');
  await request(`${documents}/quoteRequests/${id}`, { token: provider.token, status });
  const result = await queryQuotes(provider, providerId, undefined, status);
  if (status === 200) assert.deepEqual(quoteIds(result), [id]);
}

// 3. Invalid creations must all be rejected (403).
const invalidCases = [
  ['unauthenticated', undefined, {}],
  ['impersonated customerId', otherCustomer.token, {}],
  ['suspended homeowner', suspendedCustomer.token, { customerId: suspendedCustomer.id }],
  ['provider creating as customer', independent.token, { customerId: independent.id }],
  ['fixed-price offering', customer.token, { offeringId: fixedOffering }],
  ['inactive offering', customer.token, { offeringId: inactiveQuoteOffering }],
  ['mismatched offering/provider', customer.token, { providerId: company.id, offeringId: quoteOfferingIndep }],
  ['pending provider', customer.token, { providerId: pendingProvider.id, offeringId: pendingProviderOffering }],
  ['wrong initial status', customer.token, { status: 'quoted' }],
  ['prefilled quotedPrice', customer.token, { quotedPrice: 50.0 }],
  ['too short description', customer.token, { description: 'too short' }],
  ['whitespace description', customer.token, { description: '                    ' }],
  ['mismatched id field', customer.token, { id: 'wrong-id' }],
  ['more than 5 photos', customer.token, {
    photos: [1, 2, 3, 4, 5, 6].map(i => `https://res.cloudinary.com/demo/image/upload/v1/p${i}.jpg`),
  }],
  ['invalid photo url', customer.token, { photos: ['javascript:alert(1)'] }],
];

for (const [label, token, overrides] of invalidCases) {
  const badId = crypto.randomUUID();
  await write(`quoteRequests/${badId}`, quotePayload(badId, overrides), token, 403);
  await request(`${documents}/quoteRequests/${badId}`, { token: 'owner', status: 404 });
  void label;
}

// 4. Customer/provider cannot delete or tamper with the quote request in QUOTE-1.
await request(`${documents}/quoteRequests/${indepQuoteId}`, { method: 'DELETE', token: customer.token, status: 403 });
await request(`${documents}/quoteRequests/${indepQuoteId}`, { method: 'DELETE', token: independent.token, status: 403 });
await write(`quoteRequests/${indepQuoteId}`, quotePayload(indepQuoteId, { status: 'approved' }), customer.token, 403);

console.log('Quote request creation, provider association, and isolation rules passed.');
