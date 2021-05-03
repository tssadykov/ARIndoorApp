//
//  ARNavigationBar.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 5/3/21.
//

import RxCocoa
import RxSwift
import UIKit

final class ARNavigationBarViewController: UIViewController {
    
    // MARK: - Public Nested Types
    
    enum State {
        case `default`
        case selectRoute
        case callibrate
        case changeFloor(Int)
        case route(Room)
    }
    
    // MARK: - Public properties
    
    let state = BehaviorRelay<State>(value: .default)
    
    var onClose: Observable<Void> {
        return exitButton.rx.tap.asObservable()
    }
    
    // MARK: - Public Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apply(stackView) {
            view.addSubview($0)
            $0.alignment = .center
            $0.distribution = .fill
            $0.axis = .horizontal
            $0.spacing = 15.0
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        }
        
        apply(textLabel) {
            stackView.addArrangedSubview($0)
        }
        
        apply(exitButton) {
            stackView.addArrangedSubview($0)
            $0.setImage(UIImage(named: "close"), for: .normal)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 25.0).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        }
        
        state
            .bind { [weak self] state in
                guard let slf = self else { return }
                
                switch state {
                case .default:
                    slf.exitButton.isHidden = true
                    slf.textLabel.text = "Scan QR to download scheme"
                    slf.textLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                case .selectRoute:
                    slf.exitButton.isHidden = true
                    slf.textLabel.text = "Select room to start route"
                    slf.textLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                case .callibrate:
                    slf.exitButton.isHidden = false
                    slf.textLabel.text = "Scan QR to callibrate accuracy"
                    slf.textLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                case .changeFloor(let floor):
                    slf.exitButton.isHidden = false
                    slf.textLabel.text = "Go to \(floor) floor and scan QR"
                    slf.textLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
                case .route(let room):
                    slf.exitButton.isHidden = false
                    slf.textLabel.text = room.name
                    slf.textLabel.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
                }
            }
            .disposed(by: bag)
    }
    
    // MARK: - Private properties
    
    private let stackView = UIStackView()
    private let exitButton = UIButton()
    private let textLabel = UILabel()
    private let bag = DisposeBag()
}
