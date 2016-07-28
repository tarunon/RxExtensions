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
    typealias DisposeKey = Bag<Disposable>.KeyType

    private let _parent: ParentType

    let _lock = NSRecursiveLock()

    // state
    private var _id = 0 as UInt64
    private var _value: Element? = nil
    private var _dropping: Bool = false

    let cancellable = CompositeDisposable()

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
            if let key = self.cancellable.addDisposable(d) {
                _value = element
                if _dropping {
                    d.disposable = CompositeDisposable(
                        _parent._scheduler.scheduleRelative((currentId), dueTime: _parent._dueTime, action: self.propagate),
                        _parent._scheduler.scheduleRelative((currentId, key), dueTime: _parent._dueTime, action: self.endDrop)
                    )
                } else {
                    _dropping = true
                    d.disposable = CompositeDisposable(
                        _parent._scheduler.scheduleRelative((), dueTime: 0.0, action: self.propagate),
                        _parent._scheduler.scheduleRelative((currentId, key), dueTime: _parent._dueTime, action: self.endDrop)
                    )
                }
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

    func propagate(currentId: UInt64) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        if let value = _value where currentId == _id {
            _value = nil
            forwardOn(.Next(value))
        }
        // }
        return NopDisposable.instance
    }

    func endDrop(currentId: UInt64, key: DisposeKey) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        cancellable.removeDisposable(key)
        if  currentId == _id {
            _dropping = false
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

