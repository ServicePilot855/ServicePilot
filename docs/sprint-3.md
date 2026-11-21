# Sprint 3 — Bookable Catalog & Platform Administration
**Duration:** 21 Nov – 28 Nov 2026  
**Sprint Name:** Group 1 - Bookable catalog  
**Sprint Goal:** Enable independent providers and service companies to update public profiles and publish fixed-price or quote-required service listings, while equipping Platform Admins with the provider verification and approval workflow.

---

## Sprint Board Snapshot

| Ticket | User Story / Feature | Points | Assignee | Status |
|---|---|:---:|---|:---:|
| **SCRUM-71** | PROFILE-1: Update an independent provider profile | 5 | TIEK Chhunhour (`TC`) | To Do |
| **SCRUM-73** | PROFILE-2: Update a service company profile | 5 | Taing Sothyvan (`TS`) | To Do |
| **SCRUM-74** | DISC-1: View a provider's service details and prices | 5 | TIEK Chhunhour (`TC`) | To Do |
| **SCRUM-76** | OFFER-1: Add a fixed-price service listing | 8 | KHENG Sokthearith (`KS`) | To Do |
| **SCRUM-77** | OFFER-2: Add an offering that requires a quote | 5 | THANG Saoly (`TS`) | To Do |
| **SCRUM-93** | ADM-1: View pending provider applications | 5 | YEAT David (`YD`) | To Do |
| **SCRUM-94** | ADM-2: Approve a pending provider | 5 | HEM Eamsocheat (`HE`) | To Do |

**Total Work Items:** 7 stories  
**Total Story Points:** 38 pts  

---

## Story Points & Workload Allocation

| Team Member | Role | Assigned Stories | Total Points | Focus Domain |
|---|---|---|:---:|---|
| **THANG Saoly** | Scrum Master / Lead Dev | OFFER-2 (SCRUM-77) | 5 pts | Quote-required listing mode, catalog data architecture |
| **Taing Sothyvan** | Product Owner / Developer | PROFILE-2 (SCRUM-73) | 5 pts | Company profile update, contact links & coverage areas |
| **TIEK Chhunhour** | Developer | PROFILE-1 (SCRUM-71), DISC-1 (SCRUM-74) | 10 pts | Independent provider profile update & service price discovery |
| **KHENG Sokthearith** | Developer / UI Designer | OFFER-1 (SCRUM-76) | 8 pts | Fixed-price service listing form & validation |
| **YEAT David** | Developer | ADM-1 (SCRUM-93) | 5 pts | Admin pending provider review queue & verification access |
| **HEM Eamsocheat** | Developer | ADM-2 (SCRUM-94) | 5 pts | Admin provider approval logic, status activation & bookability |

---

## User Stories Specification

---

### PROFILE-1 · Update an Independent Provider Profile
**SCRUM-71 · 5 pts · Assignee: TIEK Chhunhour**  
*Epic: Accounts & Profiles (SCRUM-21) · Requirement: IND-2*

> As an independent provider, I can update my customer-facing profile so homeowners see current service coverage and contact details.

#### Acceptance Criteria
- [ ] The owner can save permitted display details, service area, and optional external contact links (Telegram / Messenger).
- [ ] The approved profile displays the updated information immediately.
- [ ] Another account cannot edit the profile (strict ownership guard).

#### Subtasks
- [ ] `SCRUM-72`: Save permitted independent profile changes
- [ ] `SCRUM-106`: Connect the profile edit form
- [ ] `SCRUM-107`: Verify saved details and ownership

#### Definition of Done
- [ ] The change is integrated into the shared prototype and all acceptance criteria are verified.
- [ ] Relevant success and failure paths pass, including access and data isolation checks where applicable. Link the verification evidence.
- [ ] Peer review is complete, required project checks pass, and defects are recorded and resolved or accepted by the Product Owner.
- [ ] Required subtasks are complete and the Product Owner has reviewed the result against the acceptance criteria.

---

