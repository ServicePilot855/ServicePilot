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

async function seedBooking(id, providerId, status, extra = {}) {
  await request(`${documents}/bookings/${id}`, {
    method: 'PATCH',
    token: 'owner',
    body: {
      fields: fields({
        id,
        customerId: customer.id,
        providerId,
        providerName: 'Test Provider',
        serviceType: `Service ${status}`,
        description: 'Sample repair booking for BOOK-4 active work test.',
        address: 'St. 310, Phnom Penh',
        status,
        appointmentDate: { timestampValue: '2026-12-01T03:00:00Z' },
        confirmedAppointmentAt: { timestampValue: '2026-12-01T03:00:00Z' },
        confirmedBy: providerId,
        ...extra,
      }),
    },
  });
}

// Seed owned confirmed, assigned, in_progress, pending, and completed bookings.
await Promise.all([
  seedBooking('bk-indep-conf', independent.id, 'confirmed'),
  seedBooking('bk-indep-prog', independent.id, 'in_progress'),
  seedBooking('bk-indep-done', independent.id, 'completed'),
  seedBooking('bk-comp-conf', company.id, 'confirmed'),
  seedBooking('bk-comp-asgn', company.id, 'assigned', {
    technicianId: technician.id,
    technicianName: 'Sokha Tech',
  }),
  seedBooking('bk-comp-prog', company.id, 'in_progress', {
    technicianId: technician.id,
    technicianName: 'Sokha Tech',
  }),
  seedBooking('bk-comp-done', company.id, 'completed'),
]);

function activeQuery(providerId) {
  return {
    structuredQuery: {
      from: [{ collectionId: 'bookings' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            { fieldFilter: { field: { fieldPath: 'providerId' }, op: 'EQUAL', value: { stringValue: providerId } } },
            {
              fieldFilter: {
                field: { fieldPath: 'status' },
                op: 'IN',
                value: {
                  arrayValue: {
                    values: ['confirmed', 'assigned', 'in_progress'].map(s => ({ stringValue: s })),
                  },
                },
              },
            },
          ],
        },
      },
    },
  };
}

// 1. Independent provider sees only their own confirmed & in_progress active work.
const indepRows = await request(`${documents}:runQuery`, {
  method: 'POST', token: independent.token, body: activeQuery(independent.id), status: 200,
});
assert.deepEqual(
  indepRows.flatMap(r => r.document ? [r.document.fields.id.stringValue] : []).sort(),
  ['bk-indep-conf', 'bk-indep-prog'],
);

// 2. Company admin sees their own confirmed, assigned (with technicianName), and in_progress jobs.
const compRows = await request(`${documents}:runQuery`, {
  method: 'POST', token: company.token, body: activeQuery(company.id), status: 200,
});
assert.deepEqual(
  compRows.flatMap(r => r.document ? [r.document.fields.id.stringValue] : []).sort(),
  ['bk-comp-asgn', 'bk-comp-conf', 'bk-comp-prog'],
);
const assignedDoc = compRows.find(r => r.document?.fields.id.stringValue === 'bk-comp-asgn').document;
assert.equal(assignedDoc.fields.technicianName.stringValue, 'Sokha Tech');

// 3. Unrelated providers, technicians querying providerId, homeowners, and anon are denied (403).
for (const token of [outsider.token, independent.token, technician.token, customer.token, undefined]) {
  await request(`${documents}:runQuery`, {
    method: 'POST', token, body: activeQuery(company.id), status: 403,
  });
}
await request(`${documents}/bookings/bk-comp-asgn`, { token: outsider.token, status: 403 });
await request(`${documents}/bookings/bk-indep-conf`, { token: company.token, status: 403 });

console.log('BOOK-4 active work query, technician assignment, and provider isolation rules passed.');
