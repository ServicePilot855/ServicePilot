# Sprint 6 — Job Progress & Company Dispatch
**Duration:** 27 Nov – 04 Dec 2026  
**Sprint Name:** Sprint 6  
**Sprint Goal:** Job progress and company dispatch — enable independent providers, company administrators, and company technicians to view active/completed jobs, assign company technicians to bookings, and transition authorized jobs from In Progress to Completed.

---

## Sprint Board Snapshot

| Ticket | User Story / Feature | Type | Assignee | Status |
|---|---|---|---|:---:|
| **SCRUM-89** | BOOK-4: View current appointments and job progress | Story | THANG Saoly (`TS`) | Done |
| **SCRUM-90** | BOOK-5: View completed and closed service records | Story | THANG Saoly (`TS`) | Done |
| **SCRUM-91** | WORK-1: Mark authorized provider work as started | Story | HEM Eamsocheat (`HE`) | To Do |
| **SCRUM-92** | WORK-2: Mark authorized provider work as completed | Story | YEAT David (`YD`) | To Do |
| **SCRUM-99** | TEAM-1: Assign one company technician to a booking | Story | Taing Sothyvan (`TS`) | In Progress |
| **SCRUM-100** | TECHJOB-1: View my assigned jobs | Story | TIEK Chhunhour (`TC`) | To Do |
| **SCRUM-101** | TECHJOB-2: Start my assigned job | Story | KHENG Sokthearith (`KS`) | To Do |
| **SCRUM-102** | TECHJOB-3: Complete my assigned job | Story | YEAT David (`YD`) | To Do |
| **SCRUM-198** | Technician activation & sign-in preserves verified company membership | Bug | Taing Sothyvan (`TS`) | Done |

**Total Work Items:** 9 items (8 stories, 1 bug)  
**Epics:** Job Tracking (`SCRUM-30`), Company Tools (`SCRUM-32`)

---

## Workload Allocation & Focus Domains

| Team Member | Role | Assigned Items | Focus Domain |
|---|---|---|---|
| **THANG Saoly** | Scrum Master / Lead Dev | BOOK-4 (`SCRUM-89`), BOOK-5 (`SCRUM-90`) | Provider active schedule & completed/closed job history |
| **Taing Sothyvan** | Product Owner / Developer | TEAM-1 (`SCRUM-99`), Bug (`SCRUM-198`) | Company technician membership persistence & booking dispatch/assignment |
| **HEM Eamsocheat** | Developer | WORK-1 (`SCRUM-91`) | Provider-side job start transition (`Confirmed` → `In Progress`) |
| **YEAT David** | Developer | WORK-2 (`SCRUM-92`), TECHJOB-3 (`SCRUM-102`) | Provider & company technician job completion (`In Progress` → `Completed`) |
| **TIEK Chhunhour** | Developer | TECHJOB-1 (`SCRUM-100`) | Company technician assigned-jobs inbox & isolation |
| **KHENG Sokthearith** | Developer / UI Designer | TECHJOB-2 (`SCRUM-101`) | Company technician job start transition (`Assigned` → `In Progress`) |

---

## User Stories & Bug Specification

---

### BOOK-4 · View Current Appointments and Job Progress
**SCRUM-89 · Assignee: THANG Saoly**  
*Epic: Job Tracking (SCRUM-30) · Requirement: IND-3, CO-2, CO-3*

> As a provider account manager, I can see my upcoming and active jobs so I know what is scheduled and how work is progressing.

#### Acceptance Criteria
- [x] An independent provider or authorized company administrator sees their own active bookings, recorded appointment times, and current status.
- [x] A company admin sees the assigned technician when available.
- [x] Records for another provider are inaccessible.

#### Subtasks
- `SCRUM-151`: Build the active work list *(In Progress)*
- `SCRUM-152`: Verify active work and status *(In Progress)*

---

