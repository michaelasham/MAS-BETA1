//
//  User.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation

struct User {
    public private(set) var id: String!
    public private(set) var score: Int!
    public private(set) var name: String!
    public private(set) var dateOfBirth: String!
    public private(set) var phone: String!
    public private(set) var dash: Int!
    public private(set) var gender: String!

    public private(set) var comments: [Comment]?

    public private(set) var createdAt: String!
    public private(set) var lastUpdated: String!
}

struct NewUser {
    public private(set) var name: String!
    public private(set) var dateOfBirth: String!
    public private(set) var phone: String!
    public private(set) var gender: String!
    public private(set) var group: String!
    public private(set) var referrer: String!
    public private(set) var timestamp: String!

}

struct Comment {
    public private(set) var id: String!
    public private(set) var sender: String!
    public private(set) var message: String!
    public private(set) var timestamp: String!
}

struct Group {
    public private(set) var id: String!
    public private(set) var name: String!
    public private(set) var gender: String!
    public private(set) var dashes: [Int]!
    public private(set) var leaders: [User]!
    public private(set) var meetings: [Meeting]?
    public private(set) var ledgerLines: [LedgerLine]?
    public var patrols: [Patrol]!
    public private(set) var createdAt: String!
    public private(set) var lastUpdated: String!
    
}

struct LedgerLine {
    public private(set) var id: String!
    public private(set) var patrol: String!
    public private(set) var amount: Int!
    public private(set) var reason: String!
    public private(set) var timestamp: String!
}

struct Patrol {
    public private(set) var name: String!
    public var chief: User!
    public var vice: User!
    public var troisieme: User!
    public var members: [User]!
    public var score: Int!

    public private(set) var createdAt: String!
    public private(set) var lastUpdated: String!
}

struct Meeting {
    public private(set) var id: String!
    public private(set) var openTime: String!
    public var closeTime: String?
    public private(set) var hostID: String!
    public var collectingAttendance: String?
    public var gameOpenTime: String?
    public var gameCloseTime: String?
    public var gameHost: String?
    public var gameTitle: String?
    public var gamePoints: Int?
    public var gameWinner: String?
    public var attendances: [String: String]
    
    // Empty initializer
    init() {
        self.id = ""
        self.openTime = ""
        self.closeTime = nil
        self.hostID = ""
        self.collectingAttendance = nil
        self.gameOpenTime = nil
        self.gameCloseTime = nil
        self.gameHost = nil
        self.gameTitle = nil
        self.gamePoints = nil
        self.gameWinner = nil
        self.attendances = [:]
    }
    // Full initializer
    init(id: String, openTime: String, closeTime: String? = nil, hostID: String, collectingAttendance: String? = nil, gameOpenTime: String? = nil, gameCloseTime: String? = nil, gameHost: String? = nil, gameTitle: String? = nil, gamePoints: Int? = nil, gameWinner: String? = nil, attendances: [String: String] = [:]) {
        self.id = id
        self.openTime = openTime
        self.closeTime = closeTime
        self.hostID = hostID
        self.collectingAttendance = collectingAttendance
        self.gameOpenTime = gameOpenTime
        self.gameCloseTime = gameCloseTime
        self.gameHost = gameHost
        self.gameTitle = gameTitle
        self.gamePoints = gamePoints
        self.gameWinner = gameWinner
        self.attendances = attendances
    }
}

