//
//  UpcomingEventCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 22/06/2024.
//

import UIKit

class UpcomingEventCell: UITableViewCell {

    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        
    }

    func setupCell(event: Event) {
        nameLbl.text = event.title
        subtitleLbl.text = "\(event.date)"
        if event.groupID != "" {
            let group = CommunityService.instance.queryGroup(id: event.groupID)
            subtitleLbl.text = "\(group.name!) Exclusive - \(event.date)"
        }
        if event.badgeID != "" {
            let badge = BadgeService.instance.queryBadge(id: event.badgeID)
            subtitleLbl.text = "\(badge.name!) Exclusive - \(event.date)"
        }
        let amountOfTickets = CommunityService.instance.countEventTickets(event: event)
        
        if CommunityService.instance.isUserGoing(event: event, user: UserDataService.instance.user) {
            statusLbl.text = "Already going"
        } else if (event.maxLimit - amountOfTickets) < 10 {
            statusLbl.text = "\(event.maxLimit - amountOfTickets) Spots left"
        } else if (event.maxLimit - amountOfTickets) < 2 {
            statusLbl.text = "\(event.maxLimit - amountOfTickets) Spot left"
        } else if (event.maxLimit - amountOfTickets) < 1 {
            statusLbl.text = "Sold out"
        }
    }

}
