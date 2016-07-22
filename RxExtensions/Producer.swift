//
//  Producer.swift
//  RxExtensions
//
//  Created by Nobuo Saito on 2016/07/22.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import RxSwift

@noreturn func rxFatalError(lastMessage: String) {
    fatalError(lastMessage)
}

@noreturn func abstractMethod() -> Void {
    rxFatalError("Abstract method")
}

class Producer<Element> : ObservableType {
    typealias E = Element

    init() {

    }

    func subscribe<O : ObserverType where O.E == Element>(observer: O) -> Disposable {
        if !CurrentThreadScheduler.isScheduleRequired {
            return run(observer)
        }
        else {
            return CurrentThreadScheduler.instance.schedule(()) { _ in
                return self.run(observer)
            }
        }
    }

    func run<O : ObserverType where O.E == Element>(observer: O) -> Disposable {
        abstractMethod()
    }
}