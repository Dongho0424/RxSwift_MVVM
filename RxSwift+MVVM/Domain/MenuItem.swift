//
//  Model.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 07/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift

struct MenuItem: Decodable {
    var name: String
    var price: Int
}

protocol MenuItemFetchable {
    func fetchMenus() -> Observable<[MenuItem]>
}

class MenuItemStore: MenuItemFetchable {
    func fetchMenus() -> Observable<[MenuItem]> {
        return APIService.fetchAllMenusRx() // Result: Observable<[Menu]>
            .map { data -> [MenuItem] in
                struct Response: Decodable {
                    let menus: [MenuItem]
                }
                let menuItems = try! JSONDecoder().decode(Response.self, from: data).menus
                return menuItems
            }
    }
}
