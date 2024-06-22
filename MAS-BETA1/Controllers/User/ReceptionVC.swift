//
//  ReceptionVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit

class ReceptionVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func onLoginClick(_ sender: Any) {
        performSegue(withIdentifier: "receptionToLoginVC", sender: self)
    }
    
    @IBAction func onLibraryClick(_ sender: Any) {
        performSegue(withIdentifier: "", sender: self)
    }
    
}