### PROFILE-2 · Update a Service Company Profile
**SCRUM-73 · 5 pts · Assignee: Taing Sothyvan**  
*Epic: Accounts & Profiles (SCRUM-21) · Requirement: CO-2*

> As a service company administrator, I can update the company's customer-facing profile so homeowners see accurate coverage and contact details.

#### Acceptance Criteria
- [ ] An authorized administrator can update permitted company details, service area, and optional contact links.
- [ ] The approved company profile shows the changes on public view.
- [ ] Administrators from another company cannot edit it.

#### Subtasks
- [ ] `SCRUM-108`: Save permitted company profile changes
- [ ] `SCRUM-109`: Connect the company profile edit form
- [ ] `SCRUM-110`: Verify company profile visibility and isolation

#### Definition of Done
- [ ] Profile edit UI matches Figma prototype specifications and ServicePilot design system.
- [ ] Company update mutations persist in Firestore with authorized admin checks.
- [ ] Data isolation tests confirm non-members are blocked from editing.
- [ ] Code passes peer review and automated tests pass with 0 warnings.

---

### DISC-1 · View a Provider's Service Details and Prices
**SCRUM-74 · 5 pts · Assignee: TIEK Chhunhour**  
*Epic: Browse & Search (SCRUM-27) · Requirement: HOME-2*

> As a homeowner, I can see what a provider offers and how each service is priced so I can choose between a fixed-price booking and a quote.

#### Acceptance Criteria
- [ ] The profile shows the selected provider's active offerings with service title and details.
- [ ] Each offering clearly shows either a fixed price (e.g., `$25.00`) or a "Quote Required" tag.
- [ ] The displayed price comes accurately from the service listing document.

#### Subtasks
- [ ] `SCRUM-111`: Show the provider's active offerings
- [ ] `SCRUM-112`: Verify pricing and provider scope

#### Definition of Done
- [ ] Offering listing card component integrated on `ProviderDetailScreen`.
- [ ] Correctly queries `services` sub-collection or filtered listings for the target provider.
- [ ] Unit and widget tests pass covering both fixed-price and quote-required rendering.

---

### OFFER-1 · Add a Fixed-Price Service Listing
**SCRUM-76 · 8 pts · Assignee: KHENG Sokthearith**  
*Epic: Browse & Search (SCRUM-27) · Requirement: IND-2, CO-2*

> As a provider account manager, I can publish a service with a fixed price so homeowners can choose it for a cart.

#### Acceptance Criteria
- [ ] An independent provider or authorized company administrator can add a listing with service details, an eligible category, and a valid fixed price.
- [ ] An eligible published listing appears on the correct profile with the saved price.
- [ ] Invalid (negative price, empty title, unselected category) or unauthorized submissions produce no listing.

#### Subtasks
- [ ] `SCRUM-115`: Validate and store the fixed-price listing
- [ ] `SCRUM-116`: Connect the fixed-price listing form
- [ ] `SCRUM-117`: Verify fixed-price listing creation

#### Definition of Done
- [ ] Service listing form with input validation (title length, price > 0).
- [ ] Firestore security rules enforce provider identity on `services` writes.
- [ ] Automated form validation and creation tests pass.

---

### OFFER-2 · Add an Offering That Requires a Quote
**SCRUM-77 · 5 pts · Assignee: THANG Saoly**  
*Epic: Browse & Search (SCRUM-27) · Requirement: IND-2, CO-2*

> As a provider account manager, I can publish an offering that needs a quote so homeowners can request a price for that job.

#### Acceptance Criteria
- [ ] An independent provider or authorized company administrator can create a listing with the `quote_required` mode.
- [ ] The homeowner sees that designation and the listing is eligible for quote intake instead of fixed-price checkout.

#### Subtasks
- [ ] `SCRUM-118`: Store an offering in quote-required mode
- [ ] `SCRUM-119`: Connect quote-required mode in the listing form
- [ ] `SCRUM-120`: Verify quote classification

