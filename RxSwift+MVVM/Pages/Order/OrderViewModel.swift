//
//  OrderViewModel.swift
//  RxSwift+MVVM
//
//  Created by 최동호 on 2021/05/24.
//  Copyright © 2021 iamchiwon. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol OrderViewModelType {
    
    // OUTPUT
    var orderedList: Observable<String> { get }
    var itemsPriceText: Observable<String> { get }
    var itemsVatText: Observable<String> { get }
    var totalPriceText: Observable<String> { get }
}

class OrderViewModel: OrderViewModelType {
    
    // OUTPUT
    var orderedList: Observable<String>
    var itemsPriceText: Observable<String>
    var itemsVatText: Observable<String>
    var totalPriceText: Observable<String>
    
    init(_ selectedMenus: [Menu] = []){
        let menus = Observable.just(selectedMenus)
        let price = menus.map { $0.map { $0.price * $0.count }.reduce(0, +) }
        let vat = price.map { Int(Float($0) * 0.1 / 10 + 0.5) * 10 }
        
        self.orderedList = menus
            .map { $0.map { "\($0.name) \($0.count)개\n" }.joined() }
        
        self.itemsPriceText = price.map { $0.currencyKR() }
        
        self.itemsVatText = vat.map { $0.currencyKR() }
        
        self.totalPriceText = Observable.combineLatest(price, vat) { $0 + $1 }
        .map { $0.currencyKR() }
            
    }
}
