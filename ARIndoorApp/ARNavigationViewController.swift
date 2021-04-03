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
    private let picker = UIPickerView()
    private let debugLabel = UILabel()
    private let finishLabel = UILabel()
    private let changeFloorLabel = UILabel()
    private let exitButton = UIButton()
    
    private var isScanningQR: Bool = true
    private let deps: ARNavigationViewControllerDeps
    
    private var arrowAnchor: AnchorEntity?
    private let bag = DisposeBag()
    private lazy var inArrow = try! Entity.load(named: "NavigationArrow")
    private let schemeSessionManager = BehaviorRelay<SchemeSessionManager?>(value: nil)
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
                        switch result {
                        case .failure:
                            self.showAlert(title: "Failed qr code", description: nil)
                        case .success(let scheme):
                            if let schemeSessionManager = self.schemeSessionManager.value, schemeSessionManager.scheme._id == schemeId {
                                schemeSessionManager.continueRoute(from: qrId, userPosition: rwp)
                            } else {
                                self.schemeSessionManager.accept(SchemeSessionManager(userPosition: rwp, qrId: qrId, scheme: scheme))
                            }
                            self.picker.reloadAllComponents()
                            UIApplication.shared.isIdleTimerDisabled = true
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
            changeFloorLabel.isHidden = true
            
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
            changeFloorLabel.isHidden = false
            changeFloorLabel.text = "Go to floor \(floor)"
            
        case .finish:
            arView.scene.anchors.removeAll()
            arrowAnchor = nil
            changeFloorLabel.isHidden = true
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
                    self.picker.reloadAllComponents()
                    self.isScanningQR = true
                }
            }
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

extension ARNavigationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return schemeSessionManager.value?.rooms.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return schemeSessionManager.value?.rooms[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let selectedRoomId = schemeSessionManager.value?.rooms[row]._id else {
            return
        }
        
        schemeSessionManager.value?.startRoute(to: selectedRoomId)
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
        
        apply(picker) {
            view.addSubview($0)
            $0.dataSource = self
            $0.delegate = self
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
        
        apply(debugLabel) {
            view.addSubview($0)
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.textColor = .gray
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: view.topAnchor, constant: 30.0).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15.0).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15.0).isActive = true
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
        
        apply(changeFloorLabel) {
            view.addSubview($0)
            $0.textAlignment = .center
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            $0.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            $0.textColor = .green
        }
        
        apply(exitButton) {
            view.addSubview($0)
            $0.setTitle("Back", for: .normal)
            $0.backgroundColor = .clear
            $0.setTitleColor(.blue, for: .normal)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10.0).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25.0).isActive = true
        }
    }
    
    private func setupBinds() {
        schemeSessionManager
            .flatMapLatest {
                return $0?.isStart ?? .just(false)
            }
            .bind { [weak self] isStart in
                self?.picker.isHidden = !isStart
            }
            .disposed(by: bag)
        
        exitButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: bag)
    }
}
