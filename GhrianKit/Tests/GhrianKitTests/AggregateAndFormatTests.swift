import XCTest
@testable import GhrianKit

final class AggregateAndFormatTests: XCTestCase {
    private func inverters() throws -> [Inverter] {
        try GhrianClient.makeDecoder()
            .decode(InvertersResponse.self, from: Fixture.data("inverters_index")).inverters
    }

    func testCombinedSnapshotSumsFlowsAcrossInverters() throws {
        // Garage has live values; Shed is empty — combined should equal Garage's.
        let combined = CombinedSnapshot(inverters: try inverters())

        XCTAssertEqual(combined.pv.watts, 3500.0)
        XCTAssertEqual(combined.pv.direction, .incoming)
        XCTAssertEqual(combined.load.watts, 1200.0)
        XCTAssertEqual(combined.load.direction, .outgoing)
        // Grid signed -800 (importing) -> magnitude shown, direction incoming.
        XCTAssertEqual(combined.grid.watts, 800.0)
        XCTAssertEqual(combined.grid.direction, .incoming)
        // Battery charging (out) magnitude 1500.
        XCTAssertEqual(combined.battery.watts, 1500.0)
        XCTAssertEqual(combined.battery.direction, .outgoing)
        XCTAssertEqual(combined.batterySoc, 80) // only Garage reports SOC
        XCTAssertEqual(combined.today.generation, 12.34)
    }

    func testCombinedBatteryDirectionFromSignedSum() {
        // Two synthetic inverters: one charging 1000W (out), one discharging 1500W (in)
        // -> net -500 -> discharging (incoming), magnitude 500.
        let charging = makeInverter(batteryWatts: 1000, direction: .outgoing)
        let discharging = makeInverter(batteryWatts: 1500, direction: .incoming)

        let combined = CombinedSnapshot(inverters: [charging, discharging])
        XCTAssertEqual(combined.battery.watts, 500.0)
        XCTAssertEqual(combined.battery.direction, .incoming)
    }

    func testFormatters() {
        XCTAssertEqual(GhrianFormat.kw(watts: 3500), "3.5 kW")
        XCTAssertEqual(GhrianFormat.kw(watts: 0), "0 kW")
        XCTAssertEqual(GhrianFormat.kw(watts: nil), "—")
        XCTAssertEqual(GhrianFormat.kwh(12.3), "12.30 kWh")
        XCTAssertEqual(GhrianFormat.percent(79.6), "80%")
        XCTAssertEqual(GhrianFormat.money(0.65, currency: "$"), "$0.65")
        XCTAssertEqual(GhrianFormat.money(-1.2, currency: "$"), "-$1.20")
    }

    func testRelativeUpdated() {
        let now = Date(timeIntervalSinceReferenceDate: 100_000)
        XCTAssertEqual(GhrianFormat.relativeUpdated(nil, now: now), "Never updated")
        XCTAssertEqual(GhrianFormat.relativeUpdated(now.addingTimeInterval(-2), now: now), "Updated just now")
        XCTAssertEqual(GhrianFormat.relativeUpdated(now.addingTimeInterval(-12), now: now), "Updated 12s ago")
        XCTAssertEqual(GhrianFormat.relativeUpdated(now.addingTimeInterval(-300), now: now), "Updated 5m ago")
        XCTAssertEqual(GhrianFormat.relativeUpdated(now.addingTimeInterval(-7200), now: now), "Updated 2h ago")
        XCTAssertEqual(GhrianFormat.relativeUpdated(now.addingTimeInterval(-259_200), now: now), "Updated 3d ago")
        // A future timestamp (clock skew) clamps to "just now" rather than going negative.
        XCTAssertEqual(GhrianFormat.relativeUpdated(now.addingTimeInterval(30), now: now), "Updated just now")
    }

    func testGridHeadline() {
        func grid(_ kw: Double?, _ dir: FlowDirection) -> Flow {
            Flow(key: "grid", label: "Grid", watts: kw.map { $0 * 1000 }, kw: kw, direction: dir)
        }
        XCTAssertEqual(GhrianFormat.gridHeadline(grid(1.2, .incoming)), GridHeadline(title: "Importing", value: "1.2 kW"))
        XCTAssertEqual(GhrianFormat.gridHeadline(grid(0.8, .outgoing)), GridHeadline(title: "Exporting", value: "0.8 kW"))
        XCTAssertEqual(GhrianFormat.gridHeadline(grid(0, .idle)), GridHeadline(title: "Grid idle", value: "0 kW"))
        XCTAssertEqual(GhrianFormat.gridHeadline(nil), GridHeadline(title: "Grid idle", value: "—"))
    }

    func testSelectionRoundTrips() {
        XCTAssertEqual(InverterSelection(storageValue: "all"), .all)
        XCTAssertEqual(InverterSelection(storageValue: "inv:7"), .inverter(7))
        XCTAssertEqual(InverterSelection.inverter(7).storageValue, "inv:7")
        XCTAssertNil(InverterSelection(storageValue: "garbage"))
        XCTAssertEqual(InverterSelection.all.inverterID, nil)
        XCTAssertEqual(InverterSelection.inverter(3).inverterID, 3)
    }

    // MARK: Helpers

    private func makeInverter(batteryWatts: Double, direction: FlowDirection) -> Inverter {
        let flow = { (key: String, dir: FlowDirection) in
            Flow(key: key, label: key, watts: nil, kw: nil, direction: dir)
        }
        let flows = Flows(
            pv: flow("pv", .incoming),
            grid: flow("grid", .idle),
            battery: Flow(key: "battery", label: "Battery", watts: batteryWatts, kw: batteryWatts / 1000, direction: direction),
            load: flow("load", .outgoing)
        )
        let snapshot = InverterSnapshot(
            flows: flows, batterySoc: nil, temperature: nil,
            today: TodayEnergy(generation: nil, charge: nil, discharge: nil, toGrid: nil, fromGrid: nil, consumption: nil)
        )
        return Inverter(
            id: Int.random(in: 1...9999), name: "Test", deviceModel: nil, mqttTopic: "t",
            serialNumber: nil, status: .online, lastReadingAt: nil, lastSeenAt: nil,
            latestValues: [:], snapshot: snapshot
        )
    }
}
