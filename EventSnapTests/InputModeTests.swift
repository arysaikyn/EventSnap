import XCTest
@testable import EventSnap

// MARK: - InputModeTests

final class InputModeTests: XCTestCase {

    // MARK: - CaseIterable Tests

    func testAllCases_Count() {
        XCTAssertEqual(InputMode.allCases.count, 3)
    }

    func testAllCases_ContainsAllModes() {
        let cases = InputMode.allCases
        XCTAssertTrue(cases.contains(.camera))
        XCTAssertTrue(cases.contains(.voice))
        XCTAssertTrue(cases.contains(.text))
    }

    // MARK: - Identifiable Tests

    func testId_ReturnsRawValue() {
        XCTAssertEqual(InputMode.camera.id, "camera")
        XCTAssertEqual(InputMode.voice.id, "voice")
        XCTAssertEqual(InputMode.text.id, "text")
    }

    // MARK: - Icon Names Tests

    func testIconNames_NotEmpty() {
        for mode in InputMode.allCases {
            XCTAssertFalse(mode.iconName.isEmpty, "\(mode) should have an iconName")
        }
    }

    func testIconNames_SpecificValues() {
        XCTAssertEqual(InputMode.camera.iconName, "camera.viewfinder")
        XCTAssertEqual(InputMode.voice.iconName, "waveform")
        XCTAssertEqual(InputMode.text.iconName, "text.alignleft")
    }

    // MARK: - Title Tests

    func testTitles_NotEmpty() {
        for mode in InputMode.allCases {
            XCTAssertFalse(mode.title.isEmpty, "\(mode) should have a title")
        }
    }

    func testTitles_SpecificValues() {
        XCTAssertEqual(InputMode.camera.title, "Camera")
        XCTAssertEqual(InputMode.voice.title, "Voice")
        XCTAssertEqual(InputMode.text.title, "Text")
    }

    // MARK: - InputType Mapping Tests

    func testAsInputType_MapsCorrectly() {
        XCTAssertEqual(InputMode.camera.asInputType, .camera)
        XCTAssertEqual(InputMode.voice.asInputType, .voice)
        XCTAssertEqual(InputMode.text.asInputType, .text)
    }

    // MARK: - RawValue Tests

    func testRawValues() {
        XCTAssertEqual(InputMode.camera.rawValue, "camera")
        XCTAssertEqual(InputMode.voice.rawValue, "voice")
        XCTAssertEqual(InputMode.text.rawValue, "text")
    }
}