import XCTest

@MainActor
class ComposableNavigation_ExamplesUITests: XCTestCase {
	var app: XCUIApplication!
	
	@MainActor
    override func setUpWithError() throws {
		try super.setUpWithError()
        continueAfterFailure = false
		app = XCUIApplication()
    }

	@MainActor
	override func tearDownWithError() throws {
		try super.tearDownWithError()
		app = nil
	}
	
	private func setupTestCase(_ showcase: String) {
		app.launchArguments = ["-uiTest", showcase]
		app.launch()
	}
	
	// MARK: Modal
	
    func testSwipeDownModalSheet() throws {
		setupTestCase("swipeDownModalSheet")
		
		let rootLabel = app.staticTexts["modalStateRoot"]
		XCTAssertEqual(rootLabel.label, "nil")
		
		app.buttons["present"].tap()
		
		let sheetLabel = app.staticTexts["modalStateSheet"]
		XCTAssertTrue(sheetLabel.waitForExistence(timeout: 2))
		XCTAssertEqual(sheetLabel.label, "sheet")
		
		app.swipeDown(velocity: .fast)
		XCTAssertEqual(rootLabel.label, "nil", "State should be nil after dismiss")
    }
	
	// MARK: Stack
	
	func testSwipeBackOnStackNavigation() throws {
		setupTestCase("swipeBackOnStackNavigation")
		
		let rootLabel = app.staticTexts["stackStateRoot"]
		XCTAssertEqual(rootLabel.label, "root")
		
		app.buttons["push"].tap()
		
		let pushedLabel = app.staticTexts["stackStatePushed"]
		XCTAssertTrue(pushedLabel.waitForExistence(timeout: 2))
		XCTAssertEqual(pushedLabel.label, "pushed")
		
		swipeBack()
		XCTAssertEqual(rootLabel.label, "root", "State should be root after dismiss")
	}
	
	private func swipeBack() {
		let coord1 = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.30))
		let coord2 = coord1.withOffset(CGVector(dx: 40, dy: 0))
		coord1.press(forDuration: 0.5, thenDragTo: coord2)
	}
	
	func testBackButtonOnStackNavigation() throws {
		setupTestCase("swipeBackOnStackNavigation")
		
		let rootLabel = app.staticTexts["stackStateRoot"]
		XCTAssertEqual(rootLabel.label, "root")
		
		app.buttons["push"].tap()
		
		let pushedLabel = app.staticTexts["stackStatePushed"]
		XCTAssertTrue(pushedLabel.waitForExistence(timeout: 2))
		XCTAssertEqual(pushedLabel.label, "pushed")
		
		app.buttons["Back"].tap()
		XCTAssertEqual(rootLabel.label, "root", "State should be root after dismiss")
	}
	
	// MARK: Tabs
	
	func testChangingTabs() throws {
		setupTestCase("changingTabs")
		
		let firstLabel = app.staticTexts["tabsState"]
		XCTAssertEqual(firstLabel.label, "one")
		
		app.buttons["two"].tap()
		
		let secondLabel = app.staticTexts["tabsState"]
		XCTAssertEqual(firstLabel.label, "two")
		XCTAssertEqual(secondLabel.label, "two")
	}
	
	// MARK: Nested deep link
	
	func testNestedDeepLink() async throws {
		setupTestCase("nestedDeepLink")
		
		let modalLevels = app.staticTexts.matching(identifier: "modalLevel")
		XCTAssertEqual(modalLevels.element(boundBy: 0).label, "1")
		XCTAssertEqual(modalLevels.element(boundBy: 1).label, "2")
		XCTAssertEqual(modalLevels.element(boundBy: 2).label, "3")
		XCTAssertEqual(modalLevels.element(boundBy: 3).label, "4")
		XCTAssertEqual(modalLevels.element(boundBy: 4).label, "5")
		
		let stackLevels = app.staticTexts.matching(identifier: "stackLevel")
		XCTAssertEqual(stackLevels.element(boundBy: 0).label, "2")
		XCTAssertEqual(stackLevels.element(boundBy: 1).label, "2")
		XCTAssertEqual(stackLevels.element(boundBy: 2).label, "2")
		XCTAssertEqual(stackLevels.element(boundBy: 3).label, "2")
		XCTAssertEqual(stackLevels.element(boundBy: 4).label, "2")
	}
}
