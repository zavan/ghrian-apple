# ghrian-apple

The Apple-client module of the [ghrian](https://github.com/zavan/ghrian) project: a
SwiftUI app for **macOS / iOS / iPadOS** that consumes the
[`ghrian-server`](https://github.com/zavan/ghrian-server) token-authenticated REST API
to show live solar power flow, daily energy, and intraday charts. Includes a **widget**
(daily energy at a glance) and a macOS **menu-bar extra** (live flow + today + charts).

## Layout

- **`GhrianKit/`** — a Swift package shared by all targets: API client + Codable
  models (decode the `/api/v1` responses), the Keychain + App-Group store, the
  site-wide flow aggregate, and design tokens/formatters mirroring the web. Pure and
  unit-tested (`swift test`).
- **`Ghrian/`** — the app target (one multiplatform target: macOS + iOS + iPadOS), built on
  Apple's **Liquid Glass** design system (min **iOS/iPadOS 26 + macOS 26**). An `AppShell`
  adapts the navigation — a glass `TabView` on iPhone, a `NavigationSplitView` sidebar on
  iPad/Mac — over an Overview screen (live `PowerFlowDiagram` hero, battery ring, today grid),
  an Energy screen (Swift Charts intraday + period totals/costs), a `Form`-based Settings
  screen, and the macOS `MenuBarExtra`. The content layer follows the system light/dark
  appearance; only controls float in glass.
- **`GhrianWidget/`** — WidgetKit extension showing **today's energy** (slowly-changing,
  so it fits the widget refresh budget — live flow stays in the app/menu-bar). Home-screen
  (`systemSmall`/`systemMedium`) + lock-screen (`accessoryRectangular`/`accessoryCircular`)
  families, AppIntent-configurable per-widget inverter (incl. "All").
- **`Shared/`** — `AppConfig` (bundle/App-Group identifiers) shared by app + widget.

## Build

Requires Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
xcodegen generate          # regenerate Ghrian.xcodeproj from project.yml
open Ghrian.xcodeproj       # then build/run the Ghrian scheme
swift test --package-path GhrianKit   # run the shared-package tests
```

The `.xcodeproj` is generated — edit `project.yml`, not the project, and re-run
`xcodegen generate`.

## Setup (in the app)

1. In the ghrian web admin, create an **API token** (API Tokens page).
2. Launch the app → enter the **server URL** (e.g. `http://192.168.1.10:3000`) and
   paste the token. Stored in the Keychain; the server URL + selection are shared
   with the widget/menu-bar via the App Group.

## Notes / TODO

- **Signing:** set a development team + the App Group (`group.me.zavan.ghrian`) and
  the shared keychain group in the targets' Signing & Capabilities before running on
  device. CLI builds use `CODE_SIGNING_ALLOWED=NO`.
- **ATS:** allows plain-`http` on the local network (`NSAllowsLocalNetworking`). A
  non-local `http` host would need a broader exception.
- The widget caches the inverter *list* for its config picker; caching the last
  *snapshot* for richer offline display is a future polish.

## License

MIT — see [LICENSE](LICENSE).
