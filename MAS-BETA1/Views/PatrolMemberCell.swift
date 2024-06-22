//
//  PatrolMemberCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//

import UIKit

class PatrolMemberCell: UITableViewCell, UIContextMenuInteractionDelegate {

    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    
    var user = User()
    var vc = PatrolSortingVC()
    var currentlyEditing = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [self] suggestedActions in
            // Create the action for the context menu
            
            if toggleSwitch.isOn && currentlyEditing {
                let firstActionButton = UIAction(title: "Assign as Chief", image: nil) { action in
                    vc.assignCertainRole(user: user, role: "chief")
                }
                let scndActionButton = UIAction(title: "Assign as Vice", image: nil) { action in
                    vc.assignCertainRole(user: user, role: "vice")
                }
                let thrdActionButton = UIAction(title: "Assign as Troisieme", image: nil) { action in
                    vc.assignCertainRole(user: user, role: "troisieme")
                }
                let frthActionButton = UIAction(title: "Assign as member", image: nil) { action in
                    vc.assignCertainRole(user: user, role: "member")
                }
                return UIMenu(title: "Manage Roles", children: [firstActionButton, scndActionButton, thrdActionButton, frthActionButton])

            }
            return UIMenu()

        }
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    func setupCell(name: String, subtitle: String, toggle: Bool, enabled: Bool) {
        toggleSwitch.isOn = toggle
        toggleSwitch.isEnabled = enabled
        nameLbl.text = name
        subtitleLbl.text = subtitle
    }
    
    @IBAction func onSwitchClick(_ sender: Any) {
        vc.toggleTriggered(user: user, value: toggleSwitch.isOn)
//        NotificationCenter.default.post(name: NOTIF_PATROL_MEMBER_UPDATE, object: nil)
    }
    
}
