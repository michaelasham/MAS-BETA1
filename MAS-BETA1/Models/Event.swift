//
//  Event.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation



struct Event {
    public private(set) var id: String
    public private(set) var title: String
    public private(set) var locationDesc: String
    public private(set) var locationLink: String
    public private(set) var desc: String
    public private(set) var badgeID: String
    public private(set) var groupID: String
    public private(set) var price: Int
    public private(set) var maxLimit: Int
    public private(set) var date: String
    
    // Empty initializer
    init() {
        self.id = ""
        self.title = ""
        self.locationDesc = ""
        self.locationLink = ""
        self.desc = ""
        self.badgeID = ""
        self.groupID = ""
        self.price = 0
        self.maxLimit = 0
        self.date = ""
    }
    
    // Memberwise initializer
    init(id: String, title: String, locationDesc: String, locationLink: String, desc: String, badgeID: String, groupID: String, price: Int, maxLimit: Int, date: String) {
        self.id = id
        self.title = title
        self.locationDesc = locationDesc
        self.locationLink = locationLink
        self.desc = desc
        self.badgeID = badgeID
        self.groupID = groupID
        self.price = price
        self.maxLimit = maxLimit
        self.date = date
    }
}


struct Ticket {
    public private(set) var event: Event
    public private(set) var userID: String
    public private(set) var timestamp: String
    public private(set) var trxID: String
    public private(set) var amount: Int
    
    // Empty initializer
    init() {
        self.event = Event()
        self.userID = ""
        self.timestamp = ""
        self.trxID = ""
        self.amount = 0
    }
    
    // Memberwise initializer
    init(event: Event, userID: String, timestamp: String, trxID: String, amount: Int) {
        self.event = event
        self.userID = userID
        self.timestamp = timestamp
        self.trxID = trxID
        self.amount = amount
    }
}
