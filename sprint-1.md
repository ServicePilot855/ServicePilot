# Sprint 1 — Authentication
**Duration:** 20 Oct – 1 Nov 2026  
**Sprint Goal:** Ship a working Flutter app skeleton with all authentication flows — registration (4 user types), login, logout, and password reset — so every role can access the platform before any service-booking features are built.

---

## Sprint Board Snapshot

| Ticket | User Story | Points | Assignee | Status |
|--------|-----------|--------|----------|--------|
| SCRUM-40 | US-01: Customer Registration | 5 | YD | To Do |
| SCRUM-47 | US-02: Independent Technician Registration | 8 | TC | To Do |
| SCRUM-48 | US-03: Service Provider Company Registration | 8 | YD | To Do |
| SCRUM-49 | US-04: Company Technician Account Activation | 8 | YD | To Do |
| SCRUM-50 | US-06: User Login | 3 | YD | To Do |
| SCRUM-51 | US-05: User Logout | 1 | YD | To Do |
| SCRUM-52 | US-07: Reset Forgotten Password | 3 | YD | To Do |
| SCRUM-53 | US-08: Platform Administrator Access | 5 | YD | To Do |
| SCRUM-56 | Design Mockup Prototype | — | KS | In Review |

**Total Story Points:** 41

---

## Registration vs Login — Fields per Role

> **Rule:** Registration always collects the full identity profile. Login only needs credentials. Never ask for extra fields at login.

### Login (all roles — same screen)

| Field | Required |
|-------|----------|
| Email | ✅ |
| Password | ✅ |
| — | — |
| **Homeowner only:** "Continue with Google" button | optional path |

### Registration Fields by Role

| Field | Customer | Indep. Technician | Company Owner | Company Technician | Platform Admin |
|-------|:--------:|:-----------------:|:-------------:|:------------------:|:--------------:|
| Full name | ✅ | ✅ | ✅ | ✅ | — (seeded) |
| Email | ✅ | ✅ | ✅ | ✅ (pre-filled from invite) | — (seeded) |
| Phone number | ✅ | ✅ | ✅ | ✅ | — (seeded) |
| Password | ✅ | ✅ | ✅ | ✅ (set on activation) | — (seeded) |
| Google Sign-In | ✅ | ⏳ TBD | ⏳ TBD | ❌ (invite-only) | ❌ |
| Account type selector | ✅ | ✅ | ✅ | ❌ (invite sets role) | ❌ |
| Company name | ❌ | ❌ | ✅ | ❌ | ❌ |
| Company address | ❌ | ❌ | ✅ | ❌ | ❌ |
| Service area | ❌ | ✅ | ❌ | ❌ | ❌ |

> **Note:** Company Technicians do **not** self-register. They are invited by a Company Admin and only set their name + password on the activation screen. All other fields come from the invitation.



## User Stories

---

### US-01 · Customer Registration
**SCRUM-40 · 5 pts · Assignee: YD**

> As a customer, I want to create an account on ServicePilot so that I can access the platform and book repair services.

#### Acceptance Criteria
- [ ] Customers can register using their **name, email, phone number, and password**.
- [ ] Customers can also register / sign in using **Google Sign-In** (OAuth 2.0).
- [ ] Google-registered accounts still store `fullName`, `email`, and `phoneNumber`; phone number is collected in a post-Google-auth completion step if not provided by Google.
- [ ] All required fields must be completed before submission.
- [ ] Email addresses must not already be registered (unique constraint).
- [ ] Invalid information displays appropriate, field-level error messages.
- [ ] Successful registration creates an account with the **Customer** role.

#### Definition of Done
- [ ] Customer registration screen is implemented in Flutter (matches Figma mockup).
- [ ] Registration data is validated client-side and stored correctly in the database.
- [ ] Password is securely hashed before storage (never stored plain).
- [ ] Unit and widget tests for registration and validation pass.
- [ ] Code is peer-reviewed and the registration flow is manually verified end-to-end.

#### Technical Notes
- Fields: `fullName` (max 100), `email` (unique, valid format), `phoneNumber` (Cambodian `+855…`), `password` (min 8 chars).
- **Google Sign-In:** Use `google_sign_in` Flutter package. On first Google login, if phone number is missing, redirect to a short completion screen to collect it before creating the account.
- Role value stored: `homeowner`.
- Display field-level error messages inline below each input.
- Login screen shows **two options**: "Continue with Google" button + email/password form.

