//
//  Sink.swift
//  RxExtensions
//
//  Created by Nobuo Saito on 2016/07/22.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import Foundation
import RxSwift

class Sink<O : ObserverType> : Disposable {
    fileprivate let disposable = SingleAssignmentDisposable()
    fileprivate let _observer: O

    init(observer: O) {
        _observer = observer
    }

    final func forwardOn(_ event: Event<O.E>) {
        if disposable.isDisposed {
            return
        }
        _observer.on(event)
    }

    final func forwarder() -> SinkForward<O> {
        return SinkForward(forward: self)
    }

    func dispose() {
        disposable.dispose()
    }

    func setDisposable(_ disposable: Disposable) {
        self.disposable.setDisposable(disposable)
    }
}

class SinkForward<O: ObserverType>: ObserverType {
    typealias E = O.E

    private let _forward: Sink<O>

    init(forward: Sink<O>) {
        _forward = forward
    }

    func on(_ event: Event<E>) {
        switch event {
        case .next:
            _forward._observer.on(event)
        case .error, .completed:
            _forward._observer.on(event)
            _forward.dispose()
        }
    }
}
