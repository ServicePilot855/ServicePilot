# ServicePilot — Senior Mobile Developer Bug & Architecture Audit Report

**Scope:** Codebase, Authentication, Routing, Security Rules, State Management, and UI/Localization Audit  
**Purpose:** Track identified bugs, security gaps, state/logic errors, and technical debt for systematic remediation.

---

## Executive Summary

| Severity | Count | Focus Areas |
|---|:---:|---|
| 🔴 **Critical** | 1 | Client-side role escalation via email inference vs. Firestore Rules mismatch |
| 🟠 **High** | 3 | Missing router guards on role homes, split Admin provider services, Firestore/local state divergence |
| 🟡 **Medium** | 4 | Silent write/auth error swallowing, hardcoded test emails in prod provider, placeholder technician home |
| 🟢 **Low** | 2 | Hardcoded English strings bypassing Khmer l10n, missing tab-switch widget test coverage |

---

## 🔴 Critical Issues

### 1. Email-Based Role Escalation & Client/Server Admin Mismatch
* **Location:** [firebase_auth_service.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/core/auth/firebase_auth_service.dart#L786-L833), [firestore.rules](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/firestore.rules#L169-L179)
* **Issue:**  
  When no Firestore `users/{uid}` document is found during login or Google Sign-In, `_loadOrCreateUserModel` calls `_inferRoleFromEmail(userEmail)`:
  * Any email containing `'admin'` is granted `AppRole.admin`.
  * Any email containing `'company'` / `'business'` is granted `AppRole.company`.
  * Any email containing `'technician'` / `'provider'` is granted `AppRole.independentProvider`.
  * Furthermore, it synthesizes a local `UserModel` with `status: 'active'`.
* **Impact:**  
  1. **Client-side privilege escalation:** Anyone signing in with an email like `test.admin@gmail.com` enters the Admin UI.  
  2. **Client/server split-brain:** `firestore.rules` `isAdmin()` requires `token.admin == true`, `token.role == 'admin'`, or `email_verified == true` with `@servicepilot.app`. Real admins created in Firebase Console without verified `@servicepilot.app` emails or custom claims can open the Admin UI, but all Firestore writes fail with `permission-denied`.
* **Recommended Fix:** Remove `_inferRoleFromEmail` from production auth paths; always source role and status from the server `users/{uid}` document (or verified Firebase custom claims) and fail closed to `AppRole.homeowner` or an explicit error if missing.

---

## 🟠 High-Severity Issues

### 2. Missing Router Role Guards for Non-Admin Home Routes
* **Location:** [app_router.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/core/router/app_router.dart#L66-L139)
* **Issue:**  
  `GoRouter.redirect` blocks non-admins from `/home/admin` & `/admin`, non-homeowners from `/cart`, and unauthorized users from `/offerings` and booking inboxes. However, there is **no redirect check** restricting `/home/technician`, `/home/company`, `/home/company-technician`, or `/home/customer` to their respective `AppRole`.
* **Impact:** Any authenticated user (e.g., a `homeowner`) can navigate directly to `/home/technician` or `/home/company` via deep link or URL hash in Flutter Web and view provider UI surfaces.
* **Recommended Fix:** Enforce a strict `role.homeRoute` check in `app_router.dart` whenever `state.matchedLocation.startsWith('/home/')`.

---

### 3. Split & Divergent Admin Provider Data Sources (`AdminPendingProvidersScreen` vs `AdminHome`)
* **Location:** [admin_provider.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/admin/providers/admin_provider.dart), [firestore_admin_provider_service.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/admin/services/firestore_admin_provider_service.dart#L51-L82), [admin_provider_approval_provider.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/admin/providers/admin_provider_approval_provider.dart)
* **Issue:**  
  * `AdminHome` reads `pendingProvidersProvider` & `approvedProvidersProvider` (backed by `FirestoreProviderService`).
  * `AdminPendingProvidersScreen` (`/admin/providers/pending`) reads `pendingProvidersStreamProvider` (backed by `FirestoreAdminProviderService` & `AdminProviderService`).
  * **Bugs caused by this split:**
    1. `AdminProviderService` (`Sokunthea Keo`, `PP Clean & Cool`) and `ProviderService` (`Sokha Pich`, `Mekong Home Repair`) have **completely different** fallback datasets.
    2. Approving a provider in `ProviderReviewScreen` updates `FirestoreProviderService` and invalidates `pendingProvidersProvider`, **without updating `AdminProviderService`**.
    3. `FirestoreAdminProviderService.watchPendingProviders()` emits `_fallbackService` items at `0ms` and then overwrites them with `[]` if Firestore has 0 pending docs, causing a visible UI flicker of fake records before disappearing.
* **Recommended Fix:** Consolidate `AdminPendingProvidersScreen` onto `IProviderService` (`pendingProvidersProvider` / `approvedProvidersProvider`) or a single unified `Stream` on `FirestoreProviderService`, and remove the duplicate `AdminProviderService` mock dataset.

---

### 4. Swallowed Firestore Write Failures & Cloud/Local State Divergence in `FirestoreProviderService`
* **Location:** [firestore_provider_service.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/providers/services/firestore_provider_service.dart#L54-L75), [firestore_provider_service.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/providers/services/firestore_provider_service.dart#L229-L260)
* **Issue:**  
  In `approveProvider`, if `_firestore.collection('providers').doc(providerId).set(...)` throws (e.g., `permission-denied` or network failure), the `catch (e)` block logs a `debugPrint` warning and **continues as if the approval succeeded**, updating only `_sharedLocalProviders`.
* **Impact:**
  1. The Admin UI shows a false success ("Approved & active"), while Firestore still has `status: 'pending_verification'`.
  2. On the next `getProviders()` or `getPendingProviders()` call, if Firestore returns any docs (`snapshot.docs.isNotEmpty`), cloud results overwrite `_sharedLocalProviders`, reverting the UI back to unapproved.
* **Recommended Fix:** Only swallow Firestore errors when explicitly running in an offline/uninitialized mock mode (`Firebase.apps.isEmpty`). When Firebase is active, surface `FirebaseException` to the caller so the UI displays a real error instead of faking persistence.

---

## 🟡 Medium-Severity Issues

### 5. Ephemeral Per-Instance Fallback in `FirestoreOfferingService`
* **Location:** [firestore_offering_service.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/services/services/firestore_offering_service.dart#L14-L60)
* **Issue:** Each `FirestoreOfferingService` instance creates its own non-static `_fallbackService = OfferingService(...)`. If `offeringServiceProvider` is rebuilt or read across contexts without Firebase, in-memory offerings are not shared consistently.
* **Recommended Fix:** Match the explicit provider switching pattern used by `bookingServiceProvider` (`Firebase.apps.isNotEmpty ? FirestoreOfferingService() : OfferingService()`), avoiding mixed cloud/local fallback inside production Firestore classes.

---

### 6. Silent Error Swallowing in `AuthNotifier.checkAuthStatus()`
* **Location:** [auth_provider.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/core/auth/auth_provider.dart#L39-L48)
* **Issue:** `checkAuthStatus()` catches all exceptions with `catch (_) { // Remain unauthenticated on error }`.
* **Impact:** If `getCurrentUser()` throws an `AuthException` (for example, the `companyTechnician` missing-membership error from `SCRUM-198`), the user is silently treated as logged out with no explanation.
* **Recommended Fix:** Catch `AuthException` specifically and transition to `AuthStateError(e.message)` (or log non-auth errors) so users see actionable feedback.

---

### 7. Hardcoded Test Email Overrides in `currentProviderIdProvider`
* **Location:** [provider_provider.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/providers/providers/provider_provider.dart#L13-L22)
* **Issue:**
  ```dart
  if (email == 'technician@test.com') return 'prov-virak-ac';
  if (email == 'company@test.com') return 'prov-fixco-company';
  if (email.contains('sophea.plumb')) return 'prov-dara-plumbing';
  ```
* **Impact:** Mixing hardcoded test email aliases into production Riverpod providers risks mapping real/QA accounts to the wrong `providerId` (which then fails Firestore ownership rules `isOfferingOwner(providerId)` / `ownsBookingInbox(providerId)`).
* **Recommended Fix:** Move test-account seeding to test fixtures/dev seed scripts and resolve `providerId` strictly from `user.companyId ?? user.id`.

---

### 8. `CompanyTechnicianHome` Is Still a Placeholder (`ComingSoonHome`)
* **Location:** [company_technician_home.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/shared/home/company_technician_home.dart#L6-L17)
* **Issue:** Signed-in company technicians see "Coming soon" instead of their assigned jobs list.
* **Status:** Expected gap scheduled for **Sprint 6** (`SCRUM-100 / TECHJOB-1`, `SCRUM-101 / TECHJOB-2`, `SCRUM-102 / TECHJOB-3`).

---

## 🟢 Low-Severity & Quality Issues

### 9. Hardcoded English UI Strings Bypassing Localization (`AppLocalizations`)
* **Locations:**
  * [admin_pending_providers_screen.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/admin/screens/admin_pending_providers_screen.dart) (`'Provider Applications'`, `'Applications awaiting review'`, `'Access Restricted'`)
  * [pending_provider_card.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/admin/widgets/pending_provider_card.dart) (`'Pending Verification'`, `'Approved & active'`, `'Review details →'`)
  * [admin_home.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/shared/home/admin_home.dart) (`'Awaiting review'`, `'Active providers'`, `'Action needed'`, `'View all'`)
  * [customer_home.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/shared/home/customer_home.dart#L207) (`'View all'`)
* **Impact:** When the app locale is switched to **Khmer (`km`)**, these labels remain in English.
* **Recommended Fix:** Move all strings into `lib/l10n/app_en.arb` and `lib/l10n/app_km.arb` and regenerate `flutter gen-l10n`.

---

### 10. Incomplete Widget Test Coverage for Admin Tab Switching & Card Navigation
* **Location:** [admin_pending_providers_test.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/test/features/admin/admin_pending_providers_test.dart)
* **Issue:** The current test suite verifies the `Pending` tab, empty state, RBAC block, and `AdminHome` header, but does not test tapping the `Active` tab (`Key('admin_tab_active')`) or tapping a `PendingProviderCard` to navigate to `ProviderReviewScreen`.
* **Recommended Fix:** Add widget tests for tab switching and card-to-detail navigation.

---

## Suggested Fix Priority Order
1. **Security First:** Fix Issue #1 (`_inferRoleFromEmail` / admin auth alignment) and Issue #2 (missing `/home/*` router role guards).
2. **Data Integrity:** Fix Issue #3 (unify Admin provider data source) and Issue #4 (stop swallowing Firestore write errors in `FirestoreProviderService`).
3. **Reliability & Cleanup:** Fix Issues #5–#7 (`FirestoreOfferingService`, `checkAuthStatus`, hardcoded test emails).
4. **Polish:** Complete Sprint 6 `CompanyTechnicianHome` (#8), localize hardcoded strings (#9), and expand admin tab tests (#10).
