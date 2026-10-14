import XCTest
@testable import InstaLite

/// `rules.js` ile aynı vakalar (`Tests/rules-cases.json`); iki taraf ayrışırsa burada yakalanır.
final class BlockRulesTests: XCTestCase {
    private struct Cases: Decodable {
        struct Redirect: Decodable {
            let from: String?
            let to: String
            let expected: String?
        }

        struct External: Decodable {
            let url: String
            let expected: String?
        }

        let redirect: [Redirect]
        let external: [External]
    }

    private func loadCases() throws -> Cases {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "rules-cases", withExtension: "json"))
        return try JSONDecoder().decode(Cases.self, from: Data(contentsOf: url))
    }

    func testRedirects() throws {
        for item in try loadCases().redirect {
            XCTAssertEqual(BlockRules.redirect(from: item.from, to: item.to), item.expected, "\(item.from ?? "nil") → \(item.to)")
        }
    }

    func testExternalLinks() throws {
        for item in try loadCases().external {
            let url = try XCTUnwrap(URL(string: item.url))
            XCTAssertEqual(BlockRules.externalURL(for: url)?.absoluteString, item.expected, item.url)
        }
    }
}
