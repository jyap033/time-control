# TimeControl

An Opal-style time-management app for iPhone. Block distracting apps on demand or
on a schedule, run focus sessions with a strict mode you can't cheat, and track
your streaks — all on-device using Apple's Screen Time API.

Built with SwiftUI + FamilyControls / ManagedSettings / DeviceActivity.

---

## ⚠️ Read this first: what you need

This app uses Apple's **Screen Time (Family Controls) API**, which has hard
requirements that a normal app doesn't:

| Requirement | Why |
|---|---|
| **A Mac with Xcode 15+** | iOS apps can only be compiled and signed on macOS. |
| **A paid Apple Developer account** ($99/yr) | The Family Controls capability and App Groups are **not** available with a free Apple ID. Without the paid account the app will build but blocking won't work. |
| **A real iPhone (iOS 16+)** | Family Controls does not function on the Simulator. |

> The Family Controls **Development** entitlement is enabled automatically when you
> add the capability with a paid account. You only need to request special approval
> from Apple if you later distribute on the App Store.

---

## Quick start

```bash
git clone <this-repo>
cd time-control
./bootstrap.sh        # installs XcodeGen if needed, generates the project, opens Xcode
```

Then in Xcode:

1. **Signing** — for **each** of the four targets (`TimeControl`,
   `DeviceActivityMonitorExtension`, `ShieldConfiguration`, `ShieldAction`):
   go to *Signing & Capabilities* and select your **Team**.
2. **Bundle IDs** — change them to your own reverse-domain prefix (see below).
3. Plug in your iPhone, choose it as the run destination, press **⌘R**.
4. On the device, approve the *"...would like to access Screen Time"* prompt, then
   trust the developer profile under *Settings → General → VPN & Device Management*.

---

## Changing the bundle identifier & App Group

The placeholder is `com.example.timecontrol`. Replace `com.example` with your own
domain in **three places** (all must stay consistent):

1. **`project.yml`** — the `PRODUCT_BUNDLE_IDENTIFIER` of all four targets, and
   `DEVELOPMENT_TEAM`. Re-run `xcodegen generate` after editing.
2. **`Shared/SharedConstants.swift`** — `AppGroup.identifier`
   (`group.com.example.timecontrol`).
3. **The three `.entitlements` files** — `Sources/App/TimeControl.entitlements`,
   `Sources/Monitor/Monitor.entitlements`, `Sources/Shield/Shield.entitlements` —
   update the `application-groups` string.

The extension bundle IDs must remain **prefixed by the app's** bundle ID
(e.g. app `com.you.timecontrol`, monitor `com.you.timecontrol.monitor`).

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
