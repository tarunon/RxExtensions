//
//  Delay.swift
//  RxExtensions
//
//  Created by Nobuo Saito on 2016/07/22.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class DelaySink<ElementType, O: ObserverType where O.E == ElementType>
    : Sink<O>
, ObserverType {
    typealias E = O.E
    typealias Source = Observable<E>
    typealias DisposeKey = Bag<Disposable>.KeyType

    // state
    private let _group = CompositeDisposable()
    private let _sourceSubscription = SingleAssignmentDisposable()

    private let _lock = NSRecursiveLock()

    private var _queue = Queue<(onTime: RxTime, event: Event<E>)>(capacity: 0)
    private var _running = false
    private var _disposed = false

    private let _dueTime: RxTimeInterval
    private let _scheduler: SchedulerType

    init(observer: O, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _dueTime = dueTime
        _scheduler = scheduler
        super.init(observer: observer)
    }

    func drainQueue(key: DisposeKey) -> Disposable {
        _lock.lock(); defer { _lock.unlock() } // lock {
        if !_queue.isEmpty {
            let (onTime, event) = _queue.peek()
            let timeInterval = _scheduler.now.timeIntervalSinceDate(onTime)
            if timeInterval < _dueTime {
                return _scheduler.scheduleRelative(key, dueTime: _dueTime - timeInterval, action: drainQueue)
            }
            _queue.dequeue()
            forwardOn(event)
            if event.isStopEvent {
                dispose()
            } else {
                return drainQueue(key)
            }
        }
        _running = false
        _group.removeDisposable(key)
        return NopDisposable.instance
        // }
    }

    func on(event: Event<E>) {
        _lock.lock(); defer { _lock.unlock() } // lock {
        switch event {
        case .Error(_):
            forwardOn(event)
            dispose()
        default:
            _queue.enqueue((_scheduler.now, event))
            if !_running {
                _running = true
                let delayDisposable = SingleAssignmentDisposable()
                if let key = _group.addDisposable(delayDisposable) {
                    delayDisposable.disposable = _scheduler.scheduleRelative(key, dueTime: _dueTime, action: drainQueue)
                }
            }
        }
        // }
    }

    func run(source: Source) -> Disposable {
        _group.addDisposable(_sourceSubscription)
        _sourceSubscription.disposable = source.subscribe(self)

        return _group
    }
}

class Delay<Element>: Producer<Element> {
    private let _source: Observable<Element>
    private let _dueTime: RxTimeInterval
    private let _scheduler: SchedulerType

    init(source: Observable<Element>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }

    override func run<O : ObserverType where O.E == Element>(observer: O) -> Disposable {
        let sink = DelaySink(observer: observer, dueTime: _dueTime, scheduler: _scheduler)
        sink.disposable = sink.run(_source)
        return sink
    }
}

extension ObservableType {
    /**
     [delay operator on reactivex.io](http://reactivex.io/documentation/operators/delay.html)
    */
    public func delay(dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<Self.E> {
        return Delay(source: self.asObservable(), dueTime: dueTime, scheduler: scheduler).asObservable()
    }
}

extension Driver {
    /**
     [delay operator on reactivex.io](http://reactivex.io/documentation/operators/delay.html)
     */
    public func delay(dueTime: RxTimeInterval) -> Driver<Element> {
        return Delay(source: self.asObservable(), dueTime: dueTime, scheduler: MainScheduler.instance).asDriver(onErrorDriveWith: Driver.empty())
    }
}

