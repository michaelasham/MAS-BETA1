//
//  LoginVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//


import UIKit

class LoginVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var resendBtn: UIButton!
    @IBOutlet weak var underscore: UIView!
    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var resendLbl: UILabel!
    
    var proceedBtn: UIButton!
    var stage = 0
    
    var futureDate = Date(timeIntervalSinceNow: 300)
    var countdown: DateComponents {
        return Calendar.current.dateComponents([.minute, .second], from: Date(), to: futureDate)
    }
    
    override func viewDidLoad() {
        field.delegate = self
        resendBtn.isHidden = true
        proceedBtn = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 60))
        proceedBtn.backgroundColor = .blue
        proceedBtn.setTitle("Continue", for: .normal)
        proceedBtn.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
        proceedBtn.addTarget(self, action: #selector(LoginVC.handleClick), for: .touchUpInside)
        proceedBtn.prepareForInterfaceBuilder()
        field.inputAccessoryView = proceedBtn
        let endEditingTap = UITapGestureRecognizer(target: self, action: #selector(LoginVC.handleEndEditingTap))
        view.addGestureRecognizer(endEditingTap)
        proceedBtn.isHidden = true
    }
    // HANDLES
    @objc func handleEndEditingTap() {
        UIView.animate(withDuration: 0.2) {
            self.view.endEditing(true)
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func updateTime() {
        if stage == 1 {
            let countdown = self.countdown //only compute once per call
            resendLbl.text = "Resend code in \(String(format: "%02d", countdown.minute!)):\(String(format: "%02d", countdown.second!))"
            if String(format: "%02d", countdown.minute!) == "00" && String(format: "%02d", countdown.second!) == "00" {
                resendBtn.isHidden = false
                resendLbl.isHidden = true
            }
        }
    }
    
    func runCountdown() {
        if stage == 1 {
            self.futureDate = Date(timeIntervalSinceNow: 300)
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        }
    }
    
    // UITextFieldDelegate method called every time the text field's text changes
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Your code here to handle the text change
            
            // Example: print the new text value
            if let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) {
                if stage == 0 {
                    proceedBtn.isHidden = newText.count != 11
                } else if stage == 1 {
                    proceedBtn.isHidden = newText.count != 6
                } else {
                    proceedBtn.isHidden = newText.count < 5
                }
            }
            
            // Return true to allow the text change, or false to prevent it
            return true
        }
    
    @objc func handleClick() {
        view.endEditing(true)
        //spinner
        if stage == 0 {
            AuthService.instance.verifyPhoneNumber(phoneNumber: "+2\(field.text!)") { (success) in
                if success {
                    self.stage = 1
                    self.runCountdown()
                    self.titleLbl.text = "Enter code"
                    self.resendLbl.text = "Please type in the verification code sent on your messages"
                    self.proceedBtn.setTitle("Submit", for: .normal)
                    self.field.placeholder = "6-digit code"
                    self.field.text = ""
                    self.proceedBtn.isHidden = true
                    self.underscore.layer.borderColor = #colorLiteral(red: 0.01819451898, green: 0.1114415303, blue: 0.5628897548, alpha: 1)
                }
            }
        } else if stage == 1 {
            AuthService.instance.submitVerificationCode(verificationCode: field.text!) { (success) in
                if success {
                    NotificationCenter.default.post(name: NOTIF_LOGIN_CHANGED, object: nil)
                    // get name
                    if UserDataService.instance.user.name == "" {
                        self.titleLbl.text = "Let us know your name"
                        self.resendLbl.text = "This action cannot be changed or undone in the future"
                        self.field.placeholder = "e.g. John Smith"
                        self.field.text = ""
                        self.proceedBtn.setTitle("Save", for: .normal)
                        self.stage = 2
                        self.resendBtn.isHidden = true
                        self.proceedBtn.isHidden = true
                        self.field.keyboardType = .default
                    } else {
                        self.performSegue(withIdentifier: "newToMainVC", sender: self)
                    }
                } else {
                    let animation = CABasicAnimation(keyPath: "position")
                    animation.duration = 0.07
                    animation.repeatCount = 4
                    animation.autoreverses = true
                    animation.fromValue = NSValue(cgPoint: CGPoint(x: self.underscore.center.x - 10, y: self.underscore.center.y))
                    animation.toValue = NSValue(cgPoint: CGPoint(x: self.underscore.center.x + 10, y: self.underscore.center.y))

                    self.underscore.layer.add(animation, forKey: "position")
                    self.underscore.layer.borderColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                    self.underscore.layer.borderWidth = 1
                    self.underscore.layer.cornerRadius = 5
                }
            }
        } else {
            //2
            UserDataService.instance.addUserName(name: field.text!) { Success in
                self.performSegue(withIdentifier: "newToMainVC", sender: self)
            }
        }
    }
    
    
    
    @IBAction func onResendClick(_ sender: Any) {
        // resend ver. code
        AuthService.instance.verifyPhoneNumber(phoneNumber: AuthService.instance.claimedPhoneNumber ?? "") { (success) in
            if success {
                self.runCountdown()
                self.resendLbl.isHidden = false
                self.resendBtn.isHidden = true
                self.titleLbl.text = "Enter code"
                self.resendLbl.text = "Please type in the verification code sent on your messages"
                self.proceedBtn.setTitle("Submit", for: .normal)
                self.field.placeholder = "6-digit code"
                self.field.text = ""
                self.stage = 1
            }
        }
        self.field.layer.borderWidth = 0
    }

    @IBAction func onNumberChange(_ sender: Any) {

    }
    
}
