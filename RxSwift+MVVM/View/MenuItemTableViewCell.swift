//
//  MenuItemTableViewCell.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 07/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MenuItemTableViewCell: UITableViewCell {
    static let identifer = "MenuItemTableViewCell"
    
    public let disposeBag = DisposeBag()
    
    // Stream
    private let changing: PublishSubject<Int>
    
    // OUTPUT
    public let countChanged: Observable<Int>
    
    // init
    required init?(coder: NSCoder) {
        
        // Stream
        self.changing = PublishSubject<Int>()
        
        // OUTPUT
        self.countChanged = self.changing.asObservable()
        
        super.init(coder: coder)
    }
    
    // MARK: - Interface Builder Outlets
    
    @IBOutlet var title: UILabel!
    @IBOutlet var count: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var increaseCountBtn: UIButton!
    @IBOutlet var decreseCountBtn: UIButton!
    
    @IBAction func onIncreaseCount() {
        self.changing.onNext(1)
    }

    @IBAction func onDecreaseCount() {
        self.changing.onNext(-1)
    }
}