### BOOK-5 · View Completed and Closed Service Records
**SCRUM-90 · Assignee: THANG Saoly**  
*Epic: Job Tracking (SCRUM-30) · Requirement: IND-3, CO-2*

> As a provider account manager, I can review past jobs so I have a record of services and booking decisions.

#### Acceptance Criteria
- [x] An independent provider or service company administrator sees their own `Completed`, `Cancelled`, and `Declined` bookings with service, appointment, and final status.
- [x] An empty history is clear and other providers' service records are inaccessible.

#### Subtasks
- `SCRUM-153`: Connect provider history *(To Do)*
- `SCRUM-154`: Verify service records *(To Do)*

---

### WORK-1 · Mark Authorized Provider Work as Started
**SCRUM-91 · Assignee: HEM Eamsocheat**  
*Epic: Job Tracking (SCRUM-30) · Requirement: HOME-4, HOME-5, IND-3, IND-4, CO-2*

> As a provider account manager, I can mark eligible work In Progress so the customer sees that service has begun.

#### Acceptance Criteria
- [ ] The authorized independent provider or company administrator can start their own eligible job.
- [ ] The homeowner sees `In Progress`.
- [ ] A cancelled booking, a booking belonging to another provider, or quote-based work without recorded approval cannot start.

#### Subtasks
- [ ] `SCRUM-155`: Connect the provider start action
- [ ] `SCRUM-156`: Verify the start gate

---

### WORK-2 · Mark Authorized Provider Work as Completed
**SCRUM-92 · Assignee: YEAT David**  
*Epic: Job Tracking (SCRUM-30) · Requirement: HOME-5, IND-3, CO-2*

> As a provider account manager, I can mark a job Completed so the homeowner and I have a final service record.

#### Dependencies
- `WORK-1` or an owned `In Progress` fixture.

#### Acceptance Criteria
- [ ] An authorized provider-side actor can complete an owned `In Progress` job.
- [ ] Both sides see `Completed` in history.
- [ ] An unrelated provider or an ineligible booking state cannot complete the job.

#### Subtasks
- [ ] `SCRUM-157`: Connect provider completion
- [ ] `SCRUM-158`: Verify the recorded completion

---

### Bug · Technician Activation and Sign-In Must Preserve Verified Company Membership
**SCRUM-198 · Priority: High · Assignee: Taing Sothyvan**  
*Status: Done · Blocks: `SCRUM-99`*

> An authorized invitation persists the technician role and inviting company through the trusted enrollment flow, and signing in on a fresh device retains the server-recorded role and company. Cross-company assignment and technician self-reassignment are denied.

---

### TEAM-1 · Assign One Company Technician to a Booking
**SCRUM-99 · Assignee: Taing Sothyvan**  
*Epic: Company Tools (SCRUM-32) · Requirement: CO-3, TECH-2*

> As a service company administrator, I can assign an eligible booking to a technician from my company so that person can carry out the work.

#### Dependencies
- `SCRUM-49`, `SCRUM-198` *(Done)*, an owned eligible booking, and the agreed sequence for confirmation and assignment.

#### Acceptance Criteria
- [ ] The company administrator can select a technician linked to the same company.
- [ ] The assignment appears on the company booking and makes the job available to that technician.
- [ ] Attempts to assign a technician from another company or assign a cancelled booking are denied.

#### Subtasks
- [ ] `SCRUM-175`: Show selectable company technicians
- [ ] `SCRUM-176`: Save the authorized booking assignment
- [ ] `SCRUM-177`: Verify company and booking boundaries

---

### TECHJOB-1 · View My Assigned Jobs
**SCRUM-100 · Assignee: TIEK Chhunhour**  
*Epic: Company Tools (SCRUM-32) · Requirement: TECH-2*

> As a company technician, I can open the jobs assigned to me so I know where and when I need to work.

#### Dependencies
- `TEAM-1` or seeded assignments and verified technician company membership.

