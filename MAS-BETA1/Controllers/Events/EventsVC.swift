//
//  EventsVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit

class EventsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var curtainView: UIView!
    @IBOutlet weak var ticketsBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    let events = CommunityService.instance.events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupView()
    }
    
    func setupView() {
        ticketsBtn.isHidden = CommunityService.instance.tickets.count == 0
//        ticketsBtn.setTitle("TICKETS (\(CommunityService.instance.tickets.count))", for: .normal)
        curtainView.isHidden = AuthService.instance.isLoggedIn
        // events available only for people in a community
        curtainView.isHidden = CommunityService.instance.events.count != 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell") as? EventCell {
            cell.setupCell(event: events[indexPath.row])
            return cell
        }
        return EventCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CommunityService.instance.selectedEvent = events[indexPath.row]
        performSegue(withIdentifier: "toEventVC", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    @IBAction func onTicketsClick(_ sender: Any) {
        performSegue(withIdentifier: "toTicketsVC", sender: self)
    }
    



}
