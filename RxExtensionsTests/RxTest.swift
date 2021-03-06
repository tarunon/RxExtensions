//
//  RxTest.swift
//  RxTests
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
import Foundation

import UIKit

let testError = NSError(domain: "dummyError", code: -232, userInfo: nil)
let testError1 = NSError(domain: "dummyError1", code: -233, userInfo: nil)
let testError2 = NSError(domain: "dummyError2", code: -234, userInfo: nil)

class RxTest
    : XCTestCase {

    #if os(Linux)
        var allTests : [(String, () throws -> Void)] = []
    #endif

    private var startResourceCount: Int32 = 0

    var accumulateStatistics: Bool {
        return true
    }

    #if TRACE_RESOURCES
        static var totalNumberOfAllocations: Int64 = 0
        static var totalNumberOfAllocatedBytes: Int64 = 0

        var startNumberOfAllocations: Int64 = 0
        var startNumberOfAllocatedBytes: Int64 = 0
    #endif

    #if os(Linux)
        func setUp() {
            setUpActions()
        }

        func tearDown() {
            tearDownActions()
        }
    #else
        override func setUp() {
            super.setUp()
            setUpActions()
        }

        override func tearDown() {
            // Put teardown code here. This method is called after the invocation of each test method in the class.
            super.tearDown()
            tearDownActions()
        }
    #endif
}

extension RxTest {
    struct Defaults {
        static let created = 100
        static let subscribed = 200
        static let disposed = 1000
    }

    func sleep(time: TimeInterval) {
        RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: time))
    }

    func setUpActions(){
        #if TRACE_RESOURCES
            self.startResourceCount = resourceCount
            registerMallocHooks()
            (startNumberOfAllocatedBytes, startNumberOfAllocations) = getMemoryInfo()
        #endif
    }

    func tearDownActions() {
        #if TRACE_RESOURCES
            // give 5 sec to clean up resources
            for _ in 0..<30 {
                if self.startResourceCount < resourceCount {
                    // main schedulers need to finish work
                    print("Waiting for resource cleanup ...")
                    NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05))
                }
                else {
                    break
                }
            }

            XCTAssertEqual(self.startResourceCount, resourceCount)
            let (endNumberOfAllocatedBytes, endNumberOfAllocations) = getMemoryInfo()

            let (newBytes, newAllocations) = (endNumberOfAllocatedBytes - startNumberOfAllocatedBytes, endNumberOfAllocations - startNumberOfAllocations)

            if accumulateStatistics {
                RxTest.totalNumberOfAllocations += newAllocations
                RxTest.totalNumberOfAllocatedBytes += newBytes
            }
            print("allocatedBytes = \(newBytes), allocations = \(newAllocations) (totalBytes = \(RxTest.totalNumberOfAllocatedBytes), totalAllocations = \(RxTest.totalNumberOfAllocations))")
        #endif
    }

}
