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

    private var onCountChanged: (Int) -> Void
    private let cellDisposeBag = DisposeBag()
    
    var disposeBag = DisposeBag()

    // INPUT
    var onData: AnyObserver<Menu>
    
    // OUTPUT
    var countChanged: Observable<Int>
    
    required init?(coder: NSCoder) {
        
        print("inside init?")
        
        let data = PublishSubject<Menu>()
        let countChanging = PublishSubject<Int>()
        
        self.onData = data.asObserver()
        self.countChanged = countChanging
        
        // INPUT
        self.onCountChanged = countChanging.onNext
        
        super.init(coder: coder)
        
        // OUTPUT

        // menu list에서 값 전달 받기.
        data.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] menu in
                self?.title.text = menu.name
                self?.count.text = "\(menu.count)"
                self?.price.text = "\(menu.price)"
            })
            .disposed(by: self.cellDisposeBag)
        
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    
    // MARK: - Interface Builder Outlets
    
    @IBOutlet var title: UILabel!
    @IBOutlet var count: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var increaseCountBtn: UIButton!
    @IBOutlet var decreseCountBtn: UIButton!
    
    @IBAction func onIncreaseCount() {
        onCountChanged(1)
    }

    @IBAction func onDecreaseCount() {
        onCountChanged(-1)
    }
}
