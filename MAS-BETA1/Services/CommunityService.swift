//
//  CommunityService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class CommunityService {
    
    static let instance = CommunityService()
    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    

    var users = [User]()
    var events = [Event]()
    var tickets = [Ticket]()
    var patrols = [Patrol]()
    
    var selectedEvent = Event()
    var selectedTicket = Ticket()
    var selectedGroup = Group()
    var selectedGroupMembers = [User]()
    var selectedMember = User()
    var groups = [Group]()
    var chosenMode = ""
    var STMode = ""
    var attendanceMode = ""
    var requestedAnEvent = false
    var openMeeting = Meeting()
    var meetings = [Meeting]()
    
    var sliderScores = 0
    
    func didMemberClockInBefore(user: User) -> Bool {
        var flag = false
        for attendance in openMeeting.attendances {
            if attendance.key == user.id {
                flag = true
            }
        }
        return flag
    }
    
    
    func pullEventRequestStatus(completion: @escaping CompletionHandler) {
        ref.child("eventRequests").getData { error, snapshot in
            guard let value = snapshot?.value as? NSDictionary else { 
                completion(false)
                return }
            for key in value.allKeys {
                let subvalue = value.value(forKey: key as! String) as? NSDictionary
                if subvalue!.value(forKey: "userID") as! String == UserDataService.instance.user.id {
                    self.requestedAnEvent = true
                }
            }
            completion(true)
        }
    }
    
    func isDateToday(dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        
        if let date = dateFormatter.date(from: dateString) {
            return Calendar.current.isDateInToday(date)
        }
        
        return false
    }
    
    func countAbsences(user: User) -> Int {
        let group = queryGroup(user: user)
        let meetings = group.meetings ?? [Meeting]()
        var attendances = 0
        for meeting in meetings {
            if meeting.attendances.filter { $0.key == user.id}.count > 0 {
                attendances += 1
            }
        }
        return meetings.count - attendances
    }
    
    func queryHostingEvent() -> Event {
        var foundEvent = Event()
        for event in events {
            let group = CommunityService.instance.checkIfUserIsLeader()
            if event.hostID == UserDataService.instance.user.id || event.groupID == group.id {
                foundEvent = event
            }
        }
        return foundEvent
    }
    
    func queryGroup(user: User) -> Group {
        for group in groups {
            if (group.gender == user.gender || group.gender == "Both") && group.dashes.contains(user.dash ?? 10000) {
                return group
            }
        }
        return Group()
    }
    
    func queryGroup(id: String) -> Group {
        return groups.filter { $0.id == id }[0]
    }
    
    func queryPatrol(user: User) -> Patrol {
        for patrol in selectedGroup.patrols {
            for member in patrol.members {
                if member.id == user.id {
                    return patrol
                }
            }
        }
        return Patrol()
    }
    
    func groupStillNeedsSorting(group: Group) -> Bool {
        var members = [User]()
        if let patrols = group.patrols {
            for patrol in group.patrols {
                for aMember in patrol.members {
                    members.append(aMember)
                }
            }
        }

        return members.count < selectedGroupMembers.count
    }
    

    
    func pullGroups(completion: @escaping CompletionHandler) {
        groups.removeAll()
        ref.child("groups").getData { error, snapshot in
            guard let value = snapshot?.value as? NSDictionary else { 
                completion(false)
                return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary

                //leaders
                var leaders = [User]()
                if let leadersDict = subvalue!.value(forKey: "leaders") as? NSArray {
                    for leaderItem in leadersDict {
                        for user in self.users {
                            if user.id == leaderItem as? String {
                                leaders.append(user)
                            }
                        }
                    }
                }

                var patrols = [Patrol]()
                if let patrolsDict = subvalue!.value(forKey: "patrols") as? NSDictionary {
                    for patrol in patrolsDict.allKeys {
                        let name = patrol as! String
                        let subvalue = patrolsDict.value(forKey: patrol as! String) as? NSDictionary ?? NSDictionary()
                        let chiefID = subvalue.value(forKey: "chief") as? String ?? ""
                        let viceID = subvalue.value(forKey: "vice") as? String ?? ""
                        let troisiemeID = subvalue.value(forKey: "troisieme") as? String ?? ""
//                        let score = subvalue.value(forKey: "score") as? Int ?? 0
                        
                        var chief = User()
                        var vice = User()
                        var troisieme = User()
                        var members = [User]()
                        if let membersDict = subvalue.value(forKey: "members") as? NSArray {
                            for memberItem in membersDict {
                                for member in self.users {
                                    if member.id == memberItem as? String {
                                        members.append(member)
                                    }
                                    if member.id == chiefID {
                                        chief = member
                                    } else if member.id == viceID {
                                        vice = member
                                    } else if member.id == troisiemeID {
                                        troisieme = member
                                    }
                                }
                            }
                        }
                        let newPatrol = Patrol(name: name,
                                               chief: chief,
                                               vice: vice,
                                               troisieme: troisieme,
                                               members: members,
                                               score: 0,
                                               createdAt: "",
                                               lastUpdated: "")
                        patrols.append(newPatrol)
                        
                    }
                }
                // patrol point book
                var lines = [LedgerLine]()
                if let linesDict = subvalue!.value(forKey: "patrolPointBook") as? NSDictionary {
                    for line in linesDict.allKeys {
                        let id = line as! String
                        let subvalue = linesDict.value(forKey: line as! String) as? NSDictionary ?? NSDictionary()
                        let amount = subvalue.value(forKey: "amount") as? Int ?? 0
                        let reason = subvalue.value(forKey: "reason") as? String ?? ""
                        let timestamp = subvalue.value(forKey: "timestamp") as? String ?? ""
                        let patrol = subvalue.value(forKey: "patrol") as? String ?? ""
                        let formattedLine = LedgerLine(id: id,
                                                       patrol: patrol,
                                                       amount: amount,
                                                       reason: reason,
                                                       timestamp: timestamp)
                        lines.append(formattedLine)
                    }
                }
                //group assembly
                let group = Group(id: id as? String,
                                  name: subvalue?.value(forKey: "name") as? String,
                                  gender: subvalue?.value(forKey: "gender") as? String,
                                  dashes: subvalue?.value(forKey: "dashes") as? [Int] ?? [Int](),
                                  leaders: leaders,
                                  ledgerLines: lines,
                                  patrols: patrols,
                                  createdAt: subvalue?.value(forKey: "createdAt") as? String ?? String(),
                                  lastUpdated: subvalue?.value(forKey: "lastUpdated") as? String ?? String()
                )
                self.groups.append(group)
            }
            self.calculatePatrolScores()
            completion(true)
        }
    }
    
    func calculatePatrolScores() {
        for i in 0..<patrols.count {
            var score = 0
            for line in selectedGroup.ledgerLines! {
                if line.patrol == patrols[i].name {
                    score += line.amount
                }
            }
            patrols[i].score = max(0,score)
        }
    }
    
    func updatePatrol(patrol: Patrol) {
        var membersArray = [String]()
        for member in patrol.members {
            if member.id.count > 0 {
                membersArray.append(member.id)
            }
        }
        var chiefID = ""
        var viceID = ""
        var troisiemeID = ""
        if let chief = patrol.chief {
            if let id = chief.id {
                chiefID = id
            }
        }
        if let vice = patrol.vice {
            if let id = vice.id {
                viceID = id
            }
        }
        if let troisieme = patrol.troisieme {
            if let id = troisieme.id {
                troisiemeID = id
            }
        }
        if patrol.name.count > 0 {
            print("selectedGroup.id! \(selectedGroup.id!)")
            ref.child("groups").child(selectedGroup.id!).child("patrols").child(patrol.name).updateChildValues([
                "members" : membersArray,
                "chief": chiefID,
                "vice": viceID,
                "troisieme": troisiemeID
            ])
        }
    }
    
    func checkIfUserIsLeader() -> Group {
        var foundGroup = Group()
        for group in groups {
            for leader in group.leaders {
                if leader.id == UserDataService.instance.user.id {
                    foundGroup = group
                }
            }
        }
        selectedGroup = foundGroup
        return foundGroup
    }
    
    func queryGroupMembers() {
        selectedGroupMembers.removeAll()
        if let dashes = selectedGroup.dashes {
            for user in users {
                if selectedGroup.dashes.contains(user.dash) && (selectedGroup.gender == "Both" || selectedGroup.gender.first == user.gender.first) {
                    selectedGroupMembers.append(user)
                }
            }
        }
    }
    
    func checkMemberAvailability(user: User) -> Bool {
        var flag = true
        for patrol in patrols {
            for member in patrol.members {
                if member.id == user.id {
                    flag = false
                    break
                }
            }
        }
        return flag
    }
    func checkMemberBelonging(user: User) -> Bool {
        var flag = false
        for patrol in patrols {
            if patrol.members != nil {
                for member in patrol.members {
                    if member.id == user.id {
                        flag = true
                        break
                    }
                }
            }
        }
        return flag
    }
    
    func queryEventTickets(event: Event) -> [Ticket] {
        return tickets.filter { $0.event.id == event.id}
    }
    
    func purchaseTicket(trxID: String, completion: @escaping CompletionHandler) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
        ref.child("tickets").childByAutoId().setValue([
            "event": selectedEvent.id,
            "user": UserDataService.instance.user.id,
            "timestamp": dateStr,
            "amount": selectedEvent.price,
            "trxID": trxID
        ])
        completion(true)
    }
    
    func pullTickets(completion: @escaping CompletionHandler) {
        ref.child("tickets").getData { error, snapshot in
            self.tickets.removeAll()
            guard let value = snapshot?.value as? NSDictionary else {
                completion(false)
                return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary
                let eventID = subvalue?.value(forKey: "event") as! String
                let scanned = subvalue?.value(forKey: "scanned") as? String ?? ""
                let userID = subvalue?.value(forKey: "user") as! String
                let timestamp = subvalue?.value(forKey: "timestamp") as! String
                let trxID = subvalue?.value(forKey: "trxID") as! String
                let amount = subvalue?.value(forKey: "amount") as! Int
                var user = User()
                var event = Event()
                //query event
                if let foundEvent = self.events.first(where: { $0.id == eventID }) {
                    event = foundEvent
                }

                let ticket = Ticket(id: id as! String,
                                    scanned: scanned,
                                    event: event,
                                    userID: userID,
                                    timestamp: timestamp,
                                    trxID: trxID,
                                    amount: amount)
                if user.id == UserDataService.instance.user.id {
                    self.tickets.append(ticket)
                }
            }
            completion(true)
        }
    }
    
