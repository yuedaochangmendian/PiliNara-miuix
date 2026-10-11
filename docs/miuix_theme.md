# Miuix Theme

## Overview

PiliNara's theme *is* the miuix theme. Colors, corner radii and the type scale are all taken from
Miuix, the MIUI / HyperOS design system, instead of being derived from Material defaults:

* **Colors** — the MIUI color roles of `top.yukonga.miuix.kmp.theme.Colors`, including the fixed
  MIUI light and dark palettes and the Monet-style generation miuix uses for key colors.
* **Shapes** — MIUI's corner radii: 16 for cards, buttons, text fields and menus, 32 for dialogs,
  28 for the top corners of a bottom sheet, 12 for tooltips, and a 52 dp top bar.
* **Type scale** — Miuix's fourteen text slots (main 17, body2 14, footnote1 13, title1 32 …).

## Where it lives

| File | Contents |
|------|----------|
| `lib/utils/miuix/miuix_colors.dart` | The `MiuixColors` token set: `light` / `dark` are ported 1:1 from miuix's `lightColorScheme()` / `darkColorScheme()`. Also holds the mapping to Material's `ColorScheme` and the translation of any other scheme into MIUI roles. |
| `lib/utils/miuix/miuix_shapes.dart` | `MiuixShapes`, the corner radii and bar heights of the miuix components. |
| `lib/utils/miuix/miuix_text_styles.dart` | `miuixTextTheme()`, Miuix's type scale as a Material `TextTheme`. |
| `lib/utils/miuix/miuix_theme.dart` | `MiuixTheme.getThemeData()`, which builds the app's `ThemeData` from those tokens (card, dialog, bottom sheet, popup menu, top bar, snackbar, tooltip, switch, slider, buttons, navigation bars). |
| `lib/utils/theme_utils.dart` | The app's entry point: `ThemeUtils.getThemeData()` resolves a `MiuixColors` and applies the pure-black mode on top. |
| `lib/models/common/theme/theme_color_type.dart` | `miuixKeyColor` (MIUI blue) and its position in the palette picker. |

## How a color scheme is resolved

`MyApp.getAllTheme()` in `lib/main.dart` picks one of three paths:

1. **MIUI blue (the default)** — selecting `MIUI 蓝` uses miuix's fixed palettes
   (`MiuixColors.light` / `MiuixColors.dark`) verbatim. This is what miuix itself renders in its
   default `ColorSchemeMode.System`, and it is what a new install gets.
2. **A brand color** — the chosen seed is turned into a Material scheme by `flex_seed_scheme`
   (tonal spot, i.e. miuix's default palette style) and then translated into MIUI roles by
   `MiuixColors.fromColorScheme()`, the inverse of miuix's `mapMd3RolesToMiuixColorsCommon`.
   That is miuix's Monet mode.

Material 3's own colour features are gone: the dynamic colour (Monet-from-wallpaper) toggle and the
palette-style picker were removed from the settings, along with the page-transition and predictive
back switches. The theme is now miuix's fixed palette or the brand colour the user picks, and the
motion below.

Whatever the path, `ThemeUtils.getThemeData()` ends up with a `MiuixColors` and builds the theme
from it, so a custom brand color keeps MIUI's neutral fills, dividers and dimming rather than
Material's.

## Mapping to Material roles

PiliNara's widgets read Material's `ColorScheme`, so the MIUI tokens are mapped onto it:

| Material | miuix |
|----------|-------|
| `primary` / `onPrimary` | `primary` / `onPrimary` |
| `primaryContainer` / `onPrimaryContainer` | `primaryContainer` / `onPrimaryContainer` |
| `primaryFixed` / `onPrimaryFixed` | `primaryVariant` / `onPrimaryVariant` |
| `secondary` / `onSecondary` | `onBackgroundVariant` / `onSecondary` |
| `secondaryContainer` / `onSecondaryContainer` | `secondaryContainer` / `onSecondaryVariant` |
| `tertiary` / `tertiaryContainer` | `tertiaryContainer` |
| `surface` / `onSurface` | `surface` / `onSurface` |
| `surfaceContainer` … `Highest` | the same-named tokens |
| `surfaceContainerLowest` / `Low` | `surfaceVariant` / `secondaryVariant` |
| `surfaceDim` / `surfaceBright` | `surfaceContainerHigh` / `surfaceContainer` |
| `onSurfaceVariant` / `outline` | `onSurfaceVariantSummary` |
| `outlineVariant` | `dividerLine` |
| `scrim` | `windowDimming` |
| `inverseSurface` / `onInverseSurface` | `onSecondaryVariant` / `secondaryVariant` |
| `surfaceTint` | transparent (MIUI surfaces are flat and untinted) |

PiliNara has always used `outline` as its secondary text color, so it lands on MIUI's summary text
tone; real dividers are `outlineVariant`, which is `dividerLine`.

Two pairings deliberately differ from miuix's own:

* PiliNara paints icons and labels on `secondaryContainer`, while miuix's `onSecondaryContainer` is
  a placeholder gray (`#A9A9A9` in light mode) that is nearly invisible on the `#F0F0F0` fill.
  miuix pairs that fill with `onSecondaryVariant` (`#303030`), so the app does too.
* `outline` carries PiliNara's secondary text, as described above.
* PiliNara's `secondary` is a *secondary text / icon* tone (and the fallback fill of the bottom
  bar's selection pill), whereas miuix's `secondary` is a neutral fill (`#E6E6E6` in light mode)
  that is unreadable as text. miuix's tint for content on a surface is `onBackgroundVariant`
  (which is what its Monet mapping resolves to `primary`), so `secondary` uses that.

## Type scale

| Material | miuix slot | Size |
|----------|------------|------|
| `displayLarge`, `headlineLarge` | title1 | 32 |
| `displayMedium`, `headlineMedium`, `headlineSmall` | title2 | 24 |
| `displaySmall`, `titleLarge` | title3 | 20 |
| `titleMedium` | headline1 | 17 |
| `titleSmall` | headline2 | 16 |
| `bodyLarge` | main (paragraph, body1 fold in here) | 17 |
| `bodyMedium` | body2 | 14 |
| `bodySmall` | footnote1 | 13 |
| `labelLarge` | button | 17 |
| `labelMedium` | subtitle | 14, bold |
| `labelSmall` | footnote2 | 11 |

Miuix only sets a line height on `paragraph` (1.2 em), so the styles leave `height` unset and let
the font's own metrics apply. `title4` (18) has no separate Material role; it sits next to
`titleMedium` and `titleLarge`. The font family and weight preferences still override every role,
as they did before.

Miuix takes its text color from `LocalContentColor`; Flutter's widgets read it out of the
`TextTheme` roles instead, so `miuixTextTheme()` is called with `color: onSurface`. Without it,
widgets such as `ListTile` would paint black text on a `#242424` card in dark mode.

## Limits of the port

* MIUI has fewer surface levels than Material 3. `surfaceDim` / `surfaceBright` and the two lowest
  container roles are therefore derived, as listed above.
* MIUI has no inverse roles, no `surfaceTint` and no `background` slot in Material's `ColorScheme`
  any more; those are derived as described in the table.
* PiliNara's pure-black mode is kept: it still darkens the canvas and each container layer on top
  of the MIUI palette.
* The continuous corners are drawn as a path (see below) rather than with miuix's runtime shader,
  and a `BoxDecoration` only accepts a `BorderRadius`, so tooltips keep circular corners.

## Miuix behaviours

The theme does not stop at tokens: miuix's interaction and surface behaviour is applied too.

### Continuous corners (squircle)

MIUI / HyperOS corners are *continuous*: the corner tile is `cornerRadius × 1.1`, and the straight
edges meet it through a cubic Bézier with a fixed control ratio of `0.643` — miuix's
`SquircleDefaults.Extension` and `SQUIRCLE_CONTROL`. `lib/utils/miuix/miuix_squircle.dart` builds
that silhouette as a `Path` and exposes it as `MiuixSquircleBorder` (and
`MiuixSquircleInputBorder` for fields), so cards, dialogs, sheets, popup menus, buttons and the
navigation indicator all use it. Bottom sheets use the top-only variant, and `enabled: false` falls
back to plain rounded corners, which is what miuix itself does where the runtime shader is
unavailable.

### Press feedback

Material's ripple (on Android M3, `InkSparkle`) is replaced by `MiuixIndication`: a press fades a
flat 10 % overlay over the whole surface — 200 ms in, 350 ms out — which is miuix's
`MiuixIndication` with `PRESS_ALPHA_DELTA = 0.10` and its 0.2 s / 0.35 s springs. miuix additionally
folds hover (6 %) and focus (8 %) into the same overlay; in Flutter those remain the job of
`InkWell.overlayColor`.

Two details of Flutter's ink pipeline matter here:

* The overlay is a **press** tint, so it has to fade in when the ink feature is *created* (touch
  down), not in `confirm()`: Flutter only calls `confirm()` when the tap is recognised, i.e. on
  release, so ramping up there makes the tint invisible while a finger is held down.
* The fade-out has to be scheduled by `confirm()` (and `cancel()`) itself, because Flutter never
  calls `cancel()` after a successful tap. Without it the 10 % tint stays on every widget that was
  tapped — a colour block left behind on the previously selected tab.
* The drawing itself goes through the SDK's `paintInkCircle`: ink features work in the *reference
  box's local coordinates* and must apply the transform Flutter passes in. Skipping it paints the
  overlay at the shared `Material`'s origin, so in a bottom bar or a tab bar (many `InkWell`s on one
  `Material`) every press appears on the **first** item. A large radius plus a clip to the control's
  own rect/shape produces miuix's flat block rather than a circular ripple.

