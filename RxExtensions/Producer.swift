//
//  Producer.swift
//  RxExtensions
//
//  Created by Nobuo Saito on 2016/07/22.
//  Copyright © 2016年 tarunon. All rights reserved.
//

import RxSwift

func rxFatalError(_ lastMessage: String) -> Never {
    fatalError(lastMessage)
}

func abstractMethod() -> Never {
    rxFatalError("Abstract method")
}

class Producer<Element> : ObservableType {
    typealias E = Element

    init() {

    }

    func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if !CurrentThreadScheduler.isScheduleRequired {
            return run(observer)
        }
        else {
            return CurrentThreadScheduler.instance.schedule(()) { _ in
                return self.run(observer)
            }
        }
    }

    func run<O : ObserverType>(_ observer: O) -> Disposable where O.E == Element {
        abstractMethod()
    }
}