---

### US-02 · Independent Technician Registration
**SCRUM-47 · 8 pts · Assignee: TC**

> As an independent technician, I want to register an account on ServicePilot so that I can offer my repair services directly to customers.

#### Acceptance Criteria
- [ ] Users can select **"Independent Technician"** as their account type during registration.
- [ ] Required fields: name, email, phone number, and password.
- [ ] All required information is validated before submission.
- [ ] Successful registration creates an account with the **Independent Technician** role.
- [ ] Newly registered independent technician accounts have a **Pending Verification** status until approved by the platform.

#### Definition of Done
- [ ] Independent technician registration screen is implemented in Flutter (matches Figma mockup).
- [ ] Technician accounts are correctly stored with the `independent_provider` role.
- [ ] `Pending Verification` status is saved correctly and reflected in the UI.
- [ ] Unit and widget tests for registration and validation pass.
- [ ] Code is peer-reviewed and the registration flow is manually verified end-to-end.

#### Technical Notes
- Role value stored: `independent_provider`.
- Account status: `pending_verification` (not `active`) on creation.
- Account type selector should appear on the registration entry screen (e.g., role picker cards).

---

### US-03 · Service Provider Company Registration
**SCRUM-48 · 8 pts · Assignee: YD**

> As a repair company owner, I want to register my company on ServicePilot so that I can manage my technicians and receive repair bookings from customers.

#### Acceptance Criteria
- [ ] Company owners can register using their **personal information** and **company name**.
- [ ] All required company and account information must be provided.
- [ ] Successful registration creates a **company record** and a **Service Provider Admin** account associated with that company.
- [ ] Newly registered companies have a **Pending Verification** status.
- [ ] Company accounts **cannot** receive customer bookings until approved by Platform Admin.

#### Definition of Done
- [ ] Company registration screen is implemented in Flutter (matches Figma mockup).
- [ ] Company record and owner account are correctly stored and linked in the database.
- [ ] The company owner receives the correct role (`company`) and company association.
- [ ] Unit and widget tests for registration and validation pass.
- [ ] Code is peer-reviewed and the registration workflow is demonstrated.

#### Technical Notes
- Role value stored: `company` (owner/admin of the company).
- Company record fields: `companyName` (max 150), `contactPhone`, `address` (max 300).
- Both `users` and `companies` tables/collections must be written atomically.
- Company status: `pending_verification` on creation.

---

### US-04 · Company Technician Account Activation
**SCRUM-49 · 8 pts · Assignee: YD**

> As a company technician, I want to activate an account invited by my company's administrator so that I can log in and manage jobs assigned to me.

#### Acceptance Criteria
- [ ] A **Service Provider Admin** can invite a technician using their email address.
- [ ] Invited technicians receive an invitation and can activate their account by setting a password.
- [ ] Activated accounts receive the **Company Technician** role.
- [ ] Technicians are associated with the **company that invited them**.
- [ ] Invalid or expired invitations cannot be used to activate an account.

#### Definition of Done
- [ ] Technician invitation and account activation functionality is implemented (invite screen + activation screen).
- [ ] Role (`company_technician`) and company association are saved correctly.
- [ ] Invitation token validation and account activation tests pass.
- [ ] Access to other companies' data is prevented and tested (cross-tenant isolation).
- [ ] Code is peer-reviewed and the full invitation → activation workflow is demonstrated.

#### Technical Notes
- Invitation tokens must be time-limited (e.g., 72 hours).
- Expired/used tokens must be rejected with a clear error message.
- The activation screen collects: `fullName` and `password` (email is pre-filled from invitation).
- Role value stored: `company_technician`.

---

### US-05 · User Logout
**SCRUM-51 · 1 pt · Assignee: YD**

> As a logged-in ServicePilot user, I want to log out of my account so that other people cannot access my account through my current session.

#### Acceptance Criteria
- [ ] All authenticated users can log out from any screen (e.g., via a menu or profile button).
- [ ] Logging out **invalidates** the current authentication session/token.
- [ ] Users are redirected to the **login screen** after logout.
- [ ] Protected pages cannot be accessed once the session is invalidated.

#### Definition of Done
- [ ] Logout action is implemented and accessible from the app.
- [ ] Current session token/credentials are invalidated securely (token blacklisted or cleared).
- [ ] Protected pages reject navigation attempts from logged-out users and redirect to login.
- [ ] Logout functionality tests pass.
- [ ] Code is peer-reviewed and the logout workflow is verified.

