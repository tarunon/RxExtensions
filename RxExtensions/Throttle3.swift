//
//  Throttle2.swift
//  RxExtensions
//
//  Created by Nobuo Saito on 2016/07/22.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class Throttle3Sink<O: ObserverType>
    : Sink<O>
    , ObserverType
    , LockOwnerType
, SynchronizedOnType {
    typealias Element = O.E
    typealias ParentType = Throttle3<Element>

    private let _parent: ParentType

    let _lock = NSRecursiveLock()

    // state
    private var _id = 0 as UInt64
    private var _value: Element? = nil
    private var _timestamp: RxTime? = nil

    let cancellable = SerialDisposable()

    init(parent: ParentType, observer: O) {
        _parent = parent

        super.init(observer: observer)
    }

    func run() -> Disposable {
        let subscription = _parent._source.subscribe(self)

        return StableCompositeDisposable.create(subscription, cancellable)
    }

    func on(event: Event<Element>) {
        synchronizedOn(event)
    }

    func _synchronized_on(event: Event<Element>) {
        switch event {
        case .Next(let element):
            _id = _id &+ 1
            let currentId = _id
            let d = SingleAssignmentDisposable()
            self.cancellable.disposable = d
            let dueTime: RxTimeInterval
            if let timestamp = _timestamp {
                dueTime = _parent._dueTime - timestamp.timeIntervalSinceDate(_parent._scheduler.now)
            } else {
                dueTime = 0.0
            }
            _timestamp = _parent._scheduler.now
            _value = element
            d.disposable = CompositeDisposable(
                _parent._scheduler.scheduleRelative(currentId, dueTime: dueTime, action: self.propagate),
                _parent._scheduler.scheduleRelative(currentId, dueTime: dueTime + _parent._dueTime, action: self.resetTimestamp)
            )
        case .Error:
            _value = nil
            forwardOn(event)
            dispose()
        case .Completed:
            if let value = _value {
                _value = nil
                forwardOn(.Next(value))
            }
            forwardOn(.Completed)
            dispose()
        }
    }

    func propagate(currentId: UInt64) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        if let value = _value where currentId == _id {
            _value = nil
            forwardOn(.Next(value))
        }
        // }
        return NopDisposable.instance
    }

    func resetTimestamp(currentId: UInt64) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        if  currentId == _id {
            _timestamp = nil
        }
        // }
        return NopDisposable.instance
    }
}

class Throttle3<Element> : Producer<Element> {

    private let _source: Observable<Element>
    private let _dueTime: RxTimeInterval
    private let _scheduler: SchedulerType

    init(source: Observable<Element>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }

    override func run<O: ObserverType where O.E == Element>(observer: O) -> Disposable {
        let sink = Throttle3Sink(parent: self, observer: observer)
        sink.disposable = sink.run()
        return sink
    }
}

extension ObservableType {
    /**
     throttle3 is like of throttle2, and send last event after wait dueTime.
     */
    public func throttle3(dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<Self.E> {
        return Throttle3(source: self.asObservable(), dueTime: dueTime, scheduler: scheduler).asObservable()
    }
}

extension Driver {
    /**
     throttle3 is like of throttle2, and send last event after wait dueTime.
     */
    public func throttle3(dueTime: RxTimeInterval) -> Driver<Element> {
        return Throttle3(source: self.asObservable(), dueTime: dueTime, scheduler: MainScheduler.instance).asDriver(onErrorDriveWith: Driver.empty())
    }
}

