//
//  Badge.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation


struct Badge {
    public private(set) var id: String!
    public private(set) var name: String!
    public private(set) var desc: String!
    public private(set) var available: Bool!
    public private(set) var lastUpdated: String!
    public private(set) var prerequisites: Bool!
    public private(set) var prerequisiteBadges: [String]?
    public private(set) var members: [String]?
}
struct BadgeActivity {
    public private(set) var id: String!
    public private(set) var winner: User!
    public private(set) var badge: Badge!
    public private(set) var leader: User!
    public private(set) var timestamp: String!
    public private(set) var createdAt: String!
}
