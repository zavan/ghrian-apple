import XCTest
@testable import GhrianKit

final class DecodingTests: XCTestCase {
    private let decoder = GhrianClient.makeDecoder()

    func testDecodesInverterShowWithSnapshot() throws {
        let inverter = try decoder.decode(InverterResponse.self, from: Fixture.data("inverter_show")).inverter

        XCTAssertEqual(inverter.id, 1)
        XCTAssertEqual(inverter.name, "Garage")
        XCTAssertEqual(inverter.status, .online)
        XCTAssertNotNil(inverter.lastReadingAt)

        // Computed snapshot.
        XCTAssertEqual(inverter.snapshot.flows.pv.watts, 3500.0)
        XCTAssertEqual(inverter.snapshot.flows.pv.direction, .incoming)
        XCTAssertEqual(inverter.snapshot.flows.grid.direction, .incoming) // meter -800 = importing
        XCTAssertEqual(inverter.snapshot.flows.battery.direction, .outgoing) // charging
        XCTAssertTrue(inverter.snapshot.flows.pv.isActive)
        XCTAssertEqual(inverter.snapshot.batterySoc, 80)
        XCTAssertEqual(inverter.snapshot.today.generation, 12.34)
        XCTAssertEqual(inverter.snapshot.today.toGrid, 8.0)
    }

    func testPreservesRawLatestValueKeys() throws {
        // Snake_case metric keys must survive decoding (no key-conversion mangling).
        let inverter = try decoder.decode(InverterResponse.self, from: Fixture.data("inverter_show")).inverter

        XCTAssertEqual(inverter.latestValues["total_dc_output_power"]?.doubleValue, 3500.0)
        XCTAssertEqual(inverter.latestValues["battery_soc"]?.unit, "%")
        if case .list(let phases)? = inverter.latestValues["device_active"]?.value {
            XCTAssertEqual(phases, ["phase_a", "phase_c"])
        } else {
            XCTFail("Expected a string-list metric value")
        }
    }

    func testDecodesEmptySnapshotForOfflineInverter() throws {
        let inverters = try decoder.decode(InvertersResponse.self, from: Fixture.data("inverters_index")).inverters
        let shed = try XCTUnwrap(inverters.first { $0.id == 2 })

        XCTAssertEqual(shed.status, .offline)
        XCTAssertNil(shed.snapshot.flows.pv.watts)
        XCTAssertFalse(shed.snapshot.flows.pv.isActive)
        XCTAssertEqual(shed.snapshot.flows.grid.direction, .idle)
        XCTAssertNil(shed.snapshot.batterySoc)
        XCTAssertNil(shed.snapshot.today.generation)
    }

    func testDecodesIntradaySeries() throws {
        let series = try decoder.decode(IntradaySeries.self, from: Fixture.data("intraday"))

        XCTAssertEqual(series.inverterId, 1)
        XCTAssertEqual(series.power.map(\.name), ["PV", "Grid", "Load", "Battery"])
        XCTAssertEqual(series.power[0].data.count, 2)
        XCTAssertEqual(series.power[0].data[1].value, 1.25)
        XCTAssertTrue(series.power[2].data.isEmpty) // Load: no points
        XCTAssertEqual(series.socSeries?.data.map(\.value), [78, 80])
        // The first point's timestamp parsed from ISO8601.
        XCTAssertNotNil(series.power[0].data.first?.time)
    }

    func testDecodesEnergyReport() throws {
        let report = try decoder.decode(EnergyReport.self, from: Fixture.data("energy_day"))

        XCTAssertEqual(report.period, .day)
        XCTAssertEqual(report.totals.generation, 12.0)
        XCTAssertEqual(report.totals.selfConsumption, 4.0)
        XCTAssertEqual(report.totals.import, 0.5)
        XCTAssertEqual(report.costs.net, 0.65)
        XCTAssertEqual(report.currency, "$")
        XCTAssertNil(report.breakdown)
    }
}
