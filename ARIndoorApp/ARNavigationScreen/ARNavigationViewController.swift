//
//  ViewController.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 1/18/21.
//

import UIKit
import ARKit
import RealityKit
import RxCocoa
import RxSwift

protocol ARNavigationViewControllerDeps {
    var buildingSchemeService: BuildingSchemeService { get }
    var urlPerformer: URLPerformer { get }
    var qrCodeReader: QRCodeReader { get }
    var schemeCacheService: SchemeCacheService { get }
}

class ARNavigationViewController: UIViewController {

    init(deps: ARNavigationViewControllerDeps) {
        self.deps = deps
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupBinds()
    }

    private let arView = ARView()
    private let selectRoomButton = UIButton()
    private let debugLabel = UILabel()
    private let finishLabel = UILabel()
    private let exitButton = UIButton()
    
    private var isScanningQR: Bool = true
    private let deps: ARNavigationViewControllerDeps
    
    private var arrowAnchor: AnchorEntity?
    private let bag = DisposeBag()
    private lazy var inArrow = try! Entity.load(named: "NavigationArrow")
    private let schemeSessionManager = BehaviorRelay<SchemeSessionManager?>(value: nil)
    
    private let saveButton = UIButton()
    private let arNavigationBar = ARNavigationBarViewController()
}

extension ARNavigationViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if isScanningQR {
            isScanningQR = false
            let rwp = frame.camera.realWorldPosition
            deps.qrCodeReader.readQRCode(image: frame.capturedImage) { string in
                guard let string = string else { self.isScanningQR = true; return }
                
                let task = self.deps.urlPerformer.perform(url: string)
                switch task {
                case .openScheme(let schemeId, let qrId):
                    self.deps.buildingSchemeService.loadScheme(for: schemeId) { result in
                        let onSuccessScheme: (Scheme) -> Void = { scheme in
                            if let schemeSessionManager = self.schemeSessionManager.value, schemeSessionManager.scheme._id == schemeId {
                                schemeSessionManager.continueRoute(from: qrId, userPosition: rwp)
                            } else {
                                self.schemeSessionManager.accept(SchemeSessionManager(userPosition: rwp, qrId: qrId, scheme: scheme))
                            }
                            UIApplication.shared.isIdleTimerDisabled = true
                        }
                        
                        switch result {
                        case .failure:
                            self.deps.schemeCacheService.getScheme(withId: schemeId) { scheme in
                                DispatchQueue.main.async {
                                    if let scheme = scheme {
                                        onSuccessScheme(scheme)
                                    } else {
                                        self.showAlert(title: "Failed qr code", description: nil)
                                    }
                                }
                            }
                        case .success(let scheme):
                            onSuccessScheme(scheme)
                        }
                    }
                case .none:
                    return
                }
            }
            
            return
        }
        
        let sessionState = schemeSessionManager.value?.applyRealWorldPosition(frame.camera.realWorldPosition)
        
        switch sessionState {
        case .direction(let direction):
            
            if finishLabel.alpha != 0.0 {
                UIView.animate(withDuration: 0.2) {
                    self.finishLabel.alpha = 0.0
                    self.finishLabel.transform = .init(scaleX: 0.0, y: 0.0)
                }
            }
            
            let cameraTransform = frame.camera.transform
            var matrixTransform = matrix_identity_float4x4
            matrixTransform[3] = cameraTransform[3]
            matrixTransform[3][1] -= 0.7
            matrixTransform = Math.rotateAroundY(matrix: matrixTransform, angle: direction)
            
            if arrowAnchor == nil {
                let inArrow = try! Entity.load(named: "NavigationArroww")
                let anchorEntity = AnchorEntity(world: matrixTransform)
                anchorEntity.addChild(inArrow)
                arView.scene.addAnchor(anchorEntity)
                self.arrowAnchor = anchorEntity
            } else {
                arrowAnchor?.reanchor(.world(transform: matrixTransform), preservingWorldTransform: false)
            }
            
        case .changeFloor(let floor):
            isScanningQR = true
            arNavigationBar.state.accept(.changeFloor(floor))
            
        case .finish:
            arView.scene.anchors.removeAll()
            arrowAnchor = nil
            if finishLabel.alpha == 0.0 {

                UIView.animate(withDuration: 0.2) {
                    self.finishLabel.alpha = 1.0
                    self.finishLabel.transform = .init(scaleX: 3.0, y: 3.0)
                } completion: { _ in
                    UIView.animate(withDuration: 0.2, delay: 1.0, options: .curveLinear, animations: {
                        self.finishLabel.alpha = 0.0
                        self.finishLabel.transform = .init(scaleX: 0.0, y: 0.0)
                    }, completion: nil)
                    self.schemeSessionManager.accept(nil)
                    self.isScanningQR = true
                }
            }
        case .callibrate:
            isScanningQR = true
            arNavigationBar.state.accept(.callibrate)
        case .none:
            arView.scene.anchors.removeAll()
            arrowAnchor = nil
        }
        
        if let sm = schemeSessionManager.value {
            debugLabel.text = "SCHEME POSITION:\nx = \(sm.currentPosition.x);\ny = \(sm.currentPosition.y)"
        } else {
            debugLabel.text = "REAL POSITION:\nx = \(frame.camera.transform[3][0]);\nz = \(frame.camera.transform[3][2])"
        }
    }
}

