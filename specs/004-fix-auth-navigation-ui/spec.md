# Feature Specification: Fix Auth Navigation & Login UI

**Feature Branch**: `004-fix-auth-navigation-ui`  
**Created**: 2026-03-09  
**Status**: Draft  
**Input**: User description: "login and logout not working properly when you login even if the login gets successful it doesnt navigate you to the home screen and same case for logout and the login button is not working the round icon is at the left give it a modern animation or keep that thing on centre"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Successful Login Navigates to Home (Priority: P1)

As a worker, when I enter valid credentials and tap the Sign In button, I want to be taken to the home screen immediately after authentication succeeds, so that I can start using the app without being stuck on the login screen.

Currently, after a successful Firebase sign-in, the app relies on a `StreamBuilder` / auth state listener in `main.dart` to detect the change and navigate. However, the app uses a `SplashScreen` as the entry point which performs a one-time auth check and then navigates via `pushReplacement`. After the splash completes, there is no active auth state listener — so successful login on the `LoginScreen` never triggers navigation to the home screen.

**Why this priority**: This is the core broken functionality — users literally cannot access the app after logging in, making the app unusable.

**Independent Test**: Can be fully tested by entering valid credentials on the login screen and verifying that the user lands on the Worker Home Screen within a few seconds.

**Acceptance Scenarios**:

1. **Given** a user is on the login screen with valid credentials entered, **When** the user taps "Sign In" and authentication succeeds, **Then** the user is navigated to the Worker Home Screen without any manual intervention.
2. **Given** a user is on the login screen with invalid credentials, **When** the user taps "Sign In" and authentication fails, **Then** the user remains on the login screen and sees an appropriate error message.
3. **Given** a user is on the login screen and taps "Sign In" while the network is unavailable, **When** authentication times out or fails, **Then** the user sees a clear error message and remains on the login screen.

---

### User Story 2 - Successful Logout Navigates to Login (Priority: P1)

As a worker, when I confirm logout from the home screen, I want to be taken back to the login screen immediately, so that my session is clearly ended and another user could log in.

Currently, after `FirebaseAuth.instance.signOut()` is called in the logout dialog, the code comment says "The StreamBuilder in main.dart will automatically handle navigation" — but no such StreamBuilder exists. The app was refactored to use a splash-based one-time auth check, leaving no active listener to react to sign-out events.

**Why this priority**: Equally critical as login — users cannot securely end their session, which is a security and usability blocker.

**Independent Test**: Can be fully tested by logging in, tapping the logout button, confirming, and verifying that the user is taken back to the login screen.

**Acceptance Scenarios**:

1. **Given** a user is logged in and on the Worker Home Screen, **When** the user taps the logout icon and confirms in the dialog, **Then** the user is navigated to the Login Screen and cannot go back to the home screen using the back button.
2. **Given** a user is logged in and taps logout, **When** the user cancels the logout dialog, **Then** the user remains on the home screen with their session intact.
3. **Given** a user confirms logout but the sign-out request fails (e.g., network issue), **When** the error occurs, **Then** the user sees an error message and remains logged in on the home screen.

---

### User Story 3 - Centered Login Icon with Modern Animation (Priority: P2)

As a user opening the login screen, I want the round bolt icon at the top of the login form to be visually centered and have a polished, modern animation (such as a subtle pulse, glow, or entrance animation), so that the app feels professional and trustworthy.

Currently, the round icon (a circular container with a lightning bolt) is reported to be positioned to the left instead of being centered. It also lacks any animation, appearing static.

**Why this priority**: This is a visual polish issue. The app must be functional first (P1 stories), but the login screen is the first impression and should look professional.

**Independent Test**: Can be tested independently by launching the app, navigating to the login screen, and visually verifying the icon is horizontally centered with a smooth animation.

**Acceptance Scenarios**:

