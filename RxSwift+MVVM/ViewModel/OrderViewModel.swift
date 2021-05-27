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
    associatedtype Output
    
    var output: Output { get }
}

class OrderViewModel: OrderViewModelType {
    
    struct Output {
        var orderedList: Observable<String>
        var itemsPriceText: Observable<String>
        var itemsVatText: Observable<String>
        var totalPriceText: Observable<String>
    }
    
    let output: Output
    
    init(_ selectedMenus: [Menu] = []){
        // ------------------------------
        //            Streams
        // ------------------------------
        let menus = Observable.just(selectedMenus)
        let price = menus.map { $0.map { $0.price * $0.count }.reduce(0, +) }
        let vat = price.map { Int(Float($0) * 0.1 / 10 + 0.5) * 10 }
        
        let orderedList = menus
            .map { $0.map { "\($0.name) \($0.count)개\n" }.joined() }
        
        let itemsPriceText = price.map { $0.currencyKR() }
        
        let itemsVatText = vat.map { $0.currencyKR() }
        
        let totalPriceText = Observable.combineLatest(price, vat) { $0 + $1 }
            .map { $0.currencyKR() }
        
        // OUTPUT
        
        self.output = Output(orderedList: orderedList,
                             itemsPriceText: itemsPriceText,
                             itemsVatText: itemsVatText,
                             totalPriceText: totalPriceText)
        
    }
}
