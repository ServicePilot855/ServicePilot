// TECHJOB-1 (SCRUM-100 / SCRUM-180): a company technician can list and open
// only the active jobs assigned to them. Run from the repository root:
// firebase emulators:exec --only auth,firestore --project demo-servicepilot "node test/firestore/technician_jobs_rules.mjs"
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
        ...(role === 'company' && { companyId: id }),
        ...(role === 'company_technician' && { companyId }),
      }),
    },
  });
  return { id, token };
}

const [company, otherCompany, customer] = await Promise.all([
  account('company'),
  account('company'),
  account('homeowner'),
]);
const [assignedTech, teammate, outsider, suspended] = await Promise.all([
  account('company_technician', { companyId: company.id }),
  account('company_technician', { companyId: company.id }),
  account('company_technician', { companyId: otherCompany.id }),
  account('company_technician', { companyId: company.id, status: 'suspended' }),
]);

async function seedBooking(id, providerId, status, technicianId) {
  await request(`${documents}/bookings/${id}`, {
    method: 'PATCH',
    token: 'owner',
    body: {
      fields: fields({
        id,
        customerId: customer.id,
        providerId,
        providerName: 'Test Company',
        serviceType: `Service ${id}`,
        description: 'Kitchen tap drips all night.',
        address: 'St. 310, Phnom Penh',
        status,
        totalPrice: 42.5,
        appointmentDate: { timestampValue: '2026-12-01T03:00:00Z' },
        confirmedAppointmentAt: { timestampValue: '2026-12-01T03:00:00Z' },
        confirmedBy: providerId,
        ...(technicianId && { technicianId, technicianName: 'Tech' }),
      }),
    },
  });
}

await Promise.all([
  seedBooking('job-assigned', company.id, 'assigned', assignedTech.id),
  seedBooking('job-progress', company.id, 'in_progress', assignedTech.id),
  seedBooking('job-confirmed', company.id, 'confirmed'),
  seedBooking('job-completed', company.id, 'completed', assignedTech.id),
  seedBooking('job-cancelled', company.id, 'cancelled', assignedTech.id),
  seedBooking('job-teammate', company.id, 'assigned', teammate.id),
  seedBooking('job-other-company', otherCompany.id, 'assigned', assignedTech.id),
]);

function equal(field, value) {
  return { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: value } } };
}

// The same query FirestoreBookingService.watchTechnicianJobs sends.
function jobsQuery(companyId, technicianId, { withCompany = true } = {}) {
  return {
    structuredQuery: {
      from: [{ collectionId: 'bookings' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            ...(withCompany ? [equal('providerId', companyId)] : []),
            equal('technicianId', technicianId),
            {
              fieldFilter: {
                field: { fieldPath: 'status' },
                op: 'IN',
                value: { arrayValue: { values: ['assigned', 'in_progress'].map(s => ({ stringValue: s })) } },
              },
            },
          ],
        },
      },
    },
  };
}

async function listJobs(user, companyId, technicianId, options) {
  const rows = await request(`${documents}:runQuery`, {
    method: 'POST',
    token: user.token,
    body: jobsQuery(companyId, technicianId, options),
    status: options?.status ?? 200,
  });
  return Array.isArray(rows)
    ? rows.flatMap(r => (r.document ? [r.document.fields.id.stringValue] : [])).sort()
    : rows;
}

// 1. The assigned technician lists exactly their active jobs.
assert.deepEqual(
  await listJobs(assignedTech, company.id, assignedTech.id),
  ['job-assigned', 'job-progress'],
);

// 2. A teammate lists only their own job, and cannot list someone else's.
assert.deepEqual(await listJobs(teammate, company.id, teammate.id), ['job-teammate']);
await listJobs(teammate, company.id, assignedTech.id, { status: 403 });

// 3. A technician from another company cannot list this company's jobs.
await listJobs(outsider, company.id, outsider.id, { status: 403 });
await listJobs(outsider, company.id, assignedTech.id, { status: 403 });
assert.deepEqual(await listJobs(outsider, otherCompany.id, outsider.id), []);

// 4. A query that leaves out the company, or comes from a suspended
//    technician or a homeowner, is refused.
await listJobs(assignedTech, company.id, assignedTech.id, { withCompany: false, status: 403 });
await listJobs(suspended, company.id, suspended.id, { status: 403 });
await listJobs(customer, company.id, assignedTech.id, { status: 403 });

// 5. Opening one job: only the assigned technician, and only while it is active
//    at their own company.
await request(`${documents}/bookings/job-assigned`, { token: assignedTech.token });
await request(`${documents}/bookings/job-progress`, { token: assignedTech.token });
for (const user of [teammate, outsider, suspended]) {
  await request(`${documents}/bookings/job-assigned`, { token: user.token, status: 403 });
}
for (const id of ['job-cancelled', 'job-confirmed', 'job-teammate', 'job-other-company']) {
  await request(`${documents}/bookings/${id}`, { token: assignedTech.token, status: 403 });
}

console.log('TECHJOB-1 technician job listing and isolation rules passed.');
