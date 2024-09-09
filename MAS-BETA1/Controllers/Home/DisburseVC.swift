//
//  DisburseVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 09/09/2024.
//

import UIKit

class DisburseVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var reasonField: UITextField!
    @IBOutlet weak var amountField: UITextField!
    
    
    var proceedBtn: UIButton!

    let patrols = CommunityService.instance.patrols
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        proceedBtn = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 60))
        proceedBtn.backgroundColor = .blue
        proceedBtn.setTitle("Continue", for: .normal)
        proceedBtn.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
        proceedBtn.addTarget(self, action: #selector(DisburseVC.handleClick), for: .touchUpInside)
        proceedBtn.prepareForInterfaceBuilder()
        reasonField.inputAccessoryView = proceedBtn
        amountField.inputAccessoryView = proceedBtn
        let endEditingTap = UITapGestureRecognizer(target: self, action: #selector(DisburseVC.handleEndEditingTap))
        view.addGestureRecognizer(endEditingTap)
    }
    
    @objc func handleClick() {
        view.endEditing(true)
        let patrol = patrols[pickerView.selectedRow(inComponent: 0)]
        CommunityService.instance.disburseManually(amount: Int(amountField.text!)!, reason: reasonField.text!, patrol: patrol)
        dismiss(animated: true)
    }
    
    @objc func handleEndEditingTap() {
        UIView.animate(withDuration: 0.2) {
            self.view.endEditing(true)
            self.view.frame.origin.y = 0
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return patrols.count
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return patrols[row].name
    }


}
