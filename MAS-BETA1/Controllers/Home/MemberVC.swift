//
//  MemberVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 03/09/2024.
//

import UIKit

class MemberVC: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var uploadBtn: BorderButton!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var actionCommentLbl: UILabel!
    
    let member = CommunityService.instance.selectedMember
    var currentlyEditing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentlyEditing = member.id == nil
        setupView()

    }
    
    func setupView() {
        if currentlyEditing {
            uploadBtn.setTitle("Save", for: .normal)
            
        } else {
            uploadBtn.setTitle("Edit", for: .normal)
            
        }
        genderSegmentedControl.isEnabled = currentlyEditing
        nameField.isEnabled = currentlyEditing
        phoneField.isEnabled = currentlyEditing
        dateOfBirthPicker.isUserInteractionEnabled = currentlyEditing
        
        if member.id != "" {
            actionCommentLbl.isHidden = true
            nameField.text = member.name
            phoneField.text = member.phone
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yy"
            
            if let date = dateFormatter.date(from: member.dateOfBirth ?? "") {
                dateOfBirthPicker.setDate(date, animated: true)
            }
            if member.gender == "Male" {
                genderSegmentedControl.selectedSegmentIndex = 0
            } else {
                genderSegmentedControl.selectedSegmentIndex = 1
            }
        }
        let group = CommunityService.instance.selectedGroup
        print(group.gender)
        genderSegmentedControl.isEnabled = false
        if group.gender == "Males" {
            genderSegmentedControl.selectedSegmentIndex = 0
        } else if group.gender == "Females" {
            genderSegmentedControl.selectedSegmentIndex = 1
        } else if group.gender == "Both" {
            genderSegmentedControl.isEnabled = true
        }
    }

    @IBAction func onUploadClick(_ sender: Any) {
        if currentlyEditing {
            let dateFormatter : DateFormatter = DateFormatter()

            let genderArray = ["Male", "Female"]
            dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            
            let anotherFormatter = DateFormatter()
            anotherFormatter.dateFormat = "M/d/yy"
            if member.id == nil {
                //new member request
                let user = User(id: "",
                                score: 0,
                                name: nameField.text!,
                                dateOfBirth: anotherFormatter.string(from: dateOfBirthPicker.date),
                                phone: phoneField.text!,
                                dash: 10000,
                                gender: genderArray[genderSegmentedControl.selectedSegmentIndex],
                                createdAt: "",
                                lastUpdated: dateString
                )
                UserDataService.instance.addNewUser(user: user) { success in
                    UserDataService.instance.pullNewUsers { Success in
                        NotificationCenter.default.post(name: NOTIF_USER_REFRESH, object: nil)
                        self.dismiss(animated: true)
                    }
                }
            } else {
                //data modification
                let user = User(id: member.id,
                                score: member.score,
                                name: nameField.text!,
                                dateOfBirth: anotherFormatter.string(from: dateOfBirthPicker.date),
                                phone: phoneField.text!,
                                dash: member.dash,
                                gender: genderArray[genderSegmentedControl.selectedSegmentIndex],
                                createdAt: member.createdAt,
                                lastUpdated: dateString
                )
                UserDataService.instance.updateUserData(user: user) { success in
                    CommunityService.instance.pullUsers { Success in
                        NotificationCenter.default.post(name: NOTIF_USER_REFRESH, object: nil)
                        self.dismiss(animated: true)
                    }
                }
            }
            
        } else {
            currentlyEditing = true
            setupView()
        }

    }
    
}