### Text fields

MIUI fields are filled rather than outlined: `secondaryContainer` background, 16 dp continuous
corners, no border until focus (primary) or error (error colour), 12 dp inner padding. That is the
`InputDecorationThemeData` in `MiuixTheme`.

### Bottom sheets

Sheets carry miuix's drag handle: a 24 dp grab strip with a 45 × 4 dp pill (radius 2) at 20 % of the
`onSurfaceVariant` tone, growing to 55 dp / 35 % while pressed. `MiuixDragHandle` is painted above
the sheet content by `lib/common/widgets/scaffold/bottom_sheet.dart`; it draws and listens for the
press only, so dragging still belongs to the sheet's own gesture recogniser.

### Overscroll

MIUI stretches the scrollable at its ends instead of showing the Android glow. PiliNara's
`CustomScrollBehavior` already used `StretchingOverscrollIndicator` on Android, which matches
miuix's `MiuixOverscrollEffect`, so this needed no change.

### Backdrop blur

`lib/utils/miuix/miuix_blur.dart` is the `miuix-blur` module: `BlurDefaults` is a 20 dp radius with
a 150 dp cap, and `MiuixBlur.sigmaFor` maps a radius onto `ImageFilter.blur`'s sigma (a 1 : 1.7
empirical ratio). `MiuixBackdrop` is the plain backdrop (blur plus a tint), `MiuixProgressiveBlur`
approximates the progressive variant with a stack of increasing sigmas. The bottom navigation bar
uses it: 82 % opaque `surfaceContainer` plus a 20 dp blur of the content behind it.

miuix's blur also mixes in `BlurColors` and an anti-banding noise overlay; neither can be
reproduced with `BackdropFilter` (it takes a fixed sigma and has no shader channel), so they are
left out — the difference is not visible at these radii.

### Cascading popup

`lib/utils/miuix/miuix_cascading_popup.dart` reproduces the menu that grows out of the row you
tapped (`CascadingMorphContent` + `CascadingListPopupLayout`): the clip rect is lerped from the
anchor rect to the popup rect (`popupClipReveal`) while the content scales from
`ENTER_SCALE_FROM` 0.15 to 1 (`ENTER_SCALE_RANGE` 0.85), the surface is a 16 dp continuous corner,
the barrier is `windowDimming`, and the popup is clamped to 200–288 dp with at most 8 rows before
it scrolls. It is a transparent route plus a `ClipPath`, with the curve and duration from
`MiuixMotion`.