#### Technical Notes
- Clear auth token from local secure storage (e.g., `flutter_secure_storage`) on logout.
- If using JWT: implement token invalidation strategy (refresh token revocation or short TTL).
- All auth-guarded routes must redirect to `/login` when no valid token is present.

---

### US-06 · User Login
**SCRUM-50 · 3 pts · Assignee: YD**

> As a registered ServicePilot user, I want to log in securely so that I can access the features available to my account.

#### Acceptance Criteria
- [ ] Registered users can log in using their **email and password**.
- [ ] Invalid credentials display an appropriate error message (no detail leakage).
- [ ] Successful login grants access to features authorized for the user's **role**.
- [ ] Users **cannot** access functionality restricted to other roles.
- [ ] **Suspended or deactivated** accounts cannot log in.

#### Definition of Done
- [ ] Login screen and authentication functionality are implemented in Flutter (matches Figma mockup).
- [ ] Credentials are securely validated against hashed passwords.
- [ ] **Role-based access control (RBAC)** is implemented and enforced by the backend.
- [ ] Successful and unsuccessful login scenarios are tested (unit + integration).
- [ ] Code is peer-reviewed and authentication is verified.

#### Technical Notes
- On success: store auth token in `flutter_secure_storage`; store role in app state.
- On failure: generic "Invalid email or password" message (do not reveal whether email exists).
- Pending-verification accounts: show "Your account is pending approval" message.
- Route guard: check role after login to navigate to the correct home screen per role.

---

### US-07 · Reset Forgotten Password
**SCRUM-52 · 3 pts · Assignee: YD**

> As a registered ServicePilot user, I want to reset my forgotten password so that I can regain access to my account.

#### Acceptance Criteria
- [ ] Users can request a password reset using their **registered email address**.
- [ ] A **time-limited** password reset link/OTP is sent to the registered email.
- [ ] Users can create a **new password** using a valid reset link.
- [ ] **Expired or previously used** reset links are rejected.
- [ ] Users can log in using their new password after reset.

#### Definition of Done
- [ ] Password reset request screen and new-password screen are implemented in Flutter.
- [ ] Reset tokens are securely generated, expire after a fixed window, and cannot be reused.
- [ ] Updated passwords are securely hashed before storage.
- [ ] Password recovery tests pass (valid token, expired token, already-used token).
- [ ] Code is peer-reviewed and the complete password reset flow is verified.

#### Technical Notes
- Token expiry: **1 hour** from generation.
- Tokens are single-use — invalidate immediately after a successful reset.
- Reset email sender: use a transactional email service (e.g., SendGrid, Mailgun, or SMTP).
- UI flow: `Forgot Password?` link on login → enter email → check email screen → deep-link to new-password screen.

---

### US-08 · Platform Administrator Access
**SCRUM-53 · 5 pts · Assignee: YD**

> As a ServicePilot Platform Admin, I want to securely access the platform administration area so that I can manage platform operations and review service provider accounts.

#### Acceptance Criteria
- [ ] Platform Admin accounts are created **only through an authorized internal process** (e.g., seeded by a backend script).
- [ ] Users **cannot** self-register as Platform Admins through the app.
- [ ] Platform Admins can log in using valid credentials via the standard login screen.
- [ ] **Only Platform Admins** can access the platform administration area.
- [ ] Non-administrative users are **denied access** to platform management functionality.

#### Definition of Done
- [ ] Platform Admin account provisioning is implemented (seed script or admin CLI).
- [ ] Administrative access restrictions are enforced by the backend (role-checked on every admin endpoint).
- [ ] Authorized (admin) and unauthorized (non-admin) access scenarios are tested.
- [ ] Code is peer-reviewed and administrator access is verified in demo.

#### Technical Notes
- Role value stored: `admin`.
- Admin accounts are **not** creatable via any public-facing registration endpoint.
- Backend must return `403 Forbidden` for any non-admin attempting to hit admin routes.
- In the Flutter app, the admin home screen / navigation is only rendered when `role == admin`.

---

## App Architecture — Sprint 1 Scope

Since this sprint delivers **only the authentication shell**, the Flutter app structure should look like:

