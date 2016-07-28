//
//  RxExtensionsTests.swift
//  RxExtensionsTests
//
//  Created by Nobuo Saito on 2016/07/28.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import XCTest
import RxSwift
import RxTests
import RxBlocking
import RxExtensions

class RxExtensionsTest : RxTest {
    override func setUp() {
        super.setUp()
    }
}

// MARK: Throttle2
extension RxExtensionsTest {
    func test_Throttle2TimeSpan_AllPass() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            completed(400)
            ])

        let res = scheduler.start {
            xs.throttle2(20, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(241, 2),
            next(271, 3),
            next(301, 4),
            completed(400)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2TimeSpan_AllPass_ErrorEnd() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            error(400, testError)
            ])

        let res = scheduler.start {
            xs.throttle2(20, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(241, 2),
            next(271, 3),
            next(301, 4),
            error(400, testError)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2TimeSpan_AllDrop() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            next(330, 5),
            next(360, 6),
            next(390, 7),
            completed(400)
            ])

        let res = scheduler.start {
            xs.throttle2(40, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            completed(400)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2TimeSpan_AllDrop_ErrorEnd() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            next(330, 5),
            next(360, 6),
            next(390, 7),
            error(400, testError)
            ])

        let res = scheduler.start {
            xs.throttle2(40, scheduler: scheduler)
        }

        let correct: [Recorded<Event<Int>>] = [
            next(211, 1),
            error(400, testError)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2Empty() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            completed(300)
            ])

        let res = scheduler.start {
            xs.throttle2(10, scheduler: scheduler)
        }

        let correct = [
            completed(300, Int.self)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2Error() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            error(300, testError)
            ])

        let res = scheduler.start {
            xs.throttle2(10, scheduler: scheduler)
        }

        let correct = [
            error(300, testError, Int.self)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2Never() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            ])

        let res = scheduler.start {
            xs.throttle2(10, scheduler: scheduler)
        }

        let correct: [Recorded<Event<Int>>] = [
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 1000)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2Simple() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(250, 3),
            next(280, 4),
            completed(300)
            ])

        let res = scheduler.start {
            xs.throttle2(20, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(241, 2),
            next(281, 4),
            completed(300)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle2WithRealScheduler() {
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default)

        let start = NSDate()

        let a = try! [Observable.just(0), Observable.never()].toObservable().concat()
            .throttle2(2.0, scheduler: scheduler)
            .toBlocking()
            .first()

        let end = NSDate()

        XCTAssertEqualWithAccuracy(0, end.timeIntervalSinceDate(start), accuracy: 0.5)
        XCTAssertEqual(a, 0)
    }
}


// MARK: Throttle3
extension RxExtensionsTest {
    func test_Throttle3TimeSpan_AllPass() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            completed(400)
            ])

        let res = scheduler.start {
            xs.throttle3(20, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(241, 2),
            next(271, 3),
            next(301, 4),
            completed(400)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3TimeSpan_AllPass_ErrorEnd() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            error(400, testError)
            ])

        let res = scheduler.start {
            xs.throttle3(20, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(241, 2),
            next(271, 3),
            next(301, 4),
            error(400, testError)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3TimeSpan_AllDrop() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            next(330, 5),
            next(360, 6),
            next(390, 7),
            completed(400)
            ])

        let res = scheduler.start {
            xs.throttle3(40, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(400, 7),
            completed(400)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3TimeSpan_AllDrop_ErrorEnd() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(270, 3),
            next(300, 4),
            next(330, 5),
            next(360, 6),
            next(390, 7),
            error(400, testError)
            ])

        let res = scheduler.start {
            xs.throttle3(40, scheduler: scheduler)
        }

        let correct: [Recorded<Event<Int>>] = [
            next(211, 1),
            error(400, testError)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 400)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3Empty() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            completed(300)
            ])

        let res = scheduler.start {
            xs.throttle3(10, scheduler: scheduler)
        }

        let correct = [
            completed(300, Int.self)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3Error() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            error(300, testError)
            ])

        let res = scheduler.start {
            xs.throttle3(10, scheduler: scheduler)
        }

        let correct = [
            error(300, testError, Int.self)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3Never() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            ])

        let res = scheduler.start {
            xs.throttle3(10, scheduler: scheduler)
        }

        let correct: [Recorded<Event<Int>>] = [
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 1000)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3Simple() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 0),
            next(210, 1),
            next(240, 2),
            next(250, 3),
            next(260, 4),
            next(290, 5),
            completed(300)
            ])

        let res = scheduler.start {
            xs.throttle3(20, scheduler: scheduler)
        }

        let correct = [
            next(211, 1),
            next(241, 2),
            next(280, 4),
            next(291, 5),
            completed(300)
        ]

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 300)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle3WithRealScheduler() {
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default)
        
        let start = NSDate()
        
        let a = try! [Observable.just(0), Observable.never()].toObservable().concat()
            .throttle3(2.0, scheduler: scheduler)
            .toBlocking()
            .first()
        
        let end = NSDate()
        
        XCTAssertEqualWithAccuracy(0, end.timeIntervalSinceDate(start), accuracy: 0.5)
        XCTAssertEqual(a, 0)
    }
}

