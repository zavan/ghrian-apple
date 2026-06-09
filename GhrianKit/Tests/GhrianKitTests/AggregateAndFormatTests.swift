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