```
lib/
├── main.dart                     # App entry point, router setup
├── core/
│   ├── router/
│   │   └── app_router.dart       # GoRouter with auth guards
│   ├── auth/
│   │   ├── auth_provider.dart    # Auth state (Riverpod / Provider)
│   │   └── auth_service.dart     # Login, register, logout, reset
│   └── constants/
│       └── app_roles.dart        # Role enum: homeowner, independent_provider, company, company_technician, admin
├── features/
│   └── auth/
│       ├── screens/
│       │   ├── splash_screen.dart
│       │   ├── role_select_screen.dart    # Account type picker
│       │   ├── login_screen.dart
│       │   ├── register_customer_screen.dart
│       │   ├── register_technician_screen.dart
│       │   ├── register_company_screen.dart
│       │   ├── technician_activation_screen.dart
│       │   ├── forgot_password_screen.dart
│       │   └── reset_password_screen.dart
│       └── widgets/
│           ├── auth_text_field.dart
│           └── role_card.dart
└── shared/
    ├── home/
    │   ├── customer_home.dart             # Placeholder — "Coming Soon"
    │   ├── technician_home.dart           # Placeholder — "Coming Soon"
    │   ├── company_home.dart              # Placeholder — "Coming Soon"
    │   ├── company_technician_home.dart   # Placeholder — "Coming Soon"
    │   └── admin_home.dart               # Placeholder — "Coming Soon"
    └── widgets/
        └── coming_soon_banner.dart
```

> **Note:** All home screens beyond authentication are **placeholders** in Sprint 1. They display a "Coming Soon" banner and a logout button. Full feature screens are built in Sprints 2 and 3.

---

## Screen Navigation Flow

```
Splash
  ├── [no session] ──► Role Select ──► Register (Customer / Technician / Company)
  └── [has session] ──► Home (role-based)

Login ◄─────────────────────────────────────────────────────────────────────
  ├── [success] ──► Home (role-based: customer / technician / company / admin)
  ├── [failed]  ──► Inline error on same screen
  └── Forgot Password ──► Enter Email ──► "Check your email" screen
                              └── Reset Link / Deep Link ──► New Password ──► Login

Company Admin Home ──► Invite Technician (email input) ──► [email sent]
  └── Technician receives email ──► Activation Screen ──► Set password ──► Login
```

---

## Non-Functional Requirements (Sprint 1)

| Concern | Requirement |
|---------|-------------|
| **Security** | Passwords hashed (bcrypt, min cost 12). Tokens stored in `flutter_secure_storage`. HTTPS only. |
| **Validation** | Client-side validation with matching backend validation. Never trust the client alone. |
| **Error UX** | Field-level inline errors. No raw error codes or stack traces exposed to the user. |
| **Performance** | Login response < 1 s on local network. |
| **Accessibility** | All form fields have labels. Error messages are screen-reader friendly. |

---

## Sprint 1 Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ~~Backend stack not agreed~~ | ~~Medium~~ | ~~High~~ | ✅ **Confirmed: Node/Express + PostgreSQL** |
| Email service not configured for password reset | Medium | Medium | Use Mailtrap for dev, SendGrid free tier for staging. |
| Invitation deep-link setup for technician activation | High | Medium | Use a short-lived token passed as a URL query param; handle in the app via GoRouter. |
| Figma mockup not final (SCRUM-56 in review) | Medium | Low | Build screens from latest Figma snapshot; update styling once mockup is approved. |

---

## Team Assignments

| Member | Role | Sprint 1 Focus |
|--------|------|---------------|
| **Taing Sothyvan** | Product Owner | Backlog ordering, AC clarification, sprint review |
| **Thang Saoly** | Scrum Master | Facilitate events, remove blockers, track board |
| **Yeat David** | Developer | US-01, US-03, US-04, US-05, US-06, US-07, US-08 |
| **Tiek Chhunhour** | Developer | US-02 |
| **Kheng Sothearith** | Developer | SCRUM-56 Design mockup (In Review) |
| **Hem Eamsocheat** | Developer | Support — testing & backend setup |

---

## Sprint-Level Definition of Done

A story is **Done** when **all** of the following are true:

1. The Flutter screen(s) match the approved Figma mockup (SCRUM-56).
2. Client-side form validation works and matches backend validation rules.
3. The feature is connected to the real backend (not mocked/hardcoded data).
4. The happy path and at least one error path are covered by automated tests.
5. The code has been reviewed by at least one other team member.
6. The Product Owner has accepted the story against the acceptance criteria.
7. No known critical bugs exist in the merged code.

---

*Last updated: 2 Nov 2026 — Sprint 1 Kickoff*
