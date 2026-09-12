# TimeControl

An Opal-style time-management app for iPhone. Focus sessions with a strict mode,
guilt-trip notifications, a Shortcuts-driven "you opened it" intervention, and
streak tracking. A full app-blocking build is included behind a flag.

Built with SwiftUI (+ FamilyControls / ManagedSettings / DeviceActivity in the
paid build).

---

## ⚠️ Two builds — pick based on your Apple account

Apple only allows the app-blocking capability (**Family Controls**) and **App
Groups** on a **paid** Developer account. A free Apple ID ("Personal Team") gets a
`Cannot create a provisioning profile … Personal development teams do not support
the Family Controls (Development) capability` error. So there are two builds:

| Build | Account needed | What you get |
|---|---|---|
| **Free build** (current default) | Free Apple ID | Focus timer, guilt notifications, Shortcuts "open app → full-screen intervention", stats/streaks. **No in-app blocking.** |
| **Full build** | Paid Developer Program ($99/yr) | Everything above **plus** real on-demand + scheduled app blocking via the Screen Time API. |

Both need **a Mac with Xcode 15+** and **a real iPhone (iOS 16+)** — Family
Controls doesn't run on the Simulator.

The free build is what `project.yml` produces right now (it defines the
`FREE_TIER` compile flag and drops the entitlement + extensions). To switch to the
full build, see *Upgrading to the full blocking build* below.

---

## Quick start (free build)

```bash
git clone <this-repo>
cd time-control
./bootstrap.sh        # installs XcodeGen if needed, generates the project, opens Xcode
```

Then in Xcode:

1. **Signing** — select the **TimeControl** target → *Signing & Capabilities* →
   check *Automatically manage signing* → pick your **Team** (your free Apple ID
   is fine).
2. **Bundle ID** — if signing says the identifier is taken, change
   `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to something unique
   (e.g. `com.<yourname>.timecontrol`) and re-run `./bootstrap.sh`.
3. Plug in your iPhone, choose it as the run destination, press **⌘R**.
4. First launch on the device: *Settings → General → VPN & Device Management* →
   trust your developer profile. Grant notification permission when asked (needed
   for guilt nudges).

Then set up the Shortcuts intervention (see below) to get blocked-on-open behavior
without the paid account.

---

## Upgrading to the full blocking build

The blocking code (the three extensions + entitlements) is still in the repo. Once
you're in the paid Apple Developer Program, turn it back on:

1. In `project.yml`, **remove** `SWIFT_ACTIVE_COMPILATION_CONDITIONS: FREE_TIER`
   from the app target.
2. Re-add the extension targets and the app's `CODE_SIGN_ENTITLEMENTS` /
   `application-groups`. The previous full spec is in this file's git history
   (before the free-build switch) — restore those `targets:` and the app's
   `INFOPLIST_FILE`/entitlement settings.
3. Re-run `xcodegen generate`, set your (paid) Team on all four targets, and build.

The `#if FREE_TIER` guards in the Swift sources already gate the auth flow and the
blocking-only UI, so flipping the flag restores the full app.

## Changing the bundle identifier

The placeholder is `com.jyap.timecontrol`. For the free build you only need the app
target's `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to be unique to your Apple
ID. For the full build, also keep the extension IDs prefixed by the app's ID and
update `AppGroup.identifier` in `Shared/SharedConstants.swift` and the three
`.entitlements` files to match.

---

## Architecture

```
TimeControl (app)                SwiftUI UI, session control, schedule editing, stats
 ├─ DeviceActivityMonitorExtension  applies/removes shields on schedule even when app is closed
 ├─ ShieldConfiguration             the custom "app blocked" screen
 └─ ShieldAction                    button handling on the block screen (strict mode)
        ▲
        │  App Group (shared UserDefaults) — selections, schedules, session + history
        ▼
Shared/  code compiled into every target
```

Key frameworks:

- **FamilyControls** — authorization + the `FamilyActivityPicker` (apps come back as
  opaque tokens; the app never sees which apps you picked).
- **ManagedSettings** — `ManagedSettingsStore` applies the shield (the block).
- **DeviceActivity** — schedules the on/off windows and wakes the monitor extension.