1. **Given** a user is on the login screen, **When** the screen loads, **Then** the round bolt icon is horizontally centered within the screen.
2. **Given** a user is on the login screen, **When** the screen finishes loading, **Then** the bolt icon displays a modern entrance animation (e.g., scale-in with a subtle glow or pulse effect) that completes within 1 second.
3. **Given** a user has accessibility reduce-motion enabled, **When** the login screen loads, **Then** the icon appears centered without animation.

---

### Edge Cases

- What happens when a user presses the hardware/system back button after successful login navigation — can they return to the login screen? (They should not be able to.)
- What happens if the user double-taps the Sign In button rapidly — does it trigger multiple sign-in attempts? (It should be debounced or disabled during loading.)
- What happens if the auth token expires while the user is on the home screen and they try to interact — does the app gracefully redirect to login?
- What happens if `signOut()` is called but Firebase is temporarily unreachable — does the local session persist correctly?
- How does the login icon animation behave on very slow devices or when the screen is rotated mid-animation?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST navigate the user to the Worker Home Screen immediately after a successful login (Firebase `signInWithEmailAndPassword` completes without error).
- **FR-002**: System MUST navigate the user to the Login Screen immediately after a successful logout (Firebase `signOut` completes without error), clearing the navigation stack so the back button does not return to the home screen.
- **FR-003**: System MUST disable the Sign In button and show a loading indicator while authentication is in progress to prevent duplicate submissions.
- **FR-004**: System MUST display clear, user-friendly error messages when login fails (invalid credentials, network error, account disabled, etc.).
- **FR-005**: System MUST display a clear error message when logout fails, keeping the user on the home screen with their session intact.
- **FR-006**: System MUST center the round bolt icon horizontally on the login screen.
- **FR-007**: System MUST display a modern entrance animation on the bolt icon when the login screen loads (e.g., scale-in, pulse, or glow effect), completing within 1 second.
- **FR-008**: System MUST respect the user's reduce-motion accessibility setting by disabling the bolt icon animation when reduce-motion is enabled.
- **FR-009**: System MUST maintain a reactive auth state listener so that auth state changes (login/logout) are detected and navigation happens automatically regardless of which screen initiated the change.
- **FR-010**: System MUST prevent the user from navigating back to the login screen after a successful login using the system back button.

### Key Entities

- **Auth Session**: Represents the current Firebase authentication state (authenticated or unauthenticated). Determines which screen the user sees. Key attributes: user ID, email, authentication status.
- **Navigation State**: Represents the current screen stack. Must be kept in sync with auth session — authenticated users see the home screen, unauthenticated users see the login screen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successful login attempts result in the user seeing the home screen within 2 seconds of authentication completing.
- **SC-002**: 100% of successful logout actions result in the user seeing the login screen within 2 seconds of sign-out completing.
- **SC-003**: The login button is non-interactive during authentication, preventing duplicate sign-in submissions.
- **SC-004**: The bolt icon on the login screen is visually centered (horizontally) on all supported screen sizes and orientations.
- **SC-005**: The bolt icon entrance animation completes within 1 second and provides a polished, modern feel as judged by visual review.
- **SC-006**: Zero regressions in existing splash screen functionality — the splash-to-login and splash-to-home flows continue to work correctly.
- **SC-007**: Users with reduce-motion enabled see the centered icon without animation, with no visual glitches.

## Assumptions

- The app uses Firebase Authentication as its sole auth provider (email/password).
- The `SplashScreen` will continue to handle the initial cold-start auth check and navigate to either Login or Home.
- After the splash screen completes, a separate mechanism (auth state listener or explicit navigation) is needed for subsequent login/logout transitions.
- The bolt icon animation should be lightweight and not delay the user's ability to interact with the login form.
- The existing `AppButton` and `AppLoading` components will be reused for the sign-in button loading state.
- Navigation after login/logout should use `pushReplacement` or equivalent to prevent back-navigation to the previous screen.
