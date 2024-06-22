//
//  BadgeService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class BadgeService {
    
    static let instance = BadgeService()
    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var badges = [Badge]()
    var badgeActivities = [BadgeActivity]()
    var availableLeaders = [User]()

    
    func pullBadges(completion: @escaping CompletionHandler) {
        self.badges.removeAll()
        ref.child("badges").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? NSDictionary else { return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary
                guard let badge = Badge(id: id as! String,
                                        name: subvalue!.value(forKey: "name") as? String,
                                        desc: subvalue!.value(forKey: "desc") as? String,
                                        available:  subvalue!.value(forKey: "available") as? Bool,
                                        lastUpdated: subvalue!.value(forKey: "lastUpdated") as? String,
                                        prerequisites:  subvalue!.value(forKey: "prerequisites") as? Bool,
                                        prerequisiteBadges:  subvalue!.value(forKey: "prerequisiteBadges") as? [String] ?? [String](),
                                        members:  subvalue!.value(forKey: "members") as? [String] ?? [String]()) as? Badge else { return }
                self.badges.append(badge)
            }
            completion(true)
        }
    }
    
    func pullBadgeActivities(completion: @escaping CompletionHandler) {
        badgeActivities.removeAll()
        ref.child("badgeActivity").getData { Error, snapshot in
            guard let value = snapshot?.value as? NSDictionary else { completion(false); return }
//            self.queryLeaders()
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary
                var wonBadge = Badge()
                var moderatingLeader = User()
                let winner = subvalue!.value(forKey: "winner") as! String
                if UserDataService.instance.user.id == winner {
                    for badge in self.badges {
                        if badge.id == subvalue!.value(forKey: "badge") as! String {
                            wonBadge = badge
                        }
                    }
                    for leader in self.availableLeaders {
                        if leader.id == subvalue!.value(forKey: "leader") as! String {
                            moderatingLeader = leader
                        }
                    }
                    
                    let badgeActivity = BadgeActivity(id: id as! String,
                                                      winner: UserDataService.instance.user,
                                                      badge: wonBadge,
                                                      leader: moderatingLeader,
                                                      timestamp: subvalue?.value(forKey: "timestamp") as! String,
                                                      createdAt: subvalue?.value(forKey: "createdAt") as! String)
                    self.badgeActivities.append(badgeActivity)
                }
            }
            completion(true)
        }
    }
    func userHasThisBadge(badgeID: String) -> Bool {
        var flag = false
        for activity in badgeActivities {
            if activity.badge.id == badgeID {
                flag = true
            }
        }
        return flag
    }
    
    func queryUserBadgeActivities(user: User) -> [BadgeActivity] {
        return badgeActivities.filter { $0.winner.id == user.id }
    }

    func queryUserMostSignificantBadgeActivity(user: User) -> BadgeActivity {
        var filteredBadgeActivities = badgeActivities.filter { $0.winner.id == user.id }
        var badgeCounts = [String: Int]()
        
        for activity in filteredBadgeActivities {
            let badgeID = activity.badge.id
            badgeCounts[badgeID!, default: 0] += 1
        }
        
        // Find the badge ID with the lowest occurrence
        guard let minBadge = badgeCounts.min(by: { $0.value < $1.value }) else {
            return BadgeActivity()
        }
        
        // Find the first BadgeActivity with the lowest occurrence badge ID
        return filteredBadgeActivities.first { $0.badge.id == minBadge.key }!
    }
    
    func queryBadge(id: String) -> Badge {
        return badges.filter { $0.id == id }[0]
    }
}
