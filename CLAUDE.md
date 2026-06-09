# AGENTS.md — ghrian-apple

**Project**: The Apple-client module of ghrian — a SwiftUI app for **macOS / iOS /
iPadOS** that consumes the [`ghrian-server`](https://github.com/zavan/ghrian-server)
token-authenticated REST API and presents live power flow, daily energy, and intraday
charts. Ships a **widget** (daily energy) and a macOS **menu-bar extra** (live).

**Where it sits**: A downstream consumer like `homekit`, but one step further out — it
talks to the **server's HTTP API**, not MQTT.

```
inverter ──Modbus──▶ [agent] ──MQTT──▶ [server] ──HTTP /api/v1──▶ [apple]  (this repo)
```

## Important invariants (don't break these)

- **Read-only client.** Only the API's GET endpoints are consumed; the app never
  mutates server state. Mirror the stack's read-only ethos.
- **Don't reimplement server presentation.** The server exposes a computed
  `snapshot` block per inverter (power-flow direction, sign conventions, today's
  energy). Consume it — do not re-derive meter-vs-port / battery-direction logic in
  Swift. Likewise use `/intraday` and `/energy` rather than paging raw `/readings`.
- **GhrianKit is the pure, tested core.** All models, the API client, the store, and
  formatting live in the `GhrianKit/` Swift package with **no UI**. App / widget /
  menu-bar targets stay thin on top. `swift test` must stay green; add tests with
  changes (decode against fixtures that mirror real API JSON).
- **Explicit `CodingKeys`, never `convertFromSnakeCase`.** The raw `latest_values`
  map uses arbitrary snake_case metric keys as *dictionary keys* — key conversion
  would mangle them. Every model spells out its keys.
- **Liquid Glass, min OS 26.** The UI is built on Apple's Liquid Glass design system and
  deploys to **iOS/iPadOS 26 + macOS 26** (so glass APIs need no `if #available`). Keep the
  two-layer model: charts/readouts/lists live on the flat, system-**adaptive** content layer
  (`GhrianColor` structural tokens map to platform system colors — light & dark, never forced);
  only navigation and controls float in glass. Don't stack glass on glass — let standard
  components (`TabView`, toolbars, `NavigationSplitView` sidebar, `Form`, `.buttonStyle(.glass)`)
  adopt it automatically; reach for `.glassEffect`/`GlassEffectContainer` only for custom
  floating clusters (e.g. the power-flow discs, the status badge).
- **Widget shows daily data, not live.** WidgetKit's ~15–30 min refresh budget can't
  track the 30s poll, so the widget surfaces today's slowly-changing energy + SOC.
  Live power flow lives in the app + menu-bar, which **poll** (there is no client
  websocket — ActionCable is session-auth'd). Don't try to make the widget live.
- **Switchable selection.** Surfaces target a single inverter or the site-wide `.all`
  aggregate (`CombinedSnapshot` sums flows). The widget picks per-instance via an
  AppIntent; app/menu-bar via a picker. Persisted in the App Group.
- **The Xcode project is generated.** `Ghrian.xcodeproj` is produced by **XcodeGen**
  from `project.yml` and is **gitignored** — edit `project.yml` and run
  `xcodegen generate`; never hand-edit the project.
- **Identifiers + signing.** Bundle/App-Group/Keychain ids (`me.zavan.*`) live in
  `Shared/AppConfig.swift` + the `*.entitlements`. The checked-in entitlements are
  **local-dev (non-sandboxed)** so the app runs with an ad-hoc signature and no
  Apple Developer team. Distribution (App Store / device) re-enables App Sandbox +
  the App Group + keychain sharing and needs a team — see `Ghrian.entitlements`.

## Layout / where things live

- **`GhrianKit/Sources/GhrianKit/`** — shared package:
  - `Models/` — `Inverter`, `InverterSnapshot`/`Flow`, `TodayEnergy`, `IntradaySeries`,
    `EnergyReport`, `MetricValue` (Codable to the `/api/v1` shapes).
  - `API/` — `GhrianClient` (async `URLSession`, Bearer), `APIError`, ISO8601 date parsing.
  - `Store/` — `GhrianStore` (server URL + selection in App-Group `UserDefaults`; token
    in `Keychain`), `InverterSelection`, inverter-list + widget-snapshot caches.
  - `Design/` — `GhrianColor` (web Tailwind palette) + `GhrianFormat` (kW/kWh/%/money).
  - `Aggregate/` — `CombinedSnapshot` (the `.all` site-wide flow sum).
- **`Ghrian/`** — the app target (one multiplatform target). `GhrianApp` (WindowGroup +
  macOS `MenuBarExtra` + macOS `Settings` scene), `AppModel` (`@Observable`, polling), `Views/`
  — `RootView` (lifecycle) → `AppShell` (compact `TabView` / regular `NavigationSplitView` +
  `InverterPicker`), `OverviewScreen` (live hero), `EnergyScreen`, `SettingsScreen` (`Form`),
  `PowerFlowDiagram`, `BatteryRing`, `TodayEnergyGrid`, `IntradayChartsView`, `Theme` (adaptive
  `Card`, `StatusBadge`, `PulsingDot`) — plus `MenuBar/`, `Assets.xcassets` (app icon).
- **`GhrianWidget/`** — WidgetKit extension: `Provider` (AppIntent timeline), the daily
  view, and `SelectInverterIntent` (config picker backed by the App-Group inverter cache).
- **`Shared/`** — `AppConfig` (ids), compiled into both app + widget.

## Essential commands

```bash
swift test --package-path GhrianKit      # shared-package unit tests
xcodegen generate                        # regenerate Ghrian.xcodeproj from project.yml
open Ghrian.xcodeproj                     # build/run the Ghrian scheme (⌘R, "My Mac")

# CLI build / local run (ad-hoc signed, no team):
xcodebuild -scheme Ghrian -destination 'platform=macOS' \
  -derivedDataPath .build-xcode CODE_SIGN_IDENTITY="-" build
open .build-xcode/Build/Products/Debug/Ghrian.app
```

The app authenticates with a Bearer **API token** created in the server's web admin
(API Tokens page); enter the server URL + token in the app's settings.

## When an AI agent works on this code

1. Run `swift test --package-path GhrianKit` and a macOS `xcodebuild` after edits.
2. Keep the Codable models in lockstep with the server's Jbuilder views — if the API
   shape changes (`server/app/views/api/v1/*`), follow it here and update fixtures.
3. Put logic in `GhrianKit` (testable, no UI); keep views thin.
4. Never add server-mutating calls. Read-only.
5. After changing targets/build settings, edit `project.yml` + `xcodegen generate`.

Keep this file up to date when you make significant changes.
