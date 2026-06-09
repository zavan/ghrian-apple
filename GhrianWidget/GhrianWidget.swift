import WidgetKit
import SwiftUI
import GhrianKit

struct DailyEntry: TimelineEntry {
    let date: Date
    let title: String
    let today: TodayEnergy?
    let soc: Double?
    let failed: Bool

    static let placeholder = DailyEntry(
        date: .now, title: "Garage",
        today: TodayEnergy(generation: 12.3, charge: 4.0, discharge: 2.0, toGrid: 8.0, fromGrid: 0.5, consumption: 6.0),
        soc: 72, failed: false
    )
}

/// Fetches today's energy (slowly-changing — fits the widget refresh budget) for
/// the configured inverter, or the site-wide aggregate for "All".
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DailyEntry { .placeholder }

    func snapshot(for configuration: SelectInverterIntent, in context: Context) async -> DailyEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: SelectInverterIntent, in context: Context) async -> Timeline<DailyEntry> {
        let entry = await entry(for: configuration)
        let next = Date().addingTimeInterval(20 * 60) // ~20 min; OS budget permitting
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for configuration: SelectInverterIntent) async -> DailyEntry {
        let store = AppConfig.makeStore()
        let selection: InverterSelection = {
            if let id = configuration.inverter?.id, id >= 0 { return .inverter(id) }
            return .all
        }()

        guard let client = store.makeClient() else {
            return DailyEntry(date: .now, title: "Not connected", today: nil, soc: nil, failed: true)
        }

        do {
            let entry: DailyEntry
            if case .inverter(let id) = selection {
                let inverter = try await client.inverter(id: id)
                entry = DailyEntry(date: .now, title: inverter.name,
                                   today: inverter.snapshot.today, soc: inverter.snapshot.batterySoc, failed: false)
            } else {
                let combined = CombinedSnapshot(inverters: try await client.inverters())
                entry = DailyEntry(date: .now, title: "All Inverters",
                                   today: combined.today, soc: combined.batterySoc, failed: false)
            }
            store.cacheWidgetSnapshot(
                WidgetSnapshot(title: entry.title, today: entry.today, soc: entry.soc, date: entry.date),
                for: selection
            )
            return entry
        } catch {
            // Render last-known values rather than a blank widget.
            if let cached = store.cachedWidgetSnapshot(for: selection) {
                return DailyEntry(date: cached.date, title: cached.title, today: cached.today, soc: cached.soc, failed: false)
            }
            return DailyEntry(date: .now, title: "Unavailable", today: nil, soc: nil, failed: true)
        }
    }
}

struct GhrianWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DailyEntry

    var body: some View {
        #if os(iOS)
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: home
        }
        #else
        home
        #endif
    }

    // MARK: Home-screen (systemSmall / systemMedium)

    private var home: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "sun.max.fill").foregroundStyle(GhrianColor.inverter)
                Text(entry.title).font(.caption.weight(.semibold)).foregroundStyle(GhrianColor.textPrimary).lineLimit(1)
                Spacer()
                if let soc = entry.soc {
                    Text(GhrianFormat.percent(soc)).font(.caption2.weight(.medium)).foregroundStyle(GhrianColor.battery)
                }
            }

            if let today = entry.today {
                tile("Yield", GhrianFormat.kwh(today.generation), GhrianColor.pv)
                if family != .systemSmall {
                    tile("Consumption", GhrianFormat.kwh(today.consumption), GhrianColor.load)
                    HStack(alignment: .top, spacing: 12) {
                        tile("To Grid", GhrianFormat.kwh(today.toGrid), GhrianColor.grid)
                        tile("From Grid", GhrianFormat.kwh(today.fromGrid), GhrianColor.importColor)
                    }
                }
            } else {
                Text(entry.failed ? "Open the app to connect." : "No data yet.")
                    .font(.caption).foregroundStyle(GhrianColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func tile(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.callout.weight(.semibold)).foregroundStyle(color).monospacedDigit()
            Text(label.uppercased()).font(.system(size: 9)).tracking(0.4).foregroundStyle(GhrianColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Lock-screen accessories (iOS only — monochrome, the system tints these)

    #if os(iOS)
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(entry.title, systemImage: "sun.max.fill")
                .font(.caption.weight(.semibold)).lineLimit(1)
            if let today = entry.today {
                Text("Yield \(GhrianFormat.kwh(today.generation))").font(.caption2)
                HStack(spacing: 6) {
                    Text("Use \(GhrianFormat.kwh(today.consumption))")
                    if let soc = entry.soc { Text("· \(GhrianFormat.percent(soc))") }
                }
                .font(.caption2)
            } else {
                Text(entry.failed ? "Not connected" : "No data").font(.caption2)
            }
        }
        .widgetAccentable()
    }

    private var circular: some View {
        Gauge(value: (entry.soc ?? 0) / 100) {
            Image(systemName: "battery.100percent")
        } currentValueLabel: {
            Text(entry.soc.map { "\(Int($0.rounded()))" } ?? "—")
        }
        .gaugeStyle(.accessoryCircular)
    }
    #endif
}

struct GhrianDailyWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "GhrianDailyWidget", intent: SelectInverterIntent.self, provider: Provider()) { entry in
            GhrianWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Energy")
        .description("Daily generation, consumption, and battery for an inverter.")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
        #else
        .supportedFamilies([.systemSmall, .systemMedium])
        #endif
    }
}
