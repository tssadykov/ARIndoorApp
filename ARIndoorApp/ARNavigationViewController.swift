//
//  ViewController.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 1/18/21.
//

import UIKit
import ARKit
import RealityKit

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
    }

    private let arView = ARView()
    private let picker = UIPickerView()
    
    private var isScanningQR: Bool = true
    private let deps: ARNavigationViewControllerDeps
    
    private var arrowAnchor: AnchorEntity?
    private lazy var inArrow = try! Entity.load(named: "NavigationArrow")
    private var schemeSessionManager: SchemeSessionManager?
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
                            self.schemeSessionManager = SchemeSessionManager(userPosition: rwp, qrId: qrId, scheme: scheme)
                        }
                    }
                case .none:
                    return
                }
            }
        }
        
        let sessionState = schemeSessionManager?.applyRealWorldPosition(frame.camera.realWorldPosition)
        
        arView.scene.anchors.removeAll()
        
        switch sessionState {
        case .direction(let direction):
            let cameraTransform = frame.camera.transform
            var matrixTransform = matrix_identity_float4x4
            matrixTransform[3][0] = cameraTransform[3][0]
            matrixTransform[3][1] = cameraTransform[3][1] + 0.3
            matrixTransform[3][2] = cameraTransform[3][2] + 0.3
//            matrixTransform = Math.rotateAroundZ(matrix: matrixTransform, angle: .pi)
//            matrixTransform = Math.rotateAroundX(matrix: matrixTransform, angle: .pi)
//            matrixTransform = Math.rotateAroundY(matrix: matrixTransform, angle: .pi)
            
            var inArrow = try! Entity.load(named: "NavigationArrow")
            let anchorEntity = AnchorEntity(world: matrixTransform)
            anchorEntity.addChild(inArrow)
        
            arView.scene.addAnchor(anchorEntity)
            self.arrowAnchor = anchorEntity
            
//            if arrowAnchor == nil {
//                let inArrow = try! NavigationArrow.loadInArrow()
//                let anchorEntity = AnchorEntity(world: matrixTransform)
//                anchorEntity.addChild(inArrow)
//                arView.scene.addAnchor(anchorEntity)
//                self.arrowAnchor = anchorEntity
//            } else {
//                arrowAnchor?.reanchor(.world(transform: matrixTransform), preservingWorldTransform: false)
//            }
            
            
        case .finish, .none:
            arView.scene.anchors.forEach { arView.scene.removeAnchor($0) }
        }
    }
}

extension ARNavigationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return schemeSessionManager?.scheme.floors?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return schemeSessionManager?.scheme.floors?[component].rooms?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return schemeSessionManager?.scheme.floors?[component].rooms?[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let selectedRoomId = schemeSessionManager?.scheme.floors?[component].rooms?[row]._id else {
            return
        }
        
        schemeSessionManager?.startRoute(to: selectedRoomId)
    }
}

private extension ARCamera {
    
    var realWorldPosition: RealWorldPosition {
        return RealWorldPosition(x: transform[3][0], y: transform[3][1], z: transform[3][2], direction: eulerAngles.z)
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
            configuration.worldAlignment = .gravityAndHeading
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
    }
}
