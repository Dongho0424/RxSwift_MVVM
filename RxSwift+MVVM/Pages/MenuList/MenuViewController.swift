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
    
    let cellId = "MenuItemTableViewCell"
    
    let viewModel : MenuViewModelType
    let disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    init(viewModel: MenuViewModelType = MenuViewModel()) {
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
            .bind(to: self.viewModel.clearSelections)
            .disposed(by: self.disposeBag)
        
        
        // 처음 로딩 + refresh 했을 때
        let firstLoad = self.rx.viewWillAppear
            .take(1)
            .map{ _ in () }
        let refresh = self.tableView.refreshControl?.rx
            .controlEvent(.valueChanged)
//            .do(onNext: { [weak self] in
//                guard let `self` = self else {
//                    print("dongho")
//                    return
//                }
//                self.activityIndicator.stopAnimating()
//            })
            .map { _ in () } ?? Observable.just(())
        Observable.merge([firstLoad, refresh])
            .bind(to: self.viewModel.fetchMenus)
            .disposed(by: self.disposeBag)
        
        // order btn click
        self.orderBtn.rx.tap
            .bind(to: self.viewModel.makeOrder)
            .disposed(by: self.disposeBag)
        
        // ------------------------------
        //           NAVIGATION
        // ------------------------------
        
        self.viewModel.orderPage
            .subscribe(onNext: { [weak self] in
                self?.performSegue(withIdentifier: OrderViewController.identifier, sender: $0)
            })
            .disposed(by: self.disposeBag)


        // ------------------------------
        //             OUTPUT
        // ------------------------------
        
        // activity indicator
        self.viewModel.activated // observable
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] activated in
                if !activated {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .bind(to: self.activityIndicator.rx.isAnimating) // observer
//            .subscribe(onNext: {
//                if $0 {
//                    self.activityIndicator.startAnimating()
//                } else {
//                    self.activityIndicator.stopAnimating()
//                }
//            })
            .disposed(by: self.disposeBag)

        // tableview cell 정보들
        self.viewModel.allMenus
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: self.tableView.rx.items(cellIdentifier: self.cellId, cellType: MenuItemTableViewCell.self)){
                index, item, cell in
                
                cell.onData.onNext(item)
                
                // cell.onChanged(observable)을 increaseMenuCount(observser)가 subscribe
                // 바인딩을 이 코드블럭에서 하는 이유는 특정 cell을 특정해야 특정 menu를
                // viewModel의 increaseMenuCount로 전달하기 때문에
                cell.countChanged // Observable<Int>
                    .map { (item, $0) }
                    .bind(to: self.viewModel.increaseMenuCount)
                    .disposed(by: cell.disposeBag)
                
            }
            .disposed(by: self.disposeBag)
                
        self.viewModel.totalCountText
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: self.itemCountLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.viewModel.totalPriceText
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: self.totalPrice.rx.text)
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
