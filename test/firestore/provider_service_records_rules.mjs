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

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([k, v]) => {
    if (typeof v === 'number') return [k, { doubleValue: v }];
    if (typeof v === 'object' && v.timestampValue) return [k, v];
    return [k, { stringValue: String(v) }];
  }));
}

async function account(role, { status = 'active', companyId } = {}) {
  const { localId: id, idToken: token } = await request(
    `http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {
      method: 'POST',
      body: { email: `${crypto.randomUUID()}@example.test`, password: crypto.randomUUID(), returnSecureToken: true },
    },
  );
  await request(`${documents}/users/${id}`, {
    method: 'PATCH',
    token: 'owner',
    body: {
      fields: fields({
        id,
        fullName: `${role}-${id.slice(0, 6)}`,
        email: `${id}@example.test`,
        phoneNumber: '+85512345678',
        role,
        status,
        ...(role === 'company' && { companyId: companyId ?? id }),
        ...(role === 'company_technician' && { companyId }),
      }),
    },
  });
  return { id, token };
}

const [customer, independent, company, outsider] = await Promise.all([
  account('homeowner'),
  account('independent_provider'),
  account('company'),
  account('independent_provider'),
]);
const technician = await account('company_technician', { companyId: company.id });

const update = (path, values) => ({ update: { name: `${prefix}/${path}`, fields: values } });
const commit = (token, writes, status = 200) => request(`${documents}:commit`, {
  method: 'POST', token, body: { writes }, status,
});

const appointmentDate = { timestampValue: '2026-12-01T03:00:00Z' };
const previewFields = (serviceType, description) => ({
  ...fields({ serviceTitle: serviceType, description }),
  appointmentDate,
});

function bookingDoc(id, providerId, status, serviceType) {
  return fields({
    id,
    customerId: customer.id,
    providerId,
    providerName: 'Test Provider',
    serviceType,
    description: `Job notes for ${serviceType}`,
    address: 'Private Street 123, Phnom Penh',
    customerPhone: '012345678',
    status,
    appointmentDate,
  });
}

// 1. Completed bookings seeded & readable only by owning provider/company admin.
const compDoneId = crypto.randomUUID();
const indepDoneId = crypto.randomUUID();
await Promise.all([
  request(`${documents}/bookings/${compDoneId}`, {
    method: 'PATCH', token: 'owner',
    body: { fields: bookingDoc(compDoneId, company.id, 'completed', 'Completed Chiller Service') },
  }),
  request(`${documents}/bookings/${indepDoneId}`, {
    method: 'PATCH', token: 'owner',
    body: { fields: bookingDoc(indepDoneId, independent.id, 'completed', 'Completed AC Wash') },
  }),
]);

// 2. Customer creates a pending booking, then cancels it and archives into cancelledBookingRequests.
const cancelId = crypto.randomUUID();
const cancelBooking = bookingDoc(cancelId, company.id, 'pending', 'Cancelled Pipe Job');
const cancelPreview = previewFields('Cancelled Pipe Job', 'Job notes for Cancelled Pipe Job');

await commit(customer.token, [
  update(`bookings/${cancelId}`, cancelBooking),
  update(`providers/${company.id}/incomingBookingRequests/${cancelId}`, cancelPreview),
]);

// Forged cancelled archive with private address or non-cancelled status must fail (403).
await commit(customer.token, [
  update(`providers/${company.id}/cancelledBookingRequests/${cancelId}`, { ...cancelPreview, ...fields({ address: 'Leak' }) }),
], 403);
await commit(customer.token, [
  update(`providers/${company.id}/cancelledBookingRequests/${cancelId}`, cancelPreview),
], 403);

// Valid customer cancellation removes incoming preview and archives privacy-safe cancelled preview.
await commit(customer.token, [
  update(`bookings/${cancelId}`, { ...cancelBooking, status: { stringValue: 'cancelled' } }),
  { delete: `${prefix}/providers/${company.id}/incomingBookingRequests/${cancelId}` },
  update(`providers/${company.id}/cancelledBookingRequests/${cancelId}`, cancelPreview),
]);

// 3. Provider declines a pending booking and archives into declinedBookingRequests.
const declineId = crypto.randomUUID();
const declineBooking = bookingDoc(declineId, company.id, 'pending', 'Declined Wiring Job');
const declinePreview = previewFields('Declined Wiring Job', 'Job notes for Declined Wiring Job');
await commit(customer.token, [
  update(`bookings/${declineId}`, declineBooking),
  update(`providers/${company.id}/incomingBookingRequests/${declineId}`, declinePreview),
]);
await commit(company.token, [
  {
    ...update(`bookings/${declineId}`, fields({ status: 'declined', declinedReason: 'Outside area' })),
    updateMask: { fieldPaths: ['status', 'declinedReason'] },
  },
  update(`providers/${company.id}/declinedBookingRequests/${declineId}`, declinePreview),
  { delete: `${prefix}/providers/${company.id}/incomingBookingRequests/${declineId}` },
]);

// 4. Company admin reads its own completed, cancelled, and declined records; unrelated users get 403.
const completedQuery = (providerId) => ({
  structuredQuery: {
    from: [{ collectionId: 'bookings' }],
    where: {
      compositeFilter: {
        op: 'AND',
        filters: [
          { fieldFilter: { field: { fieldPath: 'providerId' }, op: 'EQUAL', value: { stringValue: providerId } } },
          { fieldFilter: { field: { fieldPath: 'status' }, op: 'EQUAL', value: { stringValue: 'completed' } } },
        ],
      },
    },
  },
});

const compCompleted = await request(`${documents}:runQuery`, {
  method: 'POST', token: company.token, body: completedQuery(company.id), status: 200,
});
assert.deepEqual(compCompleted.flatMap(r => r.document ? [r.document.fields.id.stringValue] : []), [compDoneId]);

const compCancelled = await request(`${documents}/providers/${company.id}/cancelledBookingRequests`, {
  token: company.token, status: 200,
});
assert.equal(compCancelled.documents.length, 1);
assert.equal(compCancelled.documents[0].fields.serviceTitle.stringValue, 'Cancelled Pipe Job');
assert.equal('address' in compCancelled.documents[0].fields, false);

const compDeclined = await request(`${documents}/providers/${company.id}/declinedBookingRequests`, {
  token: company.token, status: 200,
});
assert.equal(compDeclined.documents.length, 1);
assert.equal(compDeclined.documents[0].fields.serviceTitle.stringValue, 'Declined Wiring Job');

// Unrelated providers, technicians, homeowners, and anon cannot read another provider's history.
for (const token of [outsider.token, independent.token, technician.token, customer.token, undefined]) {
  await request(`${documents}:runQuery`, {
    method: 'POST', token, body: completedQuery(company.id), status: 403,
  });
  await request(`${documents}/providers/${company.id}/cancelledBookingRequests`, { token, status: 403 });
  await request(`${documents}/providers/${company.id}/declinedBookingRequests`, { token, status: 403 });
}
await request(`${documents}/bookings/${cancelId}`, { token: company.token, status: 403 });

console.log('BOOK-5 completed, cancelled archive, declined archive, and provider isolation rules passed.');
