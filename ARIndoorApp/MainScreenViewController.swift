//
//  MainScreenViewController.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 2/6/21.
//

import UIKit
import AVFoundation

final class MainScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { _ in })
        apply(navigationButton) {
            view.addSubview($0)
            $0.setTitle("Navigate", for: .normal)
            $0.setTitleColor(.black, for: .normal)
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            $0.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150.0).isActive = true
            
            $0.addTarget(self, action: #selector(onNavigationButton(_:)), for: .touchUpInside)
        }
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @objc
    private func onNavigationButton(_ sender: UIButton) {
        let arNavigationVC = ARNavigationViewController(deps: deps)
        navigationController?.pushViewController(arNavigationVC, animated: true)
    }
    
    // MARK: - Private properties
    
    private let navigationButton = UIButton()
    private let deps = ApplicationDeps()
}

final class ApplicationDeps: ARNavigationViewControllerDeps {
    
    lazy var urlPerformer: URLPerformer = URLPerformerImpl()
    
    lazy var qrCodeReader: QRCodeReader = QRCodeReaderImpl()
    
    lazy var buildingSchemeService: BuildingSchemeService = BuildingSchemeServiceImpl()
}