#### Definition of Done
- [ ] Price type toggle (`fixed` vs `quote_required`) implemented on listing form.
- [ ] Database schema sets `priceType: 'quote_required'` and permits `price == null`.
- [ ] Widget and model unit tests pass.

---

### ADM-1 · View Pending Provider Applications
**SCRUM-93 · 5 pts · Assignee: YEAT David**  
*Epic: Admin (SCRUM-31) · Requirement: ADMIN-1*

> As a Platform Admin, I can review pending independent provider and company accounts so I know which applications need a decision.

#### Acceptance Criteria
- [x] An authorized admin can find pending providers (`status == 'pending_verification'`).
- [x] The admin queue displays the identity, provider type (Independent Technician vs Service Company), and verification information approved for review.
- [x] Other user roles (Customer, Technician, Company) cannot access the admin application view (strict role-based access control).

#### Subtasks
- [x] `SCRUM-159`: Load pending provider records for the admin queue
- [x] `SCRUM-160`: Display the provider review queue
- [x] `SCRUM-161`: Verify the queue and access rules

#### Definition of Done
- [x] Admin provider queue interface implemented in Flutter (`AdminPendingProvidersScreen`).
- [x] Correctly queries users and provider profiles with `status == 'pending_verification'`.
- [x] Access guard redirects or blocks non-admin users.
- [x] Automated widget and unit tests verify queue display and role access restrictions.

---

### ADM-2 · Approve a Pending Provider
**SCRUM-94 · 5 pts · Assignee: HEM Eamsocheat**  
*Epic: Admin (SCRUM-31) · Requirement: ADMIN-1*

> As a Platform Admin, I can approve a reviewed provider so it becomes eligible for customer bookings.

#### Acceptance Criteria
- [ ] An authorized admin can approve a Pending Verification provider.
- [ ] An approved, active provider becomes eligible for customer discovery and booking (`status == 'active'`).
- [ ] A non-admin account cannot approve a provider.

#### Subtasks
- [ ] `SCRUM-162`: Persist the authorized provider approval
- [ ] `SCRUM-163`: Connect approval on the provider review screen
- [ ] `SCRUM-164`: Verify approval and bookability

#### Definition of Done
- [ ] Approval action with confirmation dialog implemented on review screen.
- [ ] Status mutation updates provider status to `active` in Firestore.
- [ ] Security rules restrict update to `isAdmin()`.
- [ ] Automated tests cover successful approval and unauthorized rejection.

---

## Technical Notes & Architecture — Sprint 3 Scope

```
lib/
├── core/
│   ├── router/
│   │   └── app_router.dart                     # Routes for admin review and listing forms
│   └── constants/
│       └── provider_status.dart                # 'pending_verification', 'active', 'rejected'
├── features/
│   ├── admin/
│   │   ├── screens/
│   │   │   ├── admin_pending_providers_screen.dart # SCRUM-93 (YEAT David)
│   │   │   └── admin_provider_detail_screen.dart   # SCRUM-93 & SCRUM-94 (HEM Eamsocheat)
│   │   ├── services/
│   │   │   └── admin_provider_service.dart         # Query pending & approve providers
│   │   └── widgets/
│   │       ├── pending_provider_card.dart
│   │       └── approve_provider_dialog.dart
│   └── listings/
│       ├── models/service_listing_model.dart       # Fixed price vs Quote required
│       ├── screens/create_service_listing_screen.dart
│       └── services/listing_service.dart
```

---

## Sprint 3 Definition of Done

A user story in Sprint 3 is **Done** when:
1. Flutter screens follow the **Blue Pipe** design tokens in `DESIGN.md`.
2. Role-based security guards enforce access (Admins for review, Providers for their own profiles/listings).
3. Backend mutations persist correctly in Firebase Firestore.
4. Happy path and edge cases (unauthorized edit attempts, invalid pricing) are covered by unit and widget tests.
5. `flutter analyze` passes with 0 issues.
6. Acceptance criteria are signed off by the Product Owner (Taing Sothyvan).