// MARK: Delay
extension RxExtensionsTest {

    func testDelay_TimeSpan_Simple1() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 1),
            next(250, 2),
            next(350, 3),
            next(450, 4),
            completed(550)
            ])

        let res = scheduler.start {
            xs.delay(100, scheduler: scheduler)
        }

        XCTAssertEqual(res.events, [
            next(350, 2),
            next(450, 3),
            next(550, 4),
            completed(650)
            ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 550)
            ])
    }

    func testDelay_TimeSpan_Simple2() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 1),
            next(250, 2),
            next(350, 3),
            next(450, 4),
            completed(550)
            ])

        let res = scheduler.start {
            xs.delay(50, scheduler: scheduler)
        }

        XCTAssertEqual(res.events, [
            next(300, 2),
            next(400, 3),
            next(500, 4),
            completed(600)
            ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 550)
            ])
    }

    func testDelay_TimeSpan_Simple3() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 1),
            next(250, 2),
            next(350, 3),
            next(450, 4),
            completed(550)
            ])

        let res = scheduler.start {
            xs.delay(150, scheduler: scheduler)
        }

        XCTAssertEqual(res.events, [
            next(400, 2),
            next(500, 3),
            next(600, 4),
            completed(700)
            ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 550)
            ])
    }

    func testDelay_TimeSpan_Error1() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 1),
            next(250, 2),
            next(350, 3),
            next(450, 4),
            error(550, testError)
            ])

        let res = scheduler.start {
            xs.delay(50, scheduler: scheduler)
        }

        XCTAssertEqual(res.events, [
            next(300, 2),
            next(400, 3),
            next(500, 4),
            error(550, testError)
            ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 550)
            ])
    }

    func testDelay_TimeSpan_Error2() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            next(150, 1),
            next(250, 2),
            next(350, 3),
            next(450, 4),
            error(550, testError)
            ])

        let res = scheduler.start {
            xs.delay(150, scheduler: scheduler)
        }

        XCTAssertEqual(res.events, [
            next(400, 2),
            next(500, 3),
            error(550, testError)
            ])

        XCTAssertEqual(xs.subscriptions, [
            Subscription(200, 550)
            ])
    }

    func testDelay_TimeSpan_Real_Simple() {
        let expectation = self.expectationWithDescription("")
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default)

        let s = PublishSubject<Int>()

        let res = s.delay(0.01, scheduler: scheduler)

        var array = [Int]()

        let subscription = res.subscribe(
            onNext: { i in
                array.append(i)
            },
            onCompleted: {
                expectation.fulfill()
        })

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            s.onNext(1)
            s.onNext(2)
            s.onNext(3)
            s.onCompleted()
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)

        subscription.dispose()

        XCTAssertEqual([1, 2, 3], array)
    }

    func testDelay_TimeSpan_Real_Error1() {
        let expectation = self.expectationWithDescription("")
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default)

        let s = PublishSubject<Int>()

        let res = s.delay(0.01, scheduler: scheduler)

        var array = [Int]()

        let subscription = res.subscribe(
            onNext: { i in
                array.append(i)
            },
            onError: { _ in
                expectation.fulfill()
        })

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            s.onNext(1)
            s.onNext(2)
            s.onNext(3)
            s.onError(testError)
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)

        subscription.dispose()

        XCTAssertEqual([], array)
    }

    func testDelay_TimeSpan_Real_Error2() {
        let expectation = self.expectationWithDescription("")
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default)

        let s = PublishSubject<Int>()

        let res = s.delay(0.01, scheduler: scheduler)

        var array = [Int]()
        var err: NSError!

        let subscription = res.subscribe(
            onNext: { i in
                array.append(i)
            },
            onError: { ex in
                err = ex as NSError
                expectation.fulfill()
        })

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            s.onNext(1)
            NSThread.sleepForTimeInterval(0.5)
            s.onError(testError)
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)

        subscription.dispose()

        XCTAssertEqual([1], array)
        XCTAssertEqual(testError, err)
    }

    func testDelay_TimeSpan_Real_Error3() {
        let expectation = self.expectationWithDescription("")
        let scheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .Default)

        let s = PublishSubject<Int>()

        let res = s.delay(0.01, scheduler: scheduler)

        var array = [Int]()
        var err: NSError!

        let subscription = res.subscribe(
            onNext: { i in
                array.append(i)
                NSThread.sleepForTimeInterval(0.5)
            },
            onError: { ex in
                err = ex as NSError
                expectation.fulfill()
        })

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            s.onNext(1)
            NSThread.sleepForTimeInterval(0.5)
            s.onError(testError)
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)

        subscription.dispose()

        XCTAssertEqual([1], array)
        XCTAssertEqual(testError, err)
    }
}
