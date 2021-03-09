//
//  UIViewController+Extensions.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/6/21.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String, description: String?) {
        let ac = UIAlertController(title: title, message: description, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
