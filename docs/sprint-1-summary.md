# ServicePilot — Sprint 1 Process & Delivery Summary

> **Google Doc Reference:** [ServicePilot — Sprint 1 Process & Delivery Summary](https://docs.google.com/document/d/19Fe_za2bA0ixfdCIKMdVkTIcXgsdm1Ccn3sujhTYfRM/edit)

---

## 1. Executive Summary

| Attribute | Details |
|---|---|
| **Project Name** | ServicePilot Mobile Application |
| **Sprint** | Sprint 1 — Authentication & Core Architecture |
| **Duration** | 20 Oct 2026 – 01 Nov 2026 *(Hardening & Verification through 13 Nov 2026)* |
| **Sprint Goal** | Ship a working Flutter app skeleton with all authentication flows — registration (4 user types), login, logout, and password reset — so every role can access the platform before service-booking features are built. |
| **Total Story Points** | **41 Points Committed / 41 Points Completed** (100% completion rate) |
| **Quality Status** | **70 / 70 Automated Tests Passing** (100% Green) |
| **Codebase Status** | Clean working tree; merged into `origin/main`; production Firebase integrated |

Sprint 1 successfully established the foundation of ServicePilot. The team completed the full authentication lifecycle across all five system roles, integrated production Firebase Authentication, and established comprehensive automated unit and widget test suites.

---

## 2. Sprint Backlog & Ticket Completion

All nine backlog items planned for Sprint 1 have reached the Definition of Done.

| Ticket | User Story / Task | Points | Assignee | Status | Key Deliverable |
|---|---|:---:|---|:---:|---|
| **SCRUM-40** | US-01: Customer Registration | 5 | Yeat David | **Done** | Homeowner registration flow, field validation, Google Sign-in integration points |
| **SCRUM-47** | US-02: Independent Technician Registration | 8 | Tiek Chhunhour | **Done** | Independent provider signup, pending verification status, PR #1 merged |
| **SCRUM-48** | US-03: Service Provider Company Registration | 8 | Yeat David | **Done** | Company owner & business profile creation, pending approval flow |
| **SCRUM-49** | US-04: Company Technician Activation | 8 | Yeat David | **Done** | Invitation token validation, technician account activation & password setup |
| **SCRUM-50** | US-06: User Login | 3 | Yeat David | **Done** | Unified credential authentication, role-based redirection, error handling |
| **SCRUM-51** | US-05: User Logout | 1 | Yeat David | **Done** | Session termination, secure token clearance, redirect to login guard |
| **SCRUM-52** | US-07: Reset Forgotten Password | 3 | Yeat David | **Done** | Password reset email trigger, reset confirmation flow, token invalidation |
| **SCRUM-53** | US-08: Platform Administrator Access | 5 | Yeat David | **Done** | Seeded admin access, non-admin 403 access barriers, admin console route |
| **SCRUM-56** | Design Mockup Prototype | — | Kheng Sothearith | **Done** | High-fidelity Figma mobile prototype covering all screens and states |

---

## 3. Technical Architecture & Implementation

### 3.1 Architecture Overview
The application follows a clean, modular structure built in Flutter:
- **Core Layer (`lib/core/`)**: Contains authentication providers, GoRouter setup with reactive route guards, theme definitions, and global constants.
- **Features Layer (`lib/features/auth/`)**: Implements authentication screens (Login, Role Selection, Customer Registration, Technician Registration, Company Registration, Technician Activation, Password Reset).
- **Shared Layer (`lib/shared/`)**: Provides reusable form widgets, custom text fields, and placeholder home landing screens for each role.

### 3.2 Role-Based Access Control (RBAC)
The app implements strict role segregation with 5 roles:
1. **Homeowner (Customer)**: Access to service catalog, cart, and booking tracking.
2. **Independent Provider**: Profile and listing management, quote submission, booking updates (defaults to `Pending Verification`).
3. **Service Provider Company**: Company profile, job assignment to technicians (defaults to `Pending Verification`).
4. **Company Technician**: Access restricted to jobs assigned by their parent company.
5. **Platform Admin**: Administrative dashboard for provider review and system oversight.

### 3.3 Backend & Authentication Migration
- **Early Development**: Initial scaffolding utilized mock data and mock authentication services to decouple frontend development from backend readiness.
- **Production Integration**: Transitioned to production Firebase Authentication and Firebase DataConnect. Mock services were removed in commit `6772f22`, ensuring all authentication requests route directly to live, secure backend endpoints.
- **Secure Storage**: Authentication credentials and session tokens are preserved securely on-device with `flutter_secure_storage`.

---

## 4. Quality Assurance & Test Verification

A test-driven and regression-safe development cycle was maintained throughout the sprint. Automated test coverage spans both logic units and Flutter widget trees.

### 4.1 Automated Test Execution Summary
- **Test Command**: `flutter test`
- **Total Tests Executed**: 70
- **Passed**: 70
- **Failed**: 0
- **Execution Result**: 100% Success

### 4.2 Test Suite Breakdown
- **US-01 Customer Registration**: Validates input formatting, missing field indicators, password matching, and submission dialogs.
- **US-02 Independent Technician Registration**: Validates form rendering, Cambodian phone format validation, role assignment, and pending verification alerts.
- **US-03 Company Registration**: Validates business metadata, owner credentials, and company status flags.
- **US-04 Technician Activation**: Verifies token acceptance, password initialization, and error handling for invalid/expired tokens.
- **US-05 User Logout**: Confirms token invalidation, session state reset, and immediate navigation back to the login screen.
- **US-06 User Login**: Tests credential verification, generic error messaging (preventing user enumeration), and correct role-based routing.
- **US-07 Password Reset**: Validates email submission, error states, and reset confirmation workflows.
- **US-08 Admin Access**: Tests role protection guards and unauthorized route rejections.
- **App Smoke Test**: Verifies root app mounting, initial splash state, and proper router redirection.

---

## 5. Team Roles & Contributions

| Member | Scrum Role | Primary Contributions in Sprint 1 |
|---|---|---|
| **Taing Sothyvan** | Product Owner | Defined product vision, established acceptance criteria for US-01 through US-08, and approved sprint increments against prototype requirements. |
| **Thang Saoly** | Scrum Master | Facilitated Scrum ceremonies, monitored sprint backlog progress, tracked blockers, managed documentation, and oversaw test verification. |
| **Yeat David** | Developer | Implemented US-01, US-03, US-04, US-05, US-06, US-07, and US-08; built Firebase Auth integration and authored automated test suites. |
| **Tiek Chhunhour** | Developer | Implemented US-02 (Independent Technician Registration), built custom registration UI and validation, managed Pull Request #1. |
| **Kheng Sothearith** | Developer / UI Designer | Delivered high-fidelity Figma mobile mockups (SCRUM-56), established visual design tokens, and guided UI compliance. |
| **Hem Eamsocheat** | Developer | Supported backend infrastructure setup, Firebase environment configuration, and test scenario planning. |

---

## 6. Process Retrospective & Lessons Learned

### 6.1 What Went Well
- **Seamless Feature Velocity**: Completed 41 story points on schedule, meeting 100% of the sprint backlog commitment.
- **Robust Test Discipline**: Built a comprehensive 70-test automated suite ensuring that future sprint feature additions will not cause auth regressions.
- **Collaborative Code Review**: Pull requests (e.g. PR #1) were systematically reviewed and merged with clean commit conventions.
- **Production Alignment**: Early transition from mock auth to real Firebase Authentication prevents technical debt in Sprint 2.

### 6.2 Key Challenges & Mitigations
- **Mock-to-Firebase Migration**: Transitioning from local mock services to Firebase required refactoring test helpers to use headless Firebase mocks. This was resolved via a dedicated test helper (`test_firebase_helper.dart`).
- **Deep Link Activation**: Handling technician invitation tokens required precise GoRouter parameter parsing to avoid routing loops.

---

## 7. Next Steps — Sprint 2 Preparation

Sprint 2 (02 Nov – 15 Nov 2026) shifts focus to the core marketplace and service management functionality:
1. **Service Catalog & Categories**: Browse plumbing, electrical, AC maintenance, appliance repair, and cleaning.
2. **Provider Profiles & Listings**: Enable verified providers and companies to showcase services and pricing.
3. **Cart & Booking Flow**: Single-provider cart, date/time scheduling, and Phnom Penh address selection.
4. **Quote Request System**: Non-fixed price flow allowing customers to submit work descriptions and photos for custom provider quoting.
