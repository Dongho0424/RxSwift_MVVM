//
//  MenuListViewModel.swift
//  RxSwift+MVVM
//
//  Created by 최동호 on 2021/05/21.
//  Copyright © 2021 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift

protocol MenuViewModelType {
    var fetchMenus: AnyObserver<Void> { get }
    var clearSelections: AnyObserver<Void> { get }
    var makeOrder: AnyObserver<Void> { get }
    var increaseMenuCount: AnyObserver<(menu: Menu, increase: Int)> { get }

    var activated: Observable<Bool> { get }
//    var errorMessage: Observable<NSError> { get }
    var allMenus: Observable<[Menu]> { get }
    var totalCountText: Observable<String> { get }
    var totalPriceText: Observable<String> { get }
    var orderPage: Observable<[Menu]> { get }
}


// View Model
// 모든 로직 처리를 담당하므로
// 로직에서 생긴 오류는 여기서 찾으면 됨.
class MenuViewModel: MenuViewModelType {
    
    // INPUT
    var fetchMenus: AnyObserver<Void>
    var clearSelections: AnyObserver<Void>
    var increaseMenuCount: AnyObserver<(menu: Menu, increase: Int)>
    var makeOrder: AnyObserver<Void>
    
    // OUTPUT
    var activated: Observable<Bool>
    let allMenus: Observable<[Menu]>
    let totalCountText: Observable<String>
    let totalPriceText: Observable<String>
    var orderPage: Observable<[Menu]>
    
    let disposeBag = DisposeBag()
    
    init(){
        let fetching = PublishSubject<Void>()
        let clearing = PublishSubject<Void>()
        let increasing = PublishSubject<(menu: Menu, increase: Int)>()

        let menus = BehaviorSubject<[Menu]>(value: [])
        let activating = BehaviorSubject<Bool>(value: false)
        let ordering = PublishSubject<Void>()
        
        // INPUT
        
        self.fetchMenus = fetching.asObserver()
        
        fetching
            .do(onNext: { _ in activating.onNext(true) })
            .flatMap {
                return APIService.fetchAllMenusRx() // Result: Observable<[Menu]>
                    .map { data -> [MenuItem] in
                        struct Response: Decodable {
                            let menus: [MenuItem]
                        }
                        let menuItems = try! JSONDecoder().decode(Response.self, from: data).menus
                        return menuItems
                    }
                    .map { menuItems -> [Menu] in // Result: [Menu]
                        var menus = [Menu]()
                        menuItems.enumerated().forEach {
                            (index, menuItem) in
                            let menu = Menu.MenuFromMenuItem(id: index, item: menuItem)
                            menus.append(menu)
                        }
                        return menus // [Menu]
                    }
            } // Observable<[Menu]>
            .do(onNext: { _ in activating.onNext(false) })
            .subscribe(onNext: menus.onNext)
            .disposed(by: self.disposeBag)
            
        
        self.clearSelections = clearing.asObserver()
        
        clearing
            .withLatestFrom(menus)
            .map { $0.map { $0.setCount(count: 0) } }
            .subscribe(onNext: menus.onNext)
            .disposed(by: self.disposeBag)
        
        self.increaseMenuCount = increasing.asObserver()
        
        increasing
            .map { $0.menu.setCount(count: max(0, $0.menu.count + $0.increase)) }
            .withLatestFrom(menus) { (updated /* Menu */, original) -> [Menu] in
                original.map { originalMenu in
                    if originalMenu.name == updated.name {
                        return updated
                    } else {
                        return originalMenu
                    }
                }
            }
            .subscribe(onNext: menus.onNext)
            .disposed(by: self.disposeBag)
        
        self.makeOrder = ordering.asObserver()
        
        // OUTPUT
        
        self.allMenus = menus
        
        self.activated = activating.distinctUntilChanged()
        
        self.totalCountText = menus.map {
            $0.map { $0.count }.reduce(0) { $0 + $1 }
        }.map { "\($0)" }
        
        self.totalPriceText = menus.map {
            $0.map { $0.count * $0.price }.reduce(0) { $0 + $1 }
        }.map { $0.currencyKR() }
        
        self.orderPage = ordering.withLatestFrom(menus)
            .map { $0.filter { $0.count > 0 } }
            .filter { $0.count > 0 }
            
    }
}



