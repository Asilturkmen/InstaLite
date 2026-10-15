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

    func testInstagramImages() throws {
        let allowed = [
            "https://scontent-ist1-1.cdninstagram.com/v/t51/123.jpg?x=1",
            "https://instagram.fist1-1.fna.fbcdn.net/v/t51/123.jpg",
        ]
        let rejected = [
            "http://scontent.cdninstagram.com/a.jpg",
            "https://example.com/a.jpg",
            "https://cdninstagram.com.evil.example/a.jpg",
            "https://evilfbcdn.net/a.jpg",
        ]
        for string in allowed {
            XCTAssertTrue(BlockRules.isInstagramImage(try XCTUnwrap(URL(string: string))), string)
        }
        for string in rejected {
            XCTAssertFalse(BlockRules.isInstagramImage(try XCTUnwrap(URL(string: string))), string)
        }
    }

    func testExternalLinks() throws {
        for item in try loadCases().external {
            let url = try XCTUnwrap(URL(string: item.url))
            XCTAssertEqual(BlockRules.externalURL(for: url)?.absoluteString, item.expected, item.url)
        }
    }
}