#### Acceptance Criteria
- [ ] The signed-in technician sees their assigned jobs and the permitted appointment, service, and status details.
- [ ] Unassigned jobs and jobs assigned to other technicians or companies are inaccessible.

#### Subtasks
- [ ] `SCRUM-178`: Read jobs for the signed-in technician
- [ ] `SCRUM-179`: Display assigned jobs and details
- [ ] `SCRUM-180`: Verify assignment isolation

---

### TECHJOB-2 · Start My Assigned Job
**SCRUM-101 · Assignee: KHENG Sokthearith**  
*Epic: Company Tools (SCRUM-32) · Requirement: HOME-4, HOME-5, TECH-2*

> As a company technician, I can mark my assigned job In Progress so the company and homeowner know I have started work.

#### Dependencies
- `TECHJOB-1` and the shared start transition used by `WORK-1`.

#### Acceptance Criteria
- [ ] The assigned technician can start an eligible job, and the company and homeowner see `In Progress`.
- [ ] Unassigned technicians cannot start it.
- [ ] Cancelled work and quote-based work without approval cannot start.

#### Subtasks
- [ ] `SCRUM-181`: Connect technician start
- [ ] `SCRUM-182`: Verify technician start and visibility

---

### TECHJOB-3 · Complete My Assigned Job
**SCRUM-102 · Assignee: YEAT David**  
*Epic: Company Tools (SCRUM-32) · Requirement: HOME-5, TECH-2*

> As a company technician, I can mark my assigned job Completed so the company and homeowner can see that the work is finished.

#### Dependencies
- `TECHJOB-2` or an assigned `In Progress` fixture and the shared completion transition.

#### Acceptance Criteria
- [ ] The assigned technician can complete an `In Progress` job.
- [ ] Completion appears to the company and in the homeowner's booking history.
- [ ] A different technician or an ineligible booking state cannot complete it.

#### Subtasks
- [ ] `SCRUM-183`: Connect technician completion
- [ ] `SCRUM-184`: Verify completion across roles

---

## Technical Notes & Architecture — Sprint 6 Scope

```
lib/
├── core/
│   ├── constants/
│   │   └── booking_status.dart                      # Confirmed / Assigned -> In Progress -> Completed
│   └── router/
│       └── app_router.dart                          # Provider & technician job detail routes
├── features/
│   └── bookings/
│       ├── models/
│       │   └── booking_model.dart                   # technicianId, technicianName, status transitions
│       ├── providers/
│       │   └── booking_provider.dart                # Provider, technician & customer booking streams
│       ├── screens/
│       │   ├── booking_history_screen.dart          # Homeowner history reflects Completed
│       │   └── provider_booking_detail_screen.dart  # Start / Assign / Complete actions
│       ├── services/
│       │   ├── booking_service.dart                 # IBookingService contracts & state guards
│       │   └── firestore_booking_service.dart       # Firestore mutations & role checks
│       └── widgets/
│           └── provider_booking_list.dart           # Active & past provider job lists
└── shared/
    └── home/
        ├── company_home.dart                        # Company dispatch & job progress
        ├── company_technician_home.dart             # Assigned jobs for company technicians
        └── technician_home.dart                     # Independent provider active & past jobs
```

---

## Sprint 6 Definition of Done

A user story in Sprint 6 is **Done** when:
1. Flutter screens follow the **Blue Pipe** design tokens and rules in `DESIGN.md`.
2. Role-based and ownership security guards enforce strict isolation (independent providers, company admins, and assigned company technicians can only act on their own eligible bookings).
3. Invalid state transitions (e.g., completing a job that is not `In Progress`, or starting cancelled/unapproved-quote work) are blocked in both app services and `firestore.rules`.
4. Happy paths, failure paths, and cross-role/cross-company isolation are covered by unit, widget, and Firestore rules tests.
5. `flutter analyze` passes with 0 issues.
6. Acceptance criteria are reviewed and signed off by the Product Owner (Taing Sothyvan).
