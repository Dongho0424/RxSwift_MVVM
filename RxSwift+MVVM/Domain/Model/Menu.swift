//
//  Menu.swift
//  RxSwift+MVVM
//
//  Created by 최동호 on 2021/05/21.
//  Copyright © 2021 iamchiwon. All rights reserved.
//

import Foundation

// view 에서 쓰이는 model
struct Menu {
    let name: String
    let price: Int
    var count: Int
}

extension Menu: Equatable {
    static func MenuFromMenuItem(_ item: MenuItem) -> Menu {
        return Menu(name: item.name, price: item.price, count: 0)
    }
    
    static func == (lhs: Menu, rhs: Menu) -> Bool {
        return
            lhs.count == rhs.count &&
            lhs.name == rhs.name &&
            lhs.price == rhs.price
    }

    func setCount(count: Int) -> Menu {
        return Menu(name: self.name, price: self.price, count: count)
    }
}