private extension ARCamera {
    
    var realWorldPosition: RealWorldPosition {
        return RealWorldPosition(x: transform[3][0], y: transform[3][1], z: transform[3][2], direction: eulerAngles.y)
    }
}

private extension ARNavigationViewController {
    
    // MARK: - Private Methods
    
    private func setupViews() {
        apply(arView) {
            view.addSubview($0)
            $0.session.delegate = self
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.worldAlignment = .gravity
            $0.session.run(configuration)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        apply(exitButton) {
            view.addSubview($0)
            $0.setImage(UIImage(named: "back-arrow")?.withTintColor(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)), for: .normal)
            $0.backgroundColor = .clear
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10.0).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25.0).isActive = true
        }
        
        apply(arNavigationBar) {
            addChild($0)
            $0.didMove(toParent: self)
            
            view.addSubview($0.view)
            $0.view.translatesAutoresizingMaskIntoConstraints = false
            $0.view.centerYAnchor.constraint(equalTo: exitButton.centerYAnchor).isActive = true
            $0.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20.0).isActive = true
            $0.view.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        }
        
        apply(debugLabel) {
            view.addSubview($0)
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.textColor = .gray

            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        }
        
        apply(finishLabel) {
            view.addSubview($0)
            $0.textAlignment = .center
            $0.alpha = 0.0
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            $0.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            $0.text = "FINISH"
            $0.textColor = .green
        }
        
        apply(selectRoomButton) {
            view.addSubview($0)
            $0.setImage(UIImage(named: "search"), for: .normal)
            $0.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).withAlphaComponent(0.4)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10.0).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 45.0).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 45.0).isActive = true
            $0.layer.cornerRadius = 8.0
        }
        
        apply(saveButton) {
            view.addSubview($0)
            $0.setImage(UIImage(named: "download"), for: .normal)
            $0.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).withAlphaComponent(0.4)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.bottomAnchor.constraint(equalTo: selectRoomButton.topAnchor, constant: -10.0).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 45.0).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 45.0).isActive = true
            $0.layer.cornerRadius = 8.0
        }
    }
    
    private func setupBinds() {
        schemeSessionManager
            .flatMapLatest {
                return $0?.isStart ?? .just(false)
            }
            .bind { [weak self] isStart in
                self?.selectRoomButton.isHidden = !isStart
            }
            .disposed(by: bag)
        
        schemeSessionManager
            .map {
                return $0 == nil
            }
            .bind(to: saveButton.rx.isHidden)
            .disposed(by: bag)
        
        schemeSessionManager
            .map {
                return $0 != nil
            }
            .bind { [weak self] isSchemeFetched in
                self?.arNavigationBar.state.accept(isSchemeFetched ? .selectRoute : .default)
            }
            .disposed(by: bag)
        
        exitButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: bag)
        
        saveButton.rx.tap
            .withLatestFrom(schemeSessionManager)
            .bind { [weak self] manager in
                guard let slf = self else { return }
                guard let manager = manager else { return }
                
                let scheme = manager.scheme
                
                slf.deps.schemeCacheService.cache(scheme: scheme) { success in
                    DispatchQueue.main.async {
                        if success {
                            slf.showAlert(title: "Success save", description: nil)
                            slf.saveButton.isHidden = true
                        } else {
                            slf.showAlert(title: "Failed", description: nil)
                        }
                    }
                }
            }
            .disposed(by: bag)
        
        selectRoomButton.rx.tap
            .withLatestFrom(schemeSessionManager)
            .bind { [weak self] manager in
                guard let slf = self else { return }
                guard let manager = manager else { return }
                
                let rooms = manager.rooms
                let pointsListVC = PointsListViewController(rooms: rooms)
                slf.present(pointsListVC, animated: true, completion: nil)
                
                pointsListVC.onRoomSelect
                    .bind { [weak self, weak plvc = pointsListVC] room in
                        guard let slf = self else { return }
                        guard slf.schemeSessionManager.value === manager else { return }
                        
                        plvc?.dismiss(animated: true, completion: {
                            manager.startRoute(to: room._id)
                            slf.arNavigationBar.state.accept(.route(room))
                        })
                    }
                    .disposed(by: slf.bag)
            }
            .disposed(by: bag)
        
        arNavigationBar.onClose
            .bind { [weak self] in
                self?.schemeSessionManager.accept(nil)
                self?.isScanningQR = true
            }
            .disposed(by: bag)
    }
}
