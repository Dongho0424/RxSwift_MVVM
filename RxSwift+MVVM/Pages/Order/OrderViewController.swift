//
//  OrderViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 07/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class OrderViewController: UIViewController {
    static let identifier = "OrderViewController"
    
    var viewModel = OrderViewModel()
    let disposeBag = DisposeBag()
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBindings()
    }

    
    // MARK: - Set up UI Bindings
    func setUpBindings() {
        
        self.ordersList.rx.text.orEmpty // observer
            .distinctUntilChanged()
            .map { [weak self] _ in self?.ordersList.calcHeight() ?? 0 }
            .bind(to: ordersListHeight.rx.constant)
            .disposed(by: disposeBag)
        
        self.viewModel.orderedList
            .bind(to: ordersList.rx.text)
            .disposed(by: disposeBag)

        self.viewModel.itemsPriceText
            .bind(to: itemsPrice.rx.text)
            .disposed(by: disposeBag)

        self.viewModel.itemsVatText
            .bind(to: vatPrice.rx.text)
            .disposed(by: disposeBag)

        self.viewModel.totalPriceText
            .bind(to: totalPrice.rx.text)
            .disposed(by: disposeBag)
    }

    // MARK: - Interface Builder

    @IBOutlet var ordersList: UITextView!
    @IBOutlet var ordersListHeight: NSLayoutConstraint!
    @IBOutlet var itemsPrice: UILabel!
    @IBOutlet var vatPrice: UILabel!
    @IBOutlet var totalPrice: UILabel!
}