### Motion

`lib/utils/miuix/miuix_motion.dart` carries miuix's own timing instead of Flutter's defaults:

* `MiuixMotion.programmatic` is the curve miuix bakes for programmatic navigation
  (`NavProgrammaticEasing`): the step response of an underdamped spring (response 0.8, damping 0.95)
  solved point by point — a brisk middle and a long tail, played over
  `MiuixMotion.programmaticDuration` (500 ms, `NavDriverSpec.PROGRAMMATIC_DURATION_MILLIS`).
* `MiuixMotion.returning` is the return-only curve, and it is a plain quintic (`t⁵`) rather than a
  baked spring. The route's animation value runs 1 → 0 while a page pops, so `returning(value)` is
  the fraction of the page still on screen, and the quintic reads as "most of the way out almost
  immediately": 41 % of the screen after 10 % of the interval, 83 % after 30 %, 99 % after 60 %
  (miuix's own curve, played the same way, gives 5 % / 48 % / 84 %). Note the direction matters: an
  earlier attempt reused a fast-*rising* spring here, which in this descending domain left the page
  parked almost in place until the very end. This is a deliberate PiliNara-side deviation from miuix
  (which plays one 500 ms curve both ways): a return already knows where it is going. It is paired
  with `returnDuration` (240 ms; GetX hard-codes its own routes at 300 ms, so this only reaches
  routes built through `MaterialRouteTransitionMixin` — the curve applies everywhere), with
  `gestureSpring` (stiffness 260, still critically damped) for both gesture settles, and with the
  early finalize described below.
* `decelerate` / `accelerate` / `sinOut` are miuix's `DecelerateEasing`, `AccelerateEasing` and
  `SinOutEasing`.
* `spring(damping, response)` is `folmeSpring`: stiffness `(2π / response)²`, damping ratio as given.
* `fast` / `fastExit` / `enter` / `exit` are the durations miuix's own components use (sheet handle
  100 / 150 ms, press feedback 200 / 350 ms).

The theme installs `MiuixPageTransitionsBuilder` for every platform: the entering page slides in
full width from the trailing edge and the covered page parallaxes a quarter width with a 10 % alpha
falloff — miuix's `NavTransitions.MiuixDefault` geometry with the motion above.

The covered page is additionally dimmed by up to 50 % (`NavDisplayEffects.dimAmount`) as the motion
runs, which is how miuix's effect layer darkens the layer below the entering one.

GetX drives all in-app navigation (189 `Get.toNamed`, 49 `Get.to`, no per-call `transition:` or
`duration:` overrides), and its `Transition.native` defers to `ThemeData.pageTransitionsTheme`, so
every `GetPageRoute` uses this builder too — GetX's own `rightToLeftWithFade` would only cover the
entering slide, with GetX's timing.

