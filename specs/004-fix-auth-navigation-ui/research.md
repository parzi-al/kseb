# Research: Fix Auth Navigation & Login UI

**Branch**: `004-fix-auth-navigation-ui` | **Date**: 2026-03-09  
**Purpose**: Phase 0 research output — structured findings for each topic prior to design/implementation.

---

## Topic 1: Reactive Auth-Driven Navigation in Flutter/Firebase

### Decision

Introduce an `AuthGate` widget that uses `StreamBuilder<User?>` on `FirebaseAuth.instance.authStateChanges()` as the `home:` of `MaterialApp` in `main.dart`. The `AuthGate` returns `SplashScreen` during the initial `ConnectionState.waiting` phase, then branches to `WorkerHomeScreen` (user non-null) or `LoginScreen` (user null). Navigation uses the widget tree rebuild — no imperative `Navigator.push` calls for auth transitions.

Concrete structure:

```
MaterialApp
  └─ home: AuthGate            ← NEW widget
       └─ StreamBuilder<User?>
            ├─ waiting  → SplashScreen (plays animation, no auth logic)
            ├─ user!=null → WorkerHomeScreen
            └─ user==null → LoginScreen
```

The `SplashScreen` becomes a pure animation widget: it plays the sequence and then calls a callback (or simply appears while the stream hasn't emitted). Once `authStateChanges()` emits its first value, the `StreamBuilder` rebuilds and replaces the splash with the correct screen. The splash's existing auth resolution logic (`_resolveAuth`) is **removed** — auth is now the `StreamBuilder`'s responsibility.

Back-button prevention: Since `AuthGate` is the `home:` route and `LoginScreen`/`WorkerHomeScreen` are rendered declaratively inside it (not pushed onto a Navigator stack), the system back button simply exits the app — it cannot navigate "back" to login after auth because there's no navigation stack entry. Alternatively, if screens are pushed via `Navigator.pushReplacement`, `WillPopScope` / `PopScope` can intercept and prevent back navigation.

### Rationale

- `authStateChanges()` is Firebase's recommended stream for reacting to sign-in/sign-out events. It fires on login, logout, and token refresh.
- A `StreamBuilder` at the root ensures **every** sign-in or sign-out from **any** screen triggers navigation automatically — fixing the current broken assumption where both `LoginScreen._signIn()` and `WorkerHomeScreen._showLogoutDialog()` rely on a non-existent `StreamBuilder`.
- Placing the `StreamBuilder` inside `MaterialApp.home` (not wrapping `MaterialApp` itself) preserves theming, localization, and navigation context. Wrapping `MaterialApp` in a `StreamBuilder` would cause the entire `MaterialApp` to rebuild on every auth event, destroying all navigation state and dialogs.
- The splash screen continues to provide the branded cold-start experience — it's just decoupled from auth logic.

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **Keep splash one-shot + add explicit `Navigator.pushReplacement` in `LoginScreen._signIn`** | Fixes login but not logout, nor any future auth state changes (token revocation, force-logout). Fragile — every screen that triggers auth changes needs manual navigation code. Violates FR-009 (reactive listener). |
| **`StreamBuilder` wrapping `MaterialApp`** | Causes full `MaterialApp` rebuild on auth events, losing all state, dialogs, snackbars. Over-scoped and destructive. |
| **`GoRouter` with `redirect` based on auth state** | Excellent long-term pattern, but adds a dependency (`go_router`) and a significant routing refactor. Overkill for <15 screens and current project scope. Could be a future migration. |
| **`Navigator.pushAndRemoveUntil` after login/logout** | Works but is imperative and must be added at every auth-related call site. Not reactive — misses background token revocation or force-logout events. |

### Key Implementation Notes

1. **`authStateChanges()` vs `idTokenChanges()` vs `userChanges()`**: Use `authStateChanges()`. It fires only on sign-in and sign-out events — not on token refresh, which would cause unnecessary rebuilds. `idTokenChanges()` fires on every token refresh (~1hr) and would cause disruptive re-renders. `userChanges()` fires on profile updates too.

2. **Initial `ConnectionState.waiting`**: The stream emits `null` or a `User` almost immediately if the user is already signed in (Firebase caches auth state locally). The `waiting` state is extremely brief on warm starts. The splash animation should be time-gated (show for minimum 1.5s regardless) — overlay this with a `Future.delayed` or the existing animation controller.

3. **Splash integration pattern**: Use an `_isInitialLoad` flag in `AuthGate`. On the very first build, show `SplashScreen` with a minimum duration. Once both the splash timer completes AND the stream emits, transition to the appropriate screen. On subsequent auth changes (login/logout after splash), skip the splash and switch directly.

4. **Back button**: With declarative rendering inside `AuthGate`, the Navigator stack has only one route (the `MaterialApp.home`). The system back button triggers `SystemNavigator.pop()` (app exit), not a back navigation. If using `Navigator.pushReplacement` instead of declarative, wrap destination screens with `PopScope(canPop: false)` to prevent back-to-login.

5. **Login screen no longer needs `Navigator.push`**: `_signIn()` calls `signInWithEmailAndPassword` and does nothing on success — the `StreamBuilder` detects the auth state change and rebuilds the tree. On failure, it shows an error and stays on login. This is already what the current code intends (the comment says "StreamBuilder in main.dart will handle navigation") — the research confirms this is the right approach once the `StreamBuilder` actually exists.

6. **Logout screen no longer needs `Navigator.push`**: Same pattern — `signOut()` triggers the stream, `AuthGate` rebuilds to show `LoginScreen`. The existing code in `worker_home_screen.dart` line 903-904 already does this correctly in intent.

---

## Topic 2: Single Active Session Enforcement with Firestore

### Decision

Use a **field on the user's existing document** (`users/{uid}`) rather than a separate collection. Store `activeSessionToken` (a UUID generated at login) and `lastLoginAt` (timestamp) directly on the user doc. On login, generate a new token and write it. On app resume, read the user doc and compare the stored token to the locally held token — if they differ, force-logout the local user.

For real-time detection (optional enhancement): add a Firestore snapshot listener on the user's own doc to detect when `activeSessionToken` changes while the app is in the foreground.

### Rationale

- The app already has a `users/{uid}` collection and a `UserService` that reads/writes it. Adding 2 fields is far simpler than creating a new `device_sessions` collection with its own security rules, models, and service class.
- For <50 concurrent users, the overhead of a snapshot listener on a single document is negligible.
- A UUID session token is simpler than device fingerprinting and works across all platforms.
- Checking on app resume (via `WidgetsBindingObserver.didChangeAppLifecycleState`) is sufficient per the spec (FR-022: "checked on app resume/interactions").

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **Separate `device_sessions` collection** | Adds a new collection, model class, service, and Firestore rules for a feature that only needs to store one active token per user. Over-engineered for <50 users. Would be justified at scale (hundreds of concurrent sessions per user, audit trail of all sessions). |
| **Subcollection `users/{uid}/sessions`** | Same over-engineering problem. A subcollection makes sense for session history, but for single-active-session enforcement, only the current token matters. |
| **Firebase Cloud Functions to trigger force-logout** | Would provide true real-time push but adds server-side infrastructure, cold-start latency, and deployment complexity. The spec explicitly accepts "on next interaction/resume" detection. |
| **Firebase Realtime Database for presence** | RTDB has native presence support (`.info/connected`), but the project uses Firestore exclusively. Adding RTDB for one feature introduces a second database and billing dimension. |

### Key Implementation Notes

1. **Token generation**: Use `Uuid().v4()` from the `uuid` package, or generate a random string via Dart's `Random.secure()` + base64 encoding. Since the project avoids adding packages, use: `String.fromCharCodes(List.generate(32, (_) => Random.secure().nextInt(33) + 89))` or simpler — `DateTime.now().millisecondsSinceEpoch.toString() + Random.secure().nextInt(999999).toString()`. The token need not be cryptographically unguessable — it's stored in a doc only the user can read.

2. **Race condition (two near-simultaneous logins)**: Use a Firestore transaction to read-then-write the session token. The last writer wins — which is the correct semantic (most recent login is the "active" session). Both devices eventually detect the mismatch; the loser's locally held token won't match the doc.

3. **Offline handling**: If the user is offline at app resume, the session check fails (Firestore read throws). Degrade gracefully: allow continued use and re-check on next connectivity. Do not force-logout on network failure.

4. **Firestore security rules**: The user doc already has rules. Ensure `activeSessionToken` and `lastLoginAt` fields are writable only by the authenticated user whose `uid` matches the doc ID (or by admin).

5. **Local token storage**: Store the session token in-memory (a field on the auth service singleton). It doesn't need persistence — if the app restarts, the user goes through the auth flow again and gets a new token written.

6. **Force-logout UX**: When session mismatch is detected, show a dialog: "You have been signed out because your account was logged in on another device." Then call `FirebaseAuth.instance.signOut()`, which triggers the `authStateChanges()` stream and the `AuthGate` navigates to login.

---

## Topic 3: Client-Side Progressive Rate Limiting for Failed Login Attempts

### Decision

Hold rate-limiting state **in-memory only** (reset on app restart — per FR-017 and spec edge case). Use a simple class `LoginRateLimiter` with a `failedAttempts` counter and a `Timer`-based cooldown. The `LoginScreen` `StatefulWidget` owns an instance of this class. The cooldown thresholds are:

| Consecutive Failures | Cooldown (seconds) |
|---|---|
| 3 | 5 |
| 5 | 15 |
| 8+ | 30 |

During cooldown, the Sign In button is disabled and displays a live countdown ("Try again in Xs").

### Rationale

- In-memory state is explicitly acceptable per FR-017 ("reset after app restart") and the spec edge case ("closes/reopens the app — does the counter reset? Yes").
- A dedicated `LoginRateLimiter` class is easily unit-testable without widget tests.
- `Timer.periodic` with 1-second ticks drives the countdown display via `setState`.
- The class can be injected into `LoginScreen` for testing (mock timers via `fake_async`).

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **Persisted state (SharedPreferences / Firestore)** | Spec explicitly says counter resets on restart. Persistence would punish legitimate users who restart the app. Also adds persistence dependency for no spec benefit. |
| **Server-side rate limiting only (Firebase `too-many-requests`)** | Firebase does throttle, but: (a) the error message is cryptic, (b) the threshold is unpredictable and not configurable, (c) no client-side countdown UX. FR-015 explicitly requires client-side progressive cooldown with visible countdown. |
| **Cooldown on the auth service layer** | Could work, but the cooldown is inherently a UI concern (button disabled state, countdown timer). Keeping it in the screen/widget layer is simpler. The `LoginRateLimiter` helper class provides clean separation without a service. |

### Key Implementation Notes

1. **Countdown timer pattern**: On cooldown start, calculate `endTime = DateTime.now().add(cooldownDuration)`. Start a `Timer.periodic(Duration(seconds: 1), ...)` that calls `setState` to update `remainingSeconds`. When `remainingSeconds` reaches 0, cancel the timer and re-enable the button.

2. **When to increment**: Increment `failedAttempts` only on `FirebaseAuthException` with codes: `invalid-credential`, `wrong-password`, `user-not-found`, `invalid-email`. Do NOT increment on `network-request-failed` (not the user's fault) or `too-many-requests` (already throttled server-side).

3. **Reset conditions**: Reset to 0 on successful login. Reset to 0 on app restart (natural — in-memory state is gone). Do NOT reset on cooldown expiry (the counter persists; only the cooldown timer resets).

4. **Button state**: The Sign In button should be disabled if: (a) `_isLoading` is true (auth in progress), OR (b) `_cooldownRemaining > 0`. Show the countdown text on the button itself or directly below it.

5. **Threshold lookup**: Use a simple sorted map: `{3: 5, 5: 15, 8: 30}`. On each failure, find the highest threshold key ≤ `failedAttempts`. If found, start cooldown with that value. If `failedAttempts < 3`, no cooldown.

6. **Dispose**: Cancel any active `Timer` in `LoginScreen.dispose()` to prevent setState-after-dispose errors.

---

## Topic 4: Idle Timeout / Inactivity Detection in Flutter

### Decision

Use a **`Listener` widget (pointer event listener) at the root of the authenticated widget subtree** (inside `AuthGate`, wrapping only the authenticated screens). On any `PointerDownEvent`, reset a `RestartableTimer`. When the timer fires, call `signOut()`.

Use `Listener` rather than `GestureDetector` because `Listener` captures **all** pointer events without interfering with child gesture recognizers, and it doesn't participate in the gesture arena.

### Rationale

- `Listener` is non-competitive — it passively observes pointer events without absorbing them, so all child buttons, scrollables, and gesture detectors continue to work normally.
- `GestureDetector` participates in the gesture arena and could interfere with child gestures (e.g., canceling a long-press or swipe). It's designed for detecting specific gestures, not passive observation.
- Wrapping only the authenticated subtree means the timeout is only active when the user is logged in — no timer running on the login screen.
- `RestartableTimer` (from `package:async`) or a manual `Timer` that is canceled and restarted on each event.

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **`GestureDetector` with `behavior: HitTestBehavior.translucent`** | Could work with `translucent` to not absorb events, but it's semantically wrong — `GestureDetector` is for recognizing gestures, not passive observation. Also, `translucent` still enters the gesture arena (it just passes events through); under certain conditions it can still interfere with scroll physics or nested gesture detectors. |
| **`RawGestureDetector` / custom gesture recognizer** | Over-complex. A passive `Listener` achieves the same without any gesture recognizer overhead. |
| **`WidgetsBindingObserver` only (lifecycle-based)** | Detects app backgrounding/foregrounding but not in-app inactivity. A user could have the app open and stare at a screen for hours — lifecycle observer wouldn't detect this. Lifecycle observation is complementary (pause timer on background, resume on foreground) but not sufficient alone. |
| **`NotificationListener<ScrollNotification>`** | Only detects scroll events, misses taps on buttons, text input, etc. Too narrow. |
| **Global pointer route via `GestureBinding.instance.pointerRouter`** | Works but is a low-level API that bypasses the widget tree. Harder to scope to authenticated screens only and harder to clean up. |

### Key Implementation Notes

1. **Timer implementation**: Since the project doesn't use `package:async`, implement a simple wrapper: a `Timer?` field that is canceled and replaced on each reset. `_resetTimer() { _idleTimer?.cancel(); _idleTimer = Timer(_timeoutDuration, _onTimeout); }`

2. **Configurable timeout**: Read from Firestore `app_settings/idle_timeout` (or a field in an existing settings doc). Default to 15 minutes. Cache the value locally on app start; update on subsequent reads. The `AuthGate` can fetch this before rendering the idle timeout wrapper.

3. **Lifecycle integration**: Use `WidgetsBindingObserver` in the idle timeout widget:
   - `AppLifecycleState.paused` → cancel the timer (don't logout when app is backgrounded; start a separate background timer if desired).
   - `AppLifecycleState.resumed` → check if the total background time + idle time exceeds the threshold; if so, logout; otherwise, restart the in-app timer with remaining time.

4. **Auth integration**: When the timer fires, call `FirebaseAuth.instance.signOut()`. The `authStateChanges()` `StreamBuilder` in `AuthGate` detects this and navigates to login. Show a snackbar/dialog on the login screen: "You were logged out due to inactivity."

5. **Pointer event throttling**: `Listener.onPointerDown` fires once per touch. Don't use `onPointerMove` — it fires every frame during a drag, which is excessive. `onPointerDown` is sufficient: any user interaction starts with a pointer down event.

6. **Scope**: Wrap only `WorkerHomeScreen` and its sub-screens (the authenticated widget tree). Do NOT wrap the login screen — there's no session to time out on the login screen.

---

## Topic 5: Password Strength Indicator (Custom Widget, No External Packages)

### Decision

Build a custom `PasswordStrengthIndicator` stateless widget that takes the current password `String` and renders a horizontal segmented bar (3 segments for weak/fair/strong) with a text label. Scoring is based on additive heuristics:

| Criterion | Points |
|---|---|
| Length ≥ 6 | +1 |
| Length ≥ 10 | +1 |
| Contains uppercase letter | +1 |
| Contains lowercase letter | +1 |
| Contains digit | +1 |
| Contains special character (`!@#$%^&*...`) | +1 |

Scoring thresholds:
- **0–2 points**: Weak (red)
- **3–4 points**: Fair (amber/orange)
- **5–6 points**: Strong (green)

### Rationale

- Additive heuristics are simple, predictable, and easy to test. Each criterion is independently verifiable.
- Three levels (weak/fair/strong) match the spec requirement (FR-014) and are standard UX.
- A segmented bar is the most common UI pattern for strength meters — users immediately understand it.
- No external packages is a project constraint. The scoring logic is ~15 lines of Dart; unnecessary to pull in a dependency.

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **`zxcvbn` or `password_strength` packages** | Spec constraint: no new packages. Also, these use dictionary-based entropy estimation which is more than needed for a visual indicator. |
| **Entropy-based scoring** | More technically accurate but complex to implement without a dictionary. Additive heuristics are sufficient for a visual indicator (not a security gate — Firebase enforces the actual minimum). |
| **4 or 5 strength levels** | Over-granular for UX. Weak/fair/strong is the standard; more levels confuse users. |
| **Circular progress indicator** | Unusual UX pattern for passwords; segmented bar is universally recognized. |

### Key Implementation Notes

1. **Widget API**: `PasswordStrengthIndicator({required String password})`. Returns `SizedBox.shrink()` when password is empty (don't show the meter before the user starts typing).

2. **Visual design**: Three horizontal segments of equal width. Filled segments use the strength color; unfilled segments use `AppColors.grey200`. Below the bar, show the label ("Weak", "Fair", "Strong") in the corresponding color.

3. **Animation**: Use `AnimatedContainer` for smooth color/width transitions as strength level changes. Duration: ~300ms, curve: `Curves.easeOut`.

4. **Edge case from spec**: "exactly 6 characters with all lowercase" → length ≥ 6 (+1) + lowercase (+1) = 2 points → Weak. "mixed-complexity 6-character" (e.g., "Aa1!bc") → length ≥ 6 (+1) + uppercase (+1) + lowercase (+1) + digit (+1) + special (+1) = 5 → Strong. This differentiation is correct and matches user expectations.

5. **Regex for criteria**:
   - Uppercase: `RegExp(r'[A-Z]')`
   - Lowercase: `RegExp(r'[a-z]')`
   - Digit: `RegExp(r'[0-9]')`
   - Special: `RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]')`

6. **Placement**: Below the password `TextField`, inside the password field's `Container`. Appears only when the password field is non-empty.

7. **Accessibility**: Use `Semantics` widget to announce the strength level to screen readers: `Semantics(label: 'Password strength: Weak')`.

---

## Topic 6: Login Screen Icon Centering and Animation

### Icon Centering

### Decision

The icon container is currently placed inside a `Column` that has `CrossAxisAlignment.stretch`. The inner `Column` (containing icon, title, subtitle) uses default `CrossAxisAlignment.center`, but the outer `Column` with `stretch` forces its direct children to expand to full width. The inner `Column` is a direct child of the outer `Column`, so it gets stretched.

**Fix**: Wrap the inner `Column` (the one with the icon) in a `Center` widget, or change the inner content to explicitly use `CrossAxisAlignment.center` and wrap the icon `Container` in a `Center` or `Align` widget. Alternatively, since the inner items (`Container`, `Text`) are already centered within their own `Column`, the issue may be that the icon `Container` doesn't have `alignment: Alignment.center` and inherits the stretch from the parent.

The simplest, most correct fix: **Wrap the icon `Container` in a `Center` widget**. `Center` ignores the parent's cross-axis stretch and centers its child.

```dart
Center(
  child: Container(
    padding: ...,
    decoration: BoxDecoration(shape: BoxShape.circle, ...),
    child: Icon(Icons.bolt_rounded, ...),
  ),
),
```

### Rationale

- `CrossAxisAlignment.stretch` on the outer `Column` is needed for the text fields and button to fill the width. Changing it would break the form layout.
- `Center` is the idiomatic Flutter widget for centering a child. It's a single-widget wrapper with no performance cost.
- The inner `Column` (header section) has its own `children` alignment, but the icon `Container` is a `BoxDecoration(shape: BoxShape.circle)` — it will try to expand to fit its parent's constraints when stretched. Wrapping in `Center` constrains it to its intrinsic size.

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **Change outer `Column` to `CrossAxisAlignment.center`** | Breaks the text fields and button — they need stretch to fill the width. |
| **Use `Align(alignment: Alignment.center)`** | Works identically to `Center` (which is just a shorthand for `Align(alignment: Alignment.center)`). `Center` is more readable. |
| **Add fixed width to the icon container** | Would center it visually but is fragile across screen sizes. |
| **Use a separate `Row(mainAxisAlignment: MainAxisAlignment.center)` wrapper** | Over-complex for centering a single widget. |

### Animation: Scale-In + Glow/Pulse

### Decision

Use a **single `AnimationController`** driving two concurrent animations:

1. **Scale-in**: `Tween<double>(begin: 0.0, end: 1.0)` with `Curves.easeOutBack` over 600ms. Gives a natural overshoot effect (slightly exceeds 1.0 then settles).
2. **Glow pulse**: An outer `Container` with `BoxShadow` whose `spreadRadius` and opacity are animated. Use a second `Animation` on the same controller, `Tween<double>(begin: 0.0, end: 1.0)` with a `CurveTween(curve: Curves.easeInOut)` — the glow peaks at ~60% of the animation, then fades.

The animation auto-plays in `initState` and is non-repeating (plays once). Total duration: ≤800ms (under the 1-second FR-007 requirement).

### Rationale

- A single controller with multiple tweens is simpler than multiple controllers and ensures the animations are perfectly synchronized.
- `easeOutBack` gives a polished "pop" effect that feels modern — commonly used in iOS and Material Design entrance animations.
- A subtle glow (box shadow animation) adds a premium feel without being distracting.
- Non-repeating respects user attention — a continuous pulse would be distracting during form entry.

### Alternatives Considered

| Alternative | Why Rejected |
|---|---|
| **`AnimatedScale` / implicit animation** | Can't synchronize with the glow. Need explicit control for coordinating two animation properties. |
| **Lottie animation** | Requires `lottie` package (not allowed) and an animation file. Over-complex for a simple scale + glow. |
| **Hero animation from splash** | Interesting but the splash icon is `Icons.flash_on` (size 80) while the login icon is `Icons.bolt_rounded` in a circle container — different widgets. A Hero would require matching widget trees, which adds complexity and constrains both screens' layouts. |
| **Continuous pulse/glow loop** | Distracting while the user is trying to enter credentials. A one-shot entrance animation is more professional. |

### Key Implementation Notes

1. **Reduce-motion accessibility**: Check `MediaQuery.of(context).disableAnimations` in `didChangeDependencies`. If true, set `_controller.value = 1.0` (jump to end state) without calling `.forward()`. This shows the final centered icon without any animation, satisfying FR-008.

2. **Controller setup**:
   ```
   _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
   _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
   _glowAnimation = TweenSequence([
     TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 60),
     TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
   ]).animate(_controller);
   ```

3. **Glow rendering**: Use `AnimatedBuilder` wrapping the icon container. Apply `BoxShadow(color: AppColors.primary.withOpacity(glowValue * 0.4), spreadRadius: glowValue * 12, blurRadius: glowValue * 20)`.

4. **Performance**: The animation uses a single `AnimationController` with 2 tweens — one repaint per frame for ~800ms × 60fps = ~48 frames. Negligible performance cost.

5. **Add constants to `AnimationConstants`**:
   - `loginIconScaleDuration: Duration(milliseconds: 800)`
   - `loginIconScaleCurve: Curves.easeOutBack`
   - `loginIconGlowMaxOpacity: 0.4`
   - `loginIconGlowMaxSpread: 12.0`

6. **Integration with `LoginScreen`**: `LoginScreen` must become a `StatefulWidget` with `TickerProviderStateMixin` (it already is). Add the animation controller in `initState`, dispose in `dispose`, and wrap the icon container in `AnimatedBuilder`.
