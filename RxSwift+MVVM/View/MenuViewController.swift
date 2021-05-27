//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxViewController
import RxCocoa

// view controller
// 1. 뷰의 요소만 지정
// 2. 로직 처리는 다 view model이 가지고 있음
class MenuViewController: UIViewController {
    
    private let viewModel : MenuViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    init(viewModel : MenuViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        viewModel = MenuViewModel()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        setUpBindings()
    }

    // 화면 넘어가기 전에 거치는 코드.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier ?? ""
        if identifier == OrderViewController.identifier,
           let selectedMenus = sender as? [Menu],
           let orderVC = segue.destination as? OrderViewController {
            orderVC.viewModel = OrderViewModel(selectedMenus)
        }
    }
    
    // MARK: - UI Binding

    func setUpBindings(){
        // ------------------------------
        //             INPUT
        // ------------------------------
        
        // 처음 + clear 버튼 눌렀을 때
        let viewWillAppeaer = self.rx.viewWillAppear
            .take(1)
            .map { _ in () }
        let clearBtnTapped = self.clearBtn.rx.tap.map { _ in () }
        Observable.merge([viewWillAppeaer, clearBtnTapped])
            .bind(to: self.viewModel.input.clearButtonSelected)
            .disposed(by: self.disposeBag)
        
        
        // 처음 로딩 + refresh 했을 때
        let firstLoad = self.rx.viewWillAppear
            .take(1)
            .map{ _ in () }
        let refresh = self.tableView.refreshControl?.rx
            .controlEvent(.valueChanged)
            .map { _ in () } ?? Observable.just(())
        Observable.merge([firstLoad, refresh])
            .bind(to: self.viewModel.input.fetchMenus)
            .disposed(by: self.disposeBag)
        
        // order button click
        self.orderBtn.rx.tap
            .bind(to: self.viewModel.input.makeOrder)
            .disposed(by: self.disposeBag)
        
        // ------------------------------
        //           NAVIGATION
        // ------------------------------
        
        self.viewModel.output.orderPage
            .subscribe(onNext: { [weak self] in
                self?.performSegue(withIdentifier: OrderViewController.identifier, sender: $0)
            })
            .disposed(by: self.disposeBag)


        // ------------------------------
        //             OUTPUT
        // ------------------------------
        
        // activity indicator
        self.viewModel.output.activated // observable
            .do(onNext: { [weak self] activated in
                if !activated {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .drive(self.activityIndicator.rx.isAnimating) // observer
            .disposed(by: self.disposeBag)

        // tableview cell 정보들
        self.viewModel.output.allMenus
            .drive(self.tableView.rx.items(cellIdentifier: MenuItemTableViewCell.identifer, cellType: MenuItemTableViewCell.self)){
                index, item, cell in
                
                cell.title.text = item.name
                cell.count.text = "\(item.count)"
                cell.price.text = "\(item.price)"
                
                cell.countChanged
                    .map { (item, $0) }
                    .bind(to: self.viewModel.input.increaseMenuCount)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: self.disposeBag)
                
        self.viewModel.output.totalCountText
            .drive(self.itemCountLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.totalPriceText
            .drive(self.totalPrice.rx.text)
            .disposed(by: self.disposeBag)
    }

    // MARK: - InterfaceBuilder Links

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var itemCountLabel: UILabel!
    @IBOutlet var totalPrice: UILabel!
    @IBOutlet var clearBtn: UIButton!
    @IBOutlet var orderBtn: UIButton!
    
}

// 끊어지지 않는 Subject: Relay
// ui 특징: 1. 메인쓰레드 2. 끊어지면 안된다.
