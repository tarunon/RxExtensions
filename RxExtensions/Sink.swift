//
//  Sink.swift
//  RxExtensions
//
//  Created by Nobuo Saito on 2016/07/22.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import Foundation
import RxSwift

class Sink<O : ObserverType> : SingleAssignmentDisposable {
    private let _observer: O

    init(observer: O) {
        _observer = observer
    }

    final func forwardOn(event: Event<O.E>) {
        if disposed {
            return
        }
        _observer.on(event)
    }

    final func forwarder() -> SinkForward<O> {
        return SinkForward(forward: self)
    }
}

class SinkForward<O: ObserverType>: ObserverType {
    typealias E = O.E

    private let _forward: Sink<O>

    init(forward: Sink<O>) {
        _forward = forward
    }

    func on(event: Event<E>) {
        switch event {
        case .Next:
            _forward._observer.on(event)
        case .Error, .Completed:
            _forward._observer.on(event)
            _forward.dispose()
        }
    }
}