//    struct User {
//        public private(set) var id: String!
//        public private(set) var name: String!
//        public private(set) var dateOfBirth: String!
//        public private(set) var phone: String!
//        public private(set) var dash: Int!
//        public private(set) var gender: String!
//
//        public private(set) var comments: [Comment]?
//
//        public private(set) var createdAt: String!
//        public private(set) var lastUpdated: String!
//    }
    func pullUsers(completion: @escaping CompletionHandler) {
        ref.child("users").getData { error, snapshot in
            self.users.removeAll()
            guard let value = snapshot?.value as? NSDictionary else {
                completion(false)
                return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary ?? NSDictionary()
                let name = subvalue.value(forKey: "name") as? String ?? ""
                var phone = subvalue.value(forKey: "mobile") as? String ?? ""

                // Check if the phone number doesn't start with "0"
                if !phone.hasPrefix("0") && !phone.isEmpty {
                    phone = "0" + phone
                }
                let email = subvalue.value(forKey: "email") as? String ?? ""
                let score = subvalue.value(forKey: "score") as? Int ?? 0
                let createdAt = subvalue.value(forKey: "createdAt") as? String ?? ""
                let gender = subvalue.value(forKey: "gender") as? String ?? ""
                let dateOfBirth = subvalue.value(forKey: "dateOfBirth") as? String ?? ""
                let dash = subvalue.value(forKey: "dash") as? Int ?? 0
                let FCM = subvalue.value(forKey: "FCM") as? String ?? ""
                var comments = [Comment]()
                let commentsDict = subvalue.value(forKey: "comments") as? NSDictionary ?? NSDictionary()
                for commentID in commentsDict.allKeys {
                    guard let subsubvalue = commentsDict.value(forKey: commentID as! String) as? NSDictionary else { return }
                    let newComment = Comment(id: commentID as! String,
                                             sender: subsubvalue.value(forKey: "sender") as! String,
                                             message: subsubvalue.value(forKey: "message") as! String,
                                             timestamp: subsubvalue.value(forKey: "timestamp") as! String)
                    comments.append(newComment)
                }
                
                let user = User(id: id as! String,
                                score: score,
                                 name: name,
                                 dateOfBirth: dateOfBirth,
                                 phone: phone,
                                 dash: dash,
                                 gender: gender,
                                 FCM: FCM,
                                 comments: comments,
                                 createdAt: createdAt)
                self.users.append(user)
            }
            completion(true)
        }
    }
    
    
    func pullEvents(completion: @escaping CompletionHandler) {
        ref.child("events").getData { error, snapshot in
            self.events.removeAll()
            guard let value = snapshot?.value as? NSDictionary else {
                completion(false)
                return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary
                let title = subvalue?.value(forKey: "title") as! String
                let locationDesc = subvalue?.value(forKey: "locationDesc") as! String
                let locationLink = subvalue?.value(forKey: "locationLink") as! String
                let desc = subvalue?.value(forKey: "desc") as! String
                let badgeID = subvalue?.value(forKey: "badgeID") as! String
                let groupID = subvalue?.value(forKey: "groupID") as! String
                let hostID = subvalue?.value(forKey: "hostID") as? String ?? ""
                let price = subvalue?.value(forKey: "price") as! Int
                let maxLimit = subvalue?.value(forKey: "maxLimit") as! Int

                let date = subvalue?.value(forKey: "date") as! String

                let event = Event(id: id as! String,
                                  title: title,
                                  locationDesc: locationDesc,
                                  locationLink: locationLink,
                                  desc: desc,
                                  badgeID: badgeID,
                                  groupID: groupID,
                                  hostID: hostID,
                                  price: price,
                                  maxLimit: maxLimit,

                                  date: date)
                self.events.append(event)
            }
//            self.filterEvents()
            completion(true)
        }
    }
    //to be altered
    func filterEvents() {
        for i in 0..<events.count {
            let event = events[i]
            if !(event.groupID == "" || event.groupID == self.queryGroup(user: UserDataService.instance.user).id) && (event.badgeID == "" || BadgeService.instance.userHasThisBadge(badgeID: event.badgeID)) {
                events.remove(at: i)
            }
        }
    }
    
    func countEventTickets(event: Event) -> Int {
        let filteredTickets = tickets.filter { $0.event.id == event.id }
        return filteredTickets.count
    }
    
    func isUserGoing(event: Event, user: User) -> Bool{
        let filteredTickets = tickets.filter { $0.event.id == event.id }
        let personalizedTickets = filteredTickets.filter { $0.userID == user.id }
        return personalizedTickets.count > 0
    }
    
    
    func postEventHostRequest(type: String, desc: String, completion: @escaping CompletionHandler) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
                
        ref.child("eventRequests").childByAutoId().updateChildValues([
            "timestamp": dateStr,
            "type": type,
            "desc": desc,
            "userID": UserDataService.instance.user.id!
        ])
        self.requestedAnEvent = true
        completion(true)
    }
    
    func startMeeting(completion: @escaping CompletionHandler) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
        
        let key = ref.child("groups").child(selectedGroup.id).child("meetings").childByAutoId().key as! String
        
        ref.child("groups").child(selectedGroup.id).child("meetings").child(key).updateChildValues([
            "openTime": dateStr,
            "host": UserDataService.instance.user.id
        ])
        let meeting = Meeting(id: key, openTime: dateStr, hostID: UserDataService.instance.user.id)
        meetings.append(meeting)
        openMeeting = meeting
        completion(true)
    }
    
    func endMeeting(completion: @escaping CompletionHandler) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
        // check if i am host first
        ref.child("groups").child(selectedGroup.id).child("meetings").child(openMeeting.id).updateChildValues([
            "closeTime": dateStr
        ])
        openMeeting.closeTime = dateStr
        for i in 0..<meetings.count {
            if openMeeting.id == meetings[i].id {
                meetings[i].closeTime = openMeeting.closeTime
            }
        }
        openMeeting = Meeting()
        completion(true)
    }
    
    
    func pullMeetings(completion: @escaping CompletionHandler) {
        guard let group = checkIfUserIsLeader() as? Group else {
            completion(false)
            return
        }
        if group.id != "" && selectedGroup.id != nil {
            ref.child("groups").child(selectedGroup.id).child("meetings").getData { error, snapshot in
                guard let value = snapshot?.value as? NSDictionary else {
                    completion(false)
                    return
                }
                self.meetings.removeAll()
                for id in value.allKeys {
                    let subvalue = value.value(forKey: id as! String) as? NSDictionary
                    let hostID = subvalue?.value(forKey: "host") as! String
                    let openTime = subvalue?.value(forKey: "openTime") as! String
                    let closeTime = subvalue?.value(forKey: "closeTime") as? String ?? ""
                    let gameHost = subvalue?.value(forKey: "gameHost") as? String ?? ""
                    let gameOpenTime = subvalue?.value(forKey: "gameOpenTime") as? String ?? ""
                    let gameCloseTime = subvalue?.value(forKey: "gameCloseTime") as? String ?? ""
                    let gameTitle = subvalue?.value(forKey: "gameTitle") as? String ?? ""
                    let gameWinner = subvalue?.value(forKey: "gameWinnerID") as? String ?? ""
                    let gamePoints = subvalue?.value(forKey: "gamePoints") as? Int ?? 0
                    let collectingAttendanceID = subvalue?.value(forKey: "collectingAttendance") as? String ?? ""
                    var attendancesArray: [String : String] = [:]
                    if let attendances = subvalue?.value(forKey: "attendance") as? NSDictionary {
                        for attendance in attendances {
                            attendancesArray.updateValue(attendance.value as! String, forKey: attendance.key as! String)
                        }
                    }
                    let meeting = Meeting(id: id as! String,
                                          openTime: openTime,
                                          closeTime: closeTime,
                                          hostID: hostID,
                                          collectingAttendance: collectingAttendanceID,
                                          gameOpenTime: gameOpenTime,
                                          gameCloseTime: gameCloseTime,
                                          gameHost: gameHost,
                                          gameTitle: gameTitle,
                                          gamePoints: gamePoints,
                                          gameWinner: gameWinner,
                                          attendances: attendancesArray
                    )
                    self.meetings.append(meeting)
                }
                completion(true)
            }
        } else {
            completion(false)
        }

    }
    
    func startGame(title: String, points: Int, completion: @escaping CompletionHandler) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
         
        ref.child("groups").child(selectedGroup.id).child("meetings").child(openMeeting.id).updateChildValues([
            "gameOpenTime": dateStr,
            "gameHost": UserDataService.instance.user.id!,
            "gameTitle": title,
            "gamePoints": points
        ])
        NotificationCenter.default.post(name: NOTIF_GAME_UPDATE, object: nil)
        completion(true)
    }
    
    func endGame(winnerID: String, pointDistribution: [String:Int]) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
        ref.child("groups").child(selectedGroup.id).child("meetings").child(openMeeting.id).updateChildValues([
            "gameCloseTime": dateStr,
            "gameWinnerID": winnerID
        ])
        for line in pointDistribution {
            if line.value as! Int > 0 {
                ref.child("groups").child(selectedGroup.id).child("patrolPointBook").childByAutoId().updateChildValues([
                    "patrol" : line.key,
                    "amount" : line.value,
                    "timestamp" : dateStr,
                    "reason" : "Game \(openMeeting.gameTitle ?? "")"
                ])
            }
            for apatrol in patrols {
                if apatrol.name == line.key {
                    ref.child("groups").child(selectedGroup.id).child("patrols").child(line.key).updateChildValues(["score": line.value + apatrol.score])
                }
            }
        }
        openMeeting.gameCloseTime = dateStr
        openMeeting.gameWinner = winnerID
        NotificationCenter.default.post(name: NOTIF_GAME_UPDATE, object: nil)
    }
    func disburseManually(amount: Int, reason: String, patrol: Patrol) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
        
        ref.child("groups").child(selectedGroup.id).child("patrolPointBook").childByAutoId().updateChildValues([
            "patrol" : patrol.name!,
            "amount" : amount,
            "timestamp" : dateStr,
            "reason" : "\(UserDataService.instance.user.name!): \(reason)"
        ])
        for apatrol in patrols {
            if apatrol.name == patrol.name {
                ref.child("groups").child(selectedGroup.id).child("patrols").child(apatrol.name).updateChildValues(["score": amount + apatrol.score])
            }
        }
    }
    
    func startCollectingAttendances(completion: @escaping CompletionHandler) {
        ref.child("groups").child(selectedGroup.id).child("meetings").child(openMeeting.id).updateChildValues([
            "collectingAttendance": UserDataService.instance.user.id!
        ])
        completion(true)
    }
    
    func stopCollectingAttendance() {
        if isThereAnOpenMeeting() {
            if openMeeting.collectingAttendance == UserDataService.instance.user.id {
                ref.child("groups").child(selectedGroup.id).child("meetings").child(openMeeting.id).updateChildValues(["collectingAttendance": ""])
            }
        }
    }
    
    func clockInMember(id: String, completion: @escaping CompletionHandler) {
        var valid = false
        for user in users {
            let group = queryGroup(user: user)
            if user.id == id && group.id == selectedGroup.id {
                valid = true
            }
        }
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
           
        if valid {
            ref.child("groups").child(selectedGroup.id).child("meetings").child(openMeeting.id).child("attendance").updateChildValues([id : dateStr])
            openMeeting.attendances.updateValue(dateStr, forKey: id)
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func scanTicket(user: User, completion: @escaping CompletionHandler) {
        var flag = false
        for ticket in tickets {
            if ticket.event.id == selectedEvent.id && ticket.userID == user.id {
                flag = true
                let formatter : DateFormatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
                let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
                   
                ref.child("tickets").child(ticket.id).updateChildValues([
                    "scanned": dateStr
                ])
                completion(true)
            }
        }
        completion(flag)
    }
    
    func checkIfTicketIsScanned(user: User) -> Bool {
        for ticket in tickets {
            if ticket.event.id == selectedEvent.id && ticket.userID == user.id {
                return ticket.scanned != ""
            }
        }
        return false
    }
    
    func isThereAnOpenMeeting() -> Bool {
        var open = false
        for meeting in meetings {
            if meeting.closeTime == "" || meeting.closeTime == nil {
                open = true
                openMeeting = meeting
            }
        }
        return open
    }
    
    func queryUser(UserID: String) -> User {
        let filteredUsers = users.filter { $0.id == UserID }
        
        // Check if the filtered result is not empty
        if let user = filteredUsers.first {
            return user
        } else {
            // Return nil or handle the case when the user is not found
            return User()
        }
    }
    
    func countPatrolLiveAttendances(patrolName: String) -> Int {
        var count = 0
        for attendance in openMeeting.attendances {
            let user = queryUser(UserID: attendance.key)
            let patrol = queryPatrol(user: user)
            if patrol.name == patrolName {
                count += 1
            }
        }
        return count
    }
    
    

}
