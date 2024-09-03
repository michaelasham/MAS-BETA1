//
//  GroupVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 03/09/2024.
//

import UIKit

class GroupVC: UIViewController, UITableViewDelegate, UITableViewDataSource {


    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var members = CommunityService.instance.selectedGroupMembers
    var newUsers = UserDataService.instance.newUsers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUsers), name: NOTIF_USER_REFRESH, object: nil)
        titleLbl.text = "\(CommunityService.instance.selectedGroup.name ?? "") Members"
    }
    
    @objc func refreshUsers() {
        members = CommunityService.instance.selectedGroupMembers
        newUsers = UserDataService.instance.newUsers
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell") as? GroupMemberCell {
            if segmentedControl.selectedSegmentIndex == 0 {
                //actual users
                let user = members[indexPath.row]
                cell.setupView(user: user,
                               top: user.phone,
                               bottom: user.dateOfBirth,
                               subtitle: "")
            } else {
                // awaiting approval
                let user = newUsers[indexPath.row]
                let formattedUser = UserDataService.instance.spoofUser(newUser: user)
                cell.setupView(user: formattedUser,
                               top: "",
                               bottom: user.dateOfBirth,
                               subtitle: user.phone)
            }
            return cell
        }
        return GroupMemberCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CommunityService.instance.selectedMember = members[indexPath.row]
        performSegue(withIdentifier: "toMemberVC", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            //actual users
            return members.count

        } else {
            // awaiting approval
            return newUsers.count
        }
    }

    @IBAction func onAddClick(_ sender: Any) {
        CommunityService.instance.selectedMember = User()
        performSegue(withIdentifier: "toMemberVC", sender: self)
    }
    
    @IBAction func onSegmentChange(_ sender: Any) {
        tableView.reloadData()
        tableView.isUserInteractionEnabled = segmentedControl.selectedSegmentIndex == 0
    }
    

}