The covered page needs one supplement. Flutter hooks the page below up only when
`previousRoute.canTransitionTo(nextRoute)` **and** `nextRoute.canTransitionFrom(previousRoute)` are
both true (`TransitionRoute._updateSecondaryAnimation`), and GetX's
`GetPageRouteTransitionMixin.canTransitionTo` accepts nothing but a `MaterialRouteTransitionMixin`
on top — so for GetX → GetX the covered page never ran its secondary animation at all, and the
quarter-width parallax and the dim were invisible there. `lib/utils/miuix/miuix_navigation.dart`
adds that driver back: `MiuixNavigatorObserver` keeps the route stack, applies the framework's own
test, and hands `MiuixCoverController` the animation of the route above for every pair the
framework will not drive itself. `MiuixNavigationScope` (installed above the navigator in
`MaterialApp.builder`) passes it down to `MiuixPageTransition`, which uses it in place of
`secondaryAnimation`. The entry is dropped again when that animation reaches zero, and because the
condition mirrors the framework exactly, no cover effect is ever applied twice (Material → Material
stays the framework's own single one).

### Back gesture (miuix-nav)

The same builder carries miuix-nav's gesture layer, so a page can be peeled away by finger. The
three phases follow `NavSwipeArbitrator` / `snapToFinger` / `navBackCommitDecision`:

* **Engagement.** The activation dead zone is the system touch slop and only dismissal-direction
  travel counts: the page does not move until the finger has travelled past `kTouchSlop`, and the
  travel inside the dead zone is added on top (`initialDismissTravelPx = towardTravelPx - touchSlop`),
  so the page catches up instead of restarting at the claim point. A drag that goes *against*
  dismissal past the dead zone, or whose cross-axis travel dominates, is left to the page.
  `dragStartBehavior: down` is what makes the pre-claim travel available, exactly as miuix measures
  it from the down event.
* **Follow.** Once claimed there is no interpolation at all — the route's animation value *is* the
  finger position (miuix's `snapToFinger`, "no easing on this axis"). Cross-axis wiggle neither
  steals nor cancels; a gesture only ends when the finger lifts.
* **Settle.** The release is classified by `navBackCommitDecision` — velocity first (≥ 1 progress
  unit/s decides by sign), position as the fallback (≥ 0.5 commits) — and the release velocity is
  handed to the settle spring as its initial velocity, so position *and* velocity stay continuous.
  Both directions use `MiuixMotion.gestureSpring` (stiffness 260 instead of miuix's 146,
  `DAMPING_RATIO` 1), which keeps the critically damped shape and only makes the hand-off quicker.
  A commit floors that seed at
  `-sqrt(stiffness) * distance` (`commitVelocityFloor`), which is the exact no-overshoot bound of a
  critically damped spring, so a flung release cannot bounce past the popped position. The
  visibility threshold is miuix's `VISIBILITY_THRESHOLD` (0.0025).

Once a page is visually out of frame, the transition does not wait for the rest of the route's
duration: `MiuixPageTransition` watches its own animation during a pop and calls
`NavigatorState.finalizeRoute` as soon as `returning(value)` (the on-screen fraction) drops to 2 %.
That matters because the covered page keeps its dim and quarter-width parallax until the popped
route is finalized, and the framework only finalizes it after *the whole* reverse duration — which
GetX hard-codes at 300 ms. Finalizing on the visual end instead means the page below snaps back,
loses its dim, and becomes tappable where it is actually drawn, right when the return looks done.
The popped route hands its cover binding back on the way out (`MiuixCoverController.releaseDriver`),
and controller notifications made while the widget tree is locked (a `dispose`, for instance) are
deferred to the end of the frame.

Input blocking follows miuix as well: miuix consumes both axes and blocks taps and scrolls *until the
release*, so the navigator's user-gesture flag is cleared the moment the finger lifts (or the
platform's predictive-back terminal signal arrives) and the settle spring keeps running on its own.
That flag matters because `_ModalScopeState` wraps every route in
`IgnorePointer(ignoring: route.animation.status == reverse || navigator.userGestureInProgress)` —
holding it through the settle leaves the whole app unclickable until the animation ends. The
layer's own "hand-driven" flag (`MiuixCoverController.gestureDriven`) is what keeps the page and the
covered page at 1 : 1 through the settle instead.

Because that navigator flag is global (a single counter for the whole navigator), the layer never
starts it twice and never leaves it behind: the in-app gesture and the platform's predictive back
are mutually exclusive (whichever engages first owns the gesture, the other one declines), the flag
is dropped at release, and every finished settle (and every disposed transition) reconciles it —
if the layer is not gesturing and the controller reports no hand-driven page while the navigator
still holds the flag, one `didStopUserGesture()` is issued to heal the leak. Without that, a single
unpaired start would leave *every* route ignoring pointers, which is what "the page under the one I
just left cannot be tapped" looks like from the outside.

Predictive back is implemented in the same widget: the builder is the `WidgetsBindingObserver` that
claims `handleStartBackGesture`, so Android U+ system edge gestures drive the page 1:1 through
`handleStartBackGesture` / `handleUpdateBackGestureProgress`, and the platform's terminal signal
settles through the same spring (`navBackCompletionDecision`, velocity 0 → accept). This also
restores the finger-following preview that registering a custom builder for Android otherwise
replaces: `PredictiveBackPageTransitionsBuilder` is what normally claims the gesture.

Known differences from miuix-nav:

* miuix attaches `navSwipeDismiss` to the display container (a transition in flight can be grabbed
  anywhere) and it is opt-in per route (`swipeDismiss` defaults to `NavSwipeDirection.None`). Here
  the in-app gesture is limited to a 20 dp leading-edge strip — Android's own back-gesture hot
  zone — so it cannot steal horizontal lists or the player's seek gesture, and it is on by default
  (`MiuixPageTransitionsBuilder(swipeBack: false)` disables it).
* Flutter's gesture arena decides content-first ownership instead of miuix's pointer-consumption
  arbitration; the verdicts agree in practice (a drag that belongs to an inner scrollable wins the
  arena), but the "one move of confirmation" window has no equivalent.
* miuix drives one shared float for the whole stack, so a gesture can interrupt an in-flight
  transition for any pair of entries. Here one route's animation is grabbed; grabbing mid-flight
  still works, because `handleStartBackGesture` stops the running animation and the anchor keeps the
  first frame jump-free, but each route settles on its own.
* `NavGesture`'s `swipeEdge` / `touchY` context (transitions that pivot around the touch point) is
  not surfaced — no preset in this app uses it.

### Icons

miuix ships its icons as vectors, not as an icon font: one Kotlin `ImageVector` per icon (156 icons,
five weights, `MiuixIcons.<Name>` is the regular one), with a 1297.2 viewport and a
`group(scaleY = -1, translationY = viewport)` wrapper. `tool/gen_miuix_icons.dart` reads the Kotlin,
keeps the regular weight, bakes the flip and the 24 : 1297.2 scale into the coordinates and emits an
SVG-style command string per icon into `lib/utils/miuix/miuix_icon_data.dart`; `MiuixIcon` parses
those strings (cached) and paints them, taking its colour from `IconTheme` like `Icon` does. The
settings pages and shared widgets use the miuix set for the icons that map one-to-one (back, close,
more, search, refresh, delete, download, share, settings, add, play/pause, clear, filter, sort, copy,
edit, info, help, lock, update); business pages still use Material icons.

### Continuous corners: path, not shader

miuix's own squircle module is shader-backed, but the "shader" is a **pre-baked SDF bitmap**
(`AlphaImageBitmap` plus the note in `SquirclePath.kt` that the path control ratio must match the
value the SDF was baked for) sampled by the runtime-shader APIs, with a plain rounded-rect fallback
where shaders are unavailable. Reproducing that in Flutter would mean baking the same SDF from the
same path and sampling it through a `FragmentProgram` — the silhouette would be identical to what
`MiuixSquircleBorder` already draws, the only gain being cheaper clipping while the corners animate,
at the cost of a shader asset in the build and Impeller/Skia differences. That trade is not worth it
here, so the path implementation stays as the production one.

### Bottom navigation bar

The theme sets the bar's fill to `surfaceContainer` (MIUI's floating bar; the page is `surface`) and
`indicatorColor` stays unset because PiliNara paints the selected pill itself as a 6 % (light) / 8 %
(dark) overlay; putting an opaque colour into the theme turns the selection into a hard block on the
bar, which is what an earlier revision did. Icon and label colours follow miuix's
`FloatingNavigationBar`, where selected and unselected content share one colour
(`onSurfaceContainer`) and only the indicator marks the selection — miuix's `showDivider` is off by
default, so the bar carries no separators. The label size is Miuix's `footnote2` (11).

## Tests

`test/miuix_theme_test.dart` covers the fixed palettes, the palette picker entry, the role mapping,
the translation of a Material scheme into MIUI roles, the type scale and the shape tokens:

```bash
flutter test test/miuix_theme_test.dart
```
