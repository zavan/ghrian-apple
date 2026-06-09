import XCTest
@testable import GhrianKit

final class ClientTests: XCTestCase {
    private func client() -> GhrianClient {
        GhrianClient(baseURL: URL(string: "http://localhost:3000")!, token: "tok_test", session: StubURLProtocol.session())
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testListsInvertersAndSendsBearerToken() async throws {
        let index = try Fixture.data("inverters_index")
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tok_test")
            XCTAssertEqual(request.url?.path, "/api/v1/inverters")
            return (200, index)
        }

        let inverters = try await client().inverters()
        XCTAssertEqual(inverters.map(\.id), [1, 2])
    }

    func testIntradayBuildsDateQuery() async throws {
        let body = try Fixture.data("intraday")
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/inverters/1/intraday")
            XCTAssertTrue(request.url?.query?.contains("date=") ?? false)
            return (200, body)
        }

        let series = try await client().intraday(inverterID: 1, date: Date(timeIntervalSince1970: 1_749_000_000))
        XCTAssertEqual(series.inverterId, 1)
    }

    func testSiteWideEnergyHitsUnscopedPath() async throws {
        let body = try Fixture.data("energy_day")
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/energy")
            return (200, body)
        }

        let report = try await client().energy(inverterID: nil, period: .day)
        XCTAssertEqual(report.totals.generation, 12.0)
    }

    func testMapsUnauthorized() async throws {
        StubURLProtocol.handler = { _ in (401, Data(#"{"error":"invalid or missing API token"}"#.utf8)) }

        do {
            _ = try await client().inverters()
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testMapsNotFound() async throws {
        StubURLProtocol.handler = { _ in (404, Data(#"{"error":"not found"}"#.utf8)) }

        do {
            _ = try await client().inverter(id: 999)
            XCTFail("Expected notFound error")
        } catch let error as APIError {
            XCTAssertEqual(error, .notFound)
        }
    }
}
