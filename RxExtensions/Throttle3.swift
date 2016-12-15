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
    typealias E = O.E
    typealias Element = O.E
    typealias ParentType = Throttle3<Element>
    typealias DisposeKey = CompositeDisposable.DisposeKey

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

        return Disposables.create(subscription, cancellable)
    }

    func on(_ event: Event<Element>) {
        synchronizedOn(event)
    }

    func _synchronized_on(_ event: Event<Element>) {
        switch event {
        case .next(let element):
            _id = _id &+ 1
            let currentId = _id
            let d = SingleAssignmentDisposable()
            if let key = self.cancellable.insert(d) {
                _value = element
                if _dropping {
                    d.setDisposable(Disposables.create(
                        _parent._scheduler.scheduleRelative((currentId), dueTime: _parent._dueTime, action: self.propagate),
                        _parent._scheduler.scheduleRelative((currentId, key), dueTime: _parent._dueTime, action: self.endDrop)
                    ))
                } else {
                    _dropping = true
                    d.setDisposable(Disposables.create(
                        _parent._scheduler.scheduleRelative((), dueTime: 0.0, action: self.propagate),
                        _parent._scheduler.scheduleRelative((currentId, key), dueTime: _parent._dueTime, action: self.endDrop)
                    ))
                }
            }
        case .error:
            _value = nil
            forwardOn(event)
            dispose()
        case .completed:
            if let value = _value {
                _value = nil
                forwardOn(.next(value))
            }
            forwardOn(.completed)
            dispose()
        }
    }

    func propagate() -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        if let value = _value {
            _value = nil
            forwardOn(.next(value))
        }
        // }
        return Disposables.create()
    }

    func propagate(currentId: UInt64) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        if let value = _value, currentId == _id {
            _value = nil
            forwardOn(.next(value))
        }
        // }
        return Disposables.create()
    }

    func endDrop(currentId: UInt64, key: DisposeKey) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // {
        cancellable.remove(for: key)
        if  currentId == _id {
            _dropping = false
        }
        // }
        return Disposables.create()
    }
}

class Throttle3<Element> : Producer<Element> {

    fileprivate let _source: Observable<Element>
    fileprivate let _dueTime: RxTimeInterval
    fileprivate let _scheduler: SchedulerType

    init(source: Observable<Element>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }

    override func run<O: ObserverType>(_ observer: O) -> Disposable where O.E == Element {
        let sink = Throttle3Sink(parent: self, observer: observer)
        sink.setDisposable(sink.run())
        return sink
    }
}

extension ObservableType {
    /**
     throttle3 is like of throttle2, and send last event after wait dueTime.
     */
    public func throttle3(_ dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<Self.E> {
        return Throttle3(source: self.asObservable(), dueTime: dueTime, scheduler: scheduler).asObservable()
    }
}

extension SharedSequence {
    /**
     throttle3 is like of throttle2, and send last event after wait dueTime.
     */
    public func throttle3(_ dueTime: RxTimeInterval) -> SharedSequence {
        return Throttle3(source: self.asObservable(), dueTime: dueTime, scheduler: MainScheduler.instance).asSharedSequence(onErrorDriveWith: SharedSequence.empty())
    }
}

