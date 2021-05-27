//
//  MenuListViewModel.swift
//  RxSwift+MVVM
//
//  Created by 최동호 on 2021/05/21.
//  Copyright © 2021 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol MenuViewModelType {
    
    associatedtype Input
    associatedtype Output
    
    var input: Input { get }
    var output: Output { get }
}

class MenuViewModel: MenuViewModelType {
    
    struct Input {
        var fetchMenus: AnyObserver<Void>
        var clearButtonSelected: AnyObserver<Void>
        var makeOrder: AnyObserver<Void>
        var increaseMenuCount: AnyObserver<(menu: Menu, increase: Int)>
    }
    
    struct Output {
        var activated: Driver<Bool>
        var errorMessage: Observable<NSError>
        var allMenus: Driver<[Menu]>
        var totalCountText: Driver<String>
        var totalPriceText: Driver<String>
        var orderPage: Observable<[Menu]>
    }
    
    private let disposeBag = DisposeBag()
    
    let input: Input
    let output: Output
    
    init(domain: MenuItemFetchable = MenuItemStore()) {
        
        // ------------------------------
        //            Streams
        // ------------------------------
        let fetching = PublishSubject<Void>() // cause error
        let clearing = PublishSubject<Void>()
        let increasing = PublishSubject<(menu: Menu, increase: Int)>()
        let activating = BehaviorRelay<Bool>(value: false)
        let menus = BehaviorSubject<[Menu]>(value: [])
        // cause error
        // 1. fetching
        // 2. order page 에서 menu 개수 0개 이면
        let error = PublishSubject<NSError>()
        let ordering = PublishSubject<Void>()
        
        // menus fetching..
        // bind to menus, activating, error
        fetching
            .do(onNext: { _ in activating.accept(true) })
            .flatMap { domain.fetchMenus() } // Observable<[Menu]>
            .map { $0.map { Menu.MenuFromMenuItem($0) } }
            .do(onNext: { _ in activating.accept(false) },
                onError: { err in error.onNext(err as NSError) })
            .subscribe(onNext: menus.onNext)
            .disposed(by: self.disposeBag)
        
        // clearing all menus' count ..
        // bind to menus
        clearing
            .withLatestFrom(menus)
            .map { $0.map { $0.setCount(count: 0) } }
            .subscribe(onNext: menus.onNext)
            .disposed(by: self.disposeBag)
        
        // increasing a single menu's count..
        // bind to menu
        increasing
            .map { $0.menu.setCount(count: max(0, $0.menu.count + $0.increase)) }
            .withLatestFrom(menus) { (updated, original) -> [Menu] in
                original.map { originalMenu in
                    if originalMenu.name == updated.name {
                        return updated
                    } else {
                        return originalMenu
                    }
                }
            } // update된 메뉴를 고려해, 새로운 menu array return
            .subscribe(onNext: menus.onNext)
            .disposed(by: self.disposeBag)
        
        let totalCountText = menus.map { menus in
            menus.reduce(0) { $0 + $1.count }
        }
        .map { "\($0)" }
        
        let totalPriceText = menus.map { menus in
            menus.reduce(0) { $0 + $1.count * $1.price }
        }
        .map { "\($0)" }
        
        let orderPage = ordering
            .withLatestFrom(menus)
            .map { $0.filter { $0.count > 0 } }
            .do(onNext: { menus in
                if menus.count == 0 {
                    let err = NSError(domain: "No Orders", code: -1, userInfo: nil)
                    error.onNext(err)
                }
            })
            .filter { $0.count > 0 }

        
        // ------------------------------
        //        Input and Output
        // ------------------------------
        self.input = Input(fetchMenus: fetching.asObserver(),
                           clearButtonSelected: clearing.asObserver(),
                           makeOrder: ordering.asObserver(),
                           increaseMenuCount: increasing.asObserver())
        
        self.output = Output(activated: activating.asDriver(),
                             errorMessage: error.asObserver(),
                             allMenus: menus.asDriver(onErrorJustReturn: []),
                             totalCountText: totalCountText.asDriver(onErrorJustReturn: "0"),
                             totalPriceText: totalPriceText.asDriver(onErrorJustReturn: "\(0.currencyKR())"),
                             orderPage: orderPage)
    }
}


