//
//  PatrolSortingVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//

import UIKit

class PatrolSortingVC: UIViewController, UITableViewDelegate, UITableViewDataSource {


    @IBOutlet weak var actionBtn: BorderButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    var currentlyEditing = false
    var patrols = CommunityService.instance.selectedGroup.patrols
    var groupMembers = CommunityService.instance.selectedGroupMembers
    var selectedPatrol = Patrol()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        pickerView.delegate = self
        if CommunityService.instance.selectedGroup.patrols.count > 0 {
            selectedPatrol =  CommunityService.instance.selectedGroup.patrols[0]
        }
        CommunityService.instance.queryGroupMembers()
        groupMembers = CommunityService.instance.selectedGroupMembers
        setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePatrolMembers), name: NOTIF_PATROL_MEMBER_UPDATE, object: nil)
    }
    
    @objc func updatePatrolMembers() {
        selectedPatrol.members.removeAll()
        for i in 0..<groupMembers.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? PatrolMemberCell {
                if cell.toggleSwitch.isOn {
                    selectedPatrol.members.append(groupMembers[i])
                }
            }
        }
        for i in 0..<patrols!.count {
            if patrols![i].name == selectedPatrol.name {
                patrols![i] = selectedPatrol
                CommunityService.instance.selectedGroup.patrols = patrols
            }
        }
    }
    
    func toggleTriggered(user: User, value: Bool) {
        if value {
            selectedPatrol.members.append(user)
        } else {
            for i in 0..<selectedPatrol.members.count {
                if selectedPatrol.members[i].id == user.id {
                    selectedPatrol.members.remove(at: i)
                    break
                }
            }
        }
        for i in 0..<patrols!.count {
            if patrols![i].name == selectedPatrol.name {
                patrols![i] = selectedPatrol
                CommunityService.instance.selectedGroup.patrols = patrols
            }
        }
        
    }

    func setupView() {
        if currentlyEditing {
            actionBtn.setTitle("Close", for: .normal)
        } else {
            actionBtn.setTitle("Edit", for: .normal)
        }
        tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentlyEditing {
            return groupMembers.count
        } else {
            return (selectedPatrol.members ?? [User]()).count
        }
    }
    
    func assignCertainRole(user: User, role: String) {
        
        if selectedPatrol.chief.id == user.id {
            selectedPatrol.chief = User()
        }
        if selectedPatrol.vice.id == user.id {
            selectedPatrol.vice = User()
        }
        if selectedPatrol.troisieme.id == user.id {
            selectedPatrol.troisieme = User()
        }
        
        if role == "chief" {
            selectedPatrol.chief = user
        } else if role == "vice" {
            selectedPatrol.vice = user
        } else if role == "troisieme" {
            selectedPatrol.troisieme = user
        }
        for i in 0..<patrols!.count {
            if patrols![i].name == selectedPatrol.name {
                patrols![i] = selectedPatrol
                CommunityService.instance.selectedGroup.patrols[i] = self.selectedPatrol
            }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PatrolMemberCell") as? PatrolMemberCell {
            cell.vc = self
            cell.currentlyEditing = currentlyEditing
            if currentlyEditing {
                cell.user = groupMembers[indexPath.row]
                let member = groupMembers[indexPath.row]
                let userPatrol = CommunityService.instance.queryPatrol(user: member)
                var enabled = false
                var comment = ""
                var clearRole = false
                if userPatrol.name == selectedPatrol.name {
                    var role = "member"
                    let user = groupMembers[indexPath.row]
                    if selectedPatrol.chief.id == user.id! {
                        clearRole = false
                        role = "chief"
                    } else if selectedPatrol.vice.id == user.id! {
                        role = "vice"
                    } else if selectedPatrol.troisieme.id == user.id! {
                        role = "troisieme"
                    } else {
                        clearRole = true
                    }
                    comment = role
                } else {
                    comment = userPatrol.name ?? ""
                    clearRole = true
                }
                if userPatrol.name == selectedPatrol.name || userPatrol.name == nil {
                    enabled = true
                }

                cell.setupCell(name: member.name,
                               subtitle: comment,
                               toggle: userPatrol.name == selectedPatrol.name,
                               enabled: enabled && clearRole)
            } else {
                cell.user = selectedPatrol.members[indexPath.row]
                let user = selectedPatrol.members[indexPath.row]
                var role = "member"
                if selectedPatrol.chief.id == user.id {
                    role = "chief"
                } else if selectedPatrol.vice.id == user.id {
                    role = "vice"
                } else if selectedPatrol.troisieme.id == user.id {
                    role = "troisieme"
                }
                cell.setupCell(name: user.name, subtitle: role, toggle: true, enabled: false)
            }
            return cell
        }
        return PatrolMemberCell()
    }
    
    @IBAction func onSaveClick(_ sender: Any) {
        if currentlyEditing {
            // we want to save
            for patrol in patrols! {
                CommunityService.instance.updatePatrol(patrol: patrol)
            }
            dismiss(animated: true)
        } else {
            // start  editing
            currentlyEditing = true
            setupView()
        }
    }
    
}

extension PatrolSortingVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return patrols!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return patrols![row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPatrol = patrols![row]
        tableView.reloadData()
    }
    
}
