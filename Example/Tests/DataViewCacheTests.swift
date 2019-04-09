//
//  DataViewCacheTests.swift
//  DataFramework_Tests
//
//  Created by Alex on 4/9/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import DataFramework
import ReactiveSwift

class DataViewCacheTests: XCTestCase {

    private final class ItemModel: Uniq, Equatable, CustomDebugStringConvertible {
        static func == (lhs: DataViewCacheTests.ItemModel, rhs: DataViewCacheTests.ItemModel) -> Bool {
            return lhs.id == rhs.id
        }

        let id: Int
        var identifier: String {
            return "\(id)"
        }
        init(_ id: Int) {
            self.id = id
        }
        var debugDescription: String {
            return "id = \(id)"
        }
    }

    private final class ItemViewModel {
        static var counter: Int = 0
        let model: ItemModel
        init(_ model: ItemModel) {
            self.model = model
            ItemViewModel.counter += 1
        }
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        XCTAssert(true)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

//    func testInsert() {
//        let property: MutableProperty<[ItemModel]> = MutableProperty([])
//        let item1 = ItemModel(1)
//        let item2 = ItemModel(3)
//        let item3 = ItemModel(5)
//        property.value = [item1, item2, item3]
//
//        let result = DataResult.create(data: property.producer)
//        let cachedView = DataView.create(data: result).map { ItemViewModel($0) }.cached
//
//        var item = cachedView[1]
//        XCTAssert(item.model.id == 3)
//        XCTAssert(ItemViewModel.counter == 1)
//
//        item = cachedView[1]
//        XCTAssert(item.model.id == 3)
//        XCTAssert(ItemViewModel.counter == 1)
//
//        let item4 = ItemModel(2)
//        property.value = [item1, item4, item2, item3]
//
//        item = cachedView[1]
//        XCTAssert(item.model.id == 2)
//        XCTAssert(ItemViewModel.counter == 2)
//
//        item = cachedView[2]
//        XCTAssert(item.model.id == 3)
//        XCTAssert(ItemViewModel.counter == 2)
//    }

    func testMove() {
        let property: MutableProperty<[ItemModel]> = MutableProperty([])
        let item1 = ItemModel(1)
        let item2 = ItemModel(3)
        let item3 = ItemModel(5)
        let item4 = ItemModel(7)
        property.value = [item1, item2, item3, item4]

        let result = DataResult.create(data: property.producer)
        let cachedView = DataView.create(data: result).map { ItemViewModel($0) }.cached

        var item = cachedView[1]
        XCTAssert(item.model.id == 3)
        print(ItemViewModel.counter)
        XCTAssert(ItemViewModel.counter == 1)

        item = cachedView[2]
        XCTAssert(item.model.id == 5)
        print(ItemViewModel.counter)
        XCTAssert(ItemViewModel.counter == 2)

        property.value = [item1, item4, item3, item2]

        item = cachedView[1]
        XCTAssert(item.model.id == 5)
        XCTAssert(ItemViewModel.counter == 2)

        item = cachedView[2]
        XCTAssert(item.model.id == 3)
        XCTAssert(ItemViewModel.counter == 2)
    }

}
