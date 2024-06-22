//
//  HostanEventVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 22/06/2024.
//

import UIKit
import Toast_Swift


class HostanEventVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var descLbl: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var proceedBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        field.delegate = self

        proceedBtn = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 60))
        proceedBtn.backgroundColor = .blue
        proceedBtn.setTitle("Submit", for: .normal)
        proceedBtn.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
        proceedBtn.addTarget(self, action: #selector(HostanEventVC.handleClick), for: .touchUpInside)
        proceedBtn.prepareForInterfaceBuilder()
        field.inputAccessoryView = proceedBtn
        let endEditingTap = UITapGestureRecognizer(target: self, action: #selector(LoginVC.handleEndEditingTap))
        view.addGestureRecognizer(endEditingTap)
        proceedBtn.isHidden = true
        setupView()
    }
    // HANDLES
    @objc func handleEndEditingTap() {
        UIView.animate(withDuration: 0.2) {
            self.view.endEditing(true)
            self.view.frame.origin.y = 0
        }
    }
    
    func setupView() {
        segmentedControl.setTitle("for \(CommunityService.instance.selectedGroup.name!)", forSegmentAt: 0)
        if segmentedControl.selectedSegmentIndex == 0 {
            descLbl.text = "Hosting an event (e.g. summer camp) on the MAS App is probably the smartest decision you are tsking for a seamless fund collection, registration and marketing process. No need for excel sheets and counting cash"
        } else {
            descLbl.text = "Your intention to host an event (e.g. a crash course) on the MAS App has been the fundamental motivator for building this app. Please use it to connect with others, teach the youth and enjoy life. If you think you have a skill that can be taught, we promise you, the youth are eager to learn."
        }
    }
    // UITextFieldDelegate method called every time the text field's text changes
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Your code here to handle the text change
        
        // Example: print the new text value
        if let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) {
            self.proceedBtn.isHidden = newText.count < 4
        }
        return true
    }
    @objc func handleClick() {
        view.endEditing(true)
        var type = "GROUP-DEDICATED"
        if segmentedControl.selectedSegmentIndex == 1 {
            type = "GROWTH-ORIENTED"
        }
        CommunityService.instance.postEventHostRequest(type: type,
                                                       desc: field.text!) { Success in
            let toastMsg = "Request submitted successfully! Expect a phone call shortly."
            var style = ToastStyle()
            style.messageAlignment = .center
            self.view.makeToast(toastMsg, duration: 3.0, position: .bottom, style: style)
            self.dismiss(animated: true)
            NotificationCenter.default.post(name: NOTIF_EVENT_CREATION_REQUEST, object: nil)
        }
    }
    @IBAction func onSegmentChange(_ sender: Any) {
        setupView()
    }
    

}