### How each feature works

- **On-demand focus session** — applies the shield immediately, saves an
  `ActiveSession`, and schedules a DeviceActivity window as a backstop so the block
  lifts even if the app is killed. An in-app timer ends it precisely.
- **Scheduled blocks** — one DeviceActivity monitor per active weekday
  (`repeats: true`); the monitor extension shields/unshields on the boundaries.
- **Strict mode** — hides the "end early" control in-app; the shield screen offers
  no unblock path, so the block holds until the window ends.
- **Stats & streaks** — computed from the app's own session history (fully reliable,
  no extra entitlement needed).
- **Guilt nudges** — scheduled local notifications with rotating tough-love messages
  ("You are wasting your life"). No entitlement needed; fire even when the app is
  closed. Configured under Settings → Nudges.
- **Free "block on open" intervention** — see below.

---

## Nudges & the free intervention (no paid account needed)

Two features work **without** the Family Controls entitlement, so they're useful
even before you set up signing:

**1. Scheduled guilt nudges.** Settings → Nudges → turn on and pick times. The app
fires ordinary local notifications with rotating messages from
`Shared/NudgeMessages.swift` (edit them to taste).

**2. Opal-style "you opened it" intervention via Shortcuts.** A normal app can't see
which app you open, but iOS **Shortcuts automations** can — for free. TimeControl
listens on the `timecontrol://intervene` URL and, when opened that way, shows a
full-screen intervention (with a 10-second delay on the "continue anyway" button).

Set it up on your phone:

1. Open the **Shortcuts** app → **Automation** tab → **＋** → **App**.
2. Choose **Is Opened**, pick the distracting apps (Instagram, TikTok, …), **Next**.
3. **New Blank Automation** → add action **Open URLs** → enter `timecontrol://intervene`.
4. Turn **off** *"Ask Before Running"* so it fires silently.

Now opening a chosen app bounces you into TimeControl's guilt screen first. It's a
speed bump, not a hard block — but that friction is most of what Opal's nudges do.

---

## Source layout

```
project.yml                         XcodeGen spec (source of truth for the .xcodeproj)
bootstrap.sh                        one-command setup on a Mac
Shared/                             code shared by app + extensions
  SharedConstants.swift             App Group id, storage keys, activity ids
  SharedModels.swift                BlockSchedule, SessionRecord, ActiveSession
  SharedStore.swift                 App Group UserDefaults persistence
  ShieldController.swift            apply/clear ManagedSettings shields
Sources/App/                        the SwiftUI app
  TimeControlApp.swift              @main
  Store/AppState.swift              orchestrates sessions, schedules, stats
  Store/AuthorizationManager.swift  Screen Time authorization
  Views/                            Home, FocusSession, Schedules, Stats, Settings, picker
  Resources/Assets.xcassets         accent color + app-icon slot (add your 1024px icon)
Sources/Monitor/                    DeviceActivityMonitor extension
Sources/Shield/                     ShieldConfiguration + ShieldAction extensions
```

---

## Known limitations / roadmap

- **Enabling a schedule mid-window** doesn't block until the next occurrence
  (DeviceActivity fires on boundaries, not retroactively).
- **Very short sessions (< ~15 min)** rely on the in-app timer; the DeviceActivity
  backstop has a ~15-minute minimum, so if you force-quit the app during a very
  short session the shield clears on next launch rather than exactly on time.
- **No live system screen-time report yet.** Stats are from TimeControl's own
  sessions. A future `DeviceActivityReport` extension could show real per-app usage.
- Add your own **1024×1024 app icon** to `AppIcon.appiconset`.

Possible next steps: usage-report extension, session presets/favorites, block "app
groups" you reuse, Live Activity countdown on the Lock Screen, iCloud sync of
schedules, a hard "unblock delay" instead of full strict lock.

---

## No Mac? / alternatives

You can't build or install an app that blocks other apps without macOS + Xcode +
a paid developer account. Interim options: a **cloud Mac** (MacinCloud, AWS EC2 Mac)
to build once, or Apple's built-in **Screen Time** limits driven by a **Shortcuts**
automation — less flexible, but zero code.
