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

protocol Lock {
    func lock()
    func unlock()
}

protocol LockOwnerType : class, Lock {
    var _lock: NSRecursiveLock { get }
}

extension LockOwnerType {
    func lock() {
        _lock.lock()
    }

    func unlock() {
        _lock.unlock()
    }
}

protocol SynchronizedOnType : class, ObserverType, Lock {
    func _synchronized_on(event: Event<E>)
}

extension SynchronizedOnType {
    func synchronizedOn(event: Event<E>) {
        lock(); defer { unlock() }
        _synchronized_on(event)
    }
}

class Throttle2Sink<O: ObserverType>
    : Sink<O>
    , ObserverType
    , LockOwnerType
, SynchronizedOnType {
    typealias Element = O.E
    typealias ParentType = Throttle2<Element>

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
            _value = element
            if let timestamp = _timestamp {
                let dueTime = _parent._dueTime - timestamp.timeIntervalSinceDate(_parent._scheduler.now)
                _timestamp = _parent._scheduler.now
                d.disposable = _parent._scheduler.scheduleRelative(currentId, dueTime: dueTime + _parent._dueTime, action: self.resetTimestamp)
            } else {
                _timestamp = _parent._scheduler.now
                d.disposable = CompositeDisposable(
                    _parent._scheduler.scheduleRelative((), dueTime: 0.0, action: self.propagate),
                    _parent._scheduler.scheduleRelative(currentId, dueTime: _parent._dueTime, action: self.resetTimestamp)
                )
            }
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

    func propagate() -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        if let value = _value {
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

class Throttle2<Element> : Producer<Element> {

    private let _source: Observable<Element>
    private let _dueTime: RxTimeInterval
    private let _scheduler: SchedulerType

    init(source: Observable<Element>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }

    override func run<O: ObserverType where O.E == Element>(observer: O) -> Disposable {
        let sink = Throttle2Sink(parent: self, observer: observer)
        sink.disposable = sink.run()
        return sink
    }
}

extension ObservableType {
    /**
     throttle2 is like of throttle, throttle2 send first event in dueTime.
    */
    public func throttle2(dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<Self.E> {
        return Throttle2(source: self.asObservable(), dueTime: dueTime, scheduler: scheduler).asObservable()
    }
}

extension Driver {
    /**
     throttle2 is like of throttle, throttle2 send first event in dueTime.
     */
    public func throttle2(dueTime: RxTimeInterval) -> Driver<Element> {
        return Throttle2(source: self.asObservable(), dueTime: dueTime, scheduler: MainScheduler.instance).asDriver(onErrorDriveWith: Driver.empty())
    }
}

