//
//  HomeVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit
import Firebase

class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var groupEditBtn: UIButton!
    @IBOutlet weak var meetingSubtitleLbl: UILabel!
    @IBOutlet weak var meetingClockLbl: UILabel!
    @IBOutlet weak var groupPatrolActionBtn: BorderButton!
    @IBOutlet weak var welcomingLbl: UILabel!
    @IBOutlet weak var websiteAdView: BorderView!
    @IBOutlet weak var eventCreationRequestView: BorderView!
    @IBOutlet weak var myPatrolView: BorderView!
    @IBOutlet weak var meetingView: BorderView!
    @IBOutlet weak var eventsView: BorderView!
    @IBOutlet weak var groupPatrolOverviewView: BorderView!
    @IBOutlet weak var groupMemberOverviewView: BorderView!
    @IBOutlet weak var groupPatrolTitleLbl: UILabel!
    @IBOutlet weak var patrolScoreCollectionView: UICollectionView!
    @IBOutlet weak var groupPatrolSubtitleLbl: UILabel!
    @IBOutlet weak var groupMemberTitleLbl: UILabel!
    @IBOutlet weak var groupMemberTableView: UITableView!
    @IBOutlet weak var eventsTableView: UITableView!
    @IBOutlet weak var meetingTitleLbl: UILabel!
    @IBOutlet weak var meetingPrimaryActionBtn: CircleButton!
    @IBOutlet weak var meetingGameLbl: UILabel!
    @IBOutlet weak var meetingGameTimerLbl: UILabel!
    @IBOutlet weak var websiteBannerLbl: UILabel!
    @IBOutlet weak var websiteImageView: UIImageView!
    @IBOutlet weak var myPatrolActionBtn: BorderButton!
    @IBOutlet weak var myPatrolSubtitle: UILabel!
    @IBOutlet weak var myPatrolTableView: UITableView!
    @IBOutlet weak var myPatrolTitle: UILabel!
    @IBOutlet weak var meetingPointsBtn: BorderButton!
    @IBOutlet weak var meetingGameBtn: BorderButton!
    @IBOutlet weak var meetingAttendanceBtn: BorderButton!
    @IBOutlet weak var eventManagerView: BorderView!
    @IBOutlet weak var eventManagerTitleLbl: UILabel!
    @IBOutlet weak var eventManagerSubtitleLbl: UILabel!
    @IBOutlet weak var eventManagerBtn: UIButton!
    @IBOutlet weak var eventManagerTableView: UITableView!
    
    
    
    
    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var timer: Timer?
    var gameTimer: Timer?
    
    var leader = false
    var leadedGroup = Group()
    var myPatrol = Patrol()
    var hostingEvent = Event()
    let user = UserDataService.instance.user
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViews()
        myPatrolTableView.isEditing = false
        groupMemberTableView.isEditing = false
        patrolScoreCollectionView.isEditing = false
        setupViews()
        attachPatrolSocket()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePatrolMembers), name: NOTIF_PATROL_MEMBER_UPDATE, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupEventCreationRequestView), name: NOTIF_EVENT_CREATION_REQUEST, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupMeetingView), name: NOTIF_GAME_UPDATE, object: nil)
        if leader {
            attachMeetingSocket()
        }

    }
    //SOCKETS
    func attachMeetingSocket() {
        _ = ref.child("groups").child(leadedGroup.id!).child("meetings").observe(.value) { snapshot,xx  in
            CommunityService.instance.pullMeetings { Success in
                if CommunityService.instance.isThereAnOpenMeeting() {
                    self.setupMeetingView()
                }
            }
        }
    }
    func attachPatrolSocket() {
        _ = ref.child("groups").child(leadedGroup.id!).child("patrols").observe(.value) { snapshot,xx  in
            guard let value = snapshot.value as? NSDictionary else { return }
            for id in value.allKeys {
                for i in 0..<self.leadedGroup.patrols.count {
                    if self.leadedGroup.patrols[i].name == id as? String {
                        let subvalue = value.value(forKey: id as! String) as? NSDictionary ?? NSDictionary()
                        if self.leadedGroup.patrols[i].score != subvalue.value(forKey: "score") as? Int ?? 0 {
                            self.leadedGroup.patrols[i].score = subvalue.value(forKey: "score") as? Int ?? 0
                            CommunityService.instance.patrols[i].score = subvalue.value(forKey: "score") as? Int ?? 0

                            
                        }
                    }
                    let cell = self.patrolScoreCollectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? PatrolScoreCell
                    cell?.setupView(patrol: self.leadedGroup.patrols[i])
                }
            }
        }
    }
    func attachTicketsSocket() {
        _ = ref.child("tickets").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? NSDictionary else { return }
            CommunityService.instance.pullTickets { Success in
                self.setupEventManagerView()
            }
        })
    }
    
    
    @IBAction func onGroupEditBtn(_ sender: Any) {
        performSegue(withIdentifier: "toGroupVC", sender: self)
    }
    
    @IBAction func onEventManagerClick(_ sender: Any) {
        CommunityService.instance.attendanceMode = "event"
        performSegue(withIdentifier: "toCollectingAttendanceVC", sender: self)
    }
    @objc func updatePatrolMembers() {
//        leadedGroup = CommunityService.instance.selectedGroup
        setupGroupPatrolOverview()
    }
    
    @objc func setupEventCreationRequestView() {
        eventCreationRequestView.isHidden = !leader || CommunityService.instance.requestedAnEvent
    }
    
    func setupViews() {
        welcomingLbl.text = "Welcome back \(user.name ?? "")!"
        leadedGroup = CommunityService.instance.checkIfUserIsLeader()
        CommunityService.instance.patrols = leadedGroup.patrols ?? [Patrol]()
        CommunityService.instance.selectedGroup = leadedGroup
        meetingView.isHidden = leadedGroup.id == ""
        eventsView.isHidden = CommunityService.instance.events.count == 0
        eventCreationRequestView.isHidden = UserDataService.instance.user.dash ?? 0 >= 0
        leader = leadedGroup.id != ""
        CommunityService.instance.queryGroupMembers()
        
        setupGroupPatrolOverview()
        setupEventManagerView()
        setupMyPatrolView()
        setupMeetingView()
        setupUpcomingEvents()
        setupGroupMemberOverview()
        setupWebsiteView()
        setupEventCreationRequestView()
    }
    
    func setupTableViews() {
        patrolScoreCollectionView.delegate = self
        patrolScoreCollectionView.dataSource = self
        groupMemberTableView.delegate = self
        groupMemberTableView.dataSource = self
        myPatrolTableView.delegate = self
        myPatrolTableView.dataSource = self
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.isEditing = false
        eventManagerTableView.isEditing = false
        eventManagerTableView.delegate = self
        eventManagerTableView.dataSource = self
    }
    
    func setupGroupPatrolOverview() {
        groupPatrolTitleLbl.text = "\(leadedGroup.name ?? "") Patrol Overview"
        groupPatrolActionBtn.isHidden = !leader
        if leader {
            if CommunityService.instance.groupStillNeedsSorting(group: leadedGroup) {
                patrolScoreCollectionView.isHidden = true
            } else {
                patrolScoreCollectionView.isHidden = false
            }
        } else {
//            CommunityService.instance.selectedGroup = leadedGroup
            let patrols = CommunityService.instance.selectedGroup.patrols
            if patrols?.count == 0 {

            } else {
                patrolScoreCollectionView.isHidden = false
            }
        }
    }
    
    func setupEventManagerView() {
        hostingEvent = CommunityService.instance.queryHostingEvent()
        if hostingEvent.id != "" {
            eventManagerTitleLbl.text = hostingEvent.title
            let tickets = CommunityService.instance.queryEventTickets(event: hostingEvent)
            eventManagerSubtitleLbl.text = "(\(tickets.count)/\(hostingEvent.maxLimit))  \(hostingEvent.date)"
            eventManagerTableView.reloadData()
            let today = CommunityService.instance.isDateToday(dateString: hostingEvent.date)
            eventManagerBtn.isHidden = !today
        } else {
            eventManagerView.isHidden = true
        }
    }
    
    func setupGroupMemberOverview() {
        groupMemberOverviewView.isHidden = CommunityService.instance.selectedGroupMembers.count == 0
        groupMemberTitleLbl.text = "\(CommunityService.instance.selectedGroup.name ?? "") Member Overview"
    }
    
    func setupUpcomingEvents() {
        CommunityService.instance.filterEvents()
        eventsView.isHidden = CommunityService.instance.events.count == 0
    }
    
    @objc func setupMeetingView() {
        meetingView.isHidden = !leader
        meetingSubtitleLbl.text = ""
        meetingClockLbl.text = ""
        meetingGameLbl.text = ""
        meetingGameTimerLbl.text = ""
        if leader {
            meetingPointsBtn.isHidden = !CommunityService.instance.isThereAnOpenMeeting()
            meetingAttendanceBtn.isHidden = !CommunityService.instance.isThereAnOpenMeeting()
            meetingGameBtn.isHidden = !CommunityService.instance.isThereAnOpenMeeting()
            if CommunityService.instance.isThereAnOpenMeeting() {
                meetingClockLbl.isHidden = false
                meetingPrimaryActionBtn.setTitle("END MEETING", for: .normal)
                let user = CommunityService.instance.queryUser(UserID: CommunityService.instance.openMeeting.hostID)
                meetingSubtitleLbl.text = "Hosted by \(user.name!)"
                if user.id == UserDataService.instance.user.id {
                    meetingSubtitleLbl.text = "Hosted by you"
                }
                if CommunityService.instance.openMeeting.collectingAttendance == UserDataService.instance.user.id {
//                   self.performSegue(withIdentifier: "toCollectingAttendanceVC", sender: self)
               } else if CommunityService.instance.openMeeting.collectingAttendance != "" {
                     meetingAttendanceBtn.isEnabled = false
                     let collector = CommunityService.instance.queryUser(UserID: CommunityService.instance.openMeeting.collectingAttendance ?? "")
                     meetingAttendanceBtn.setTitle("\(collector.name ?? "") is collecting attendance", for: .normal)
                     meetingAttendanceBtn.backgroundColor = .darkGray
                 } else {
                    meetingAttendanceBtn.isEnabled = true
                    meetingAttendanceBtn.setTitle("Collect Attendance", for: .normal)
                    meetingAttendanceBtn.backgroundColor = .blue
                }
                meetingGameBtn.isEnabled = true
                if CommunityService.instance.openMeeting.gameOpenTime != "" {
                    //game opened
                    meetingGameTimerLbl.isHidden = false
                    let gameHost = CommunityService.instance.queryUser(UserID: CommunityService.instance.openMeeting.gameHost ?? "")
                    if gameHost.id == UserDataService.instance.user.id {
                        meetingGameLbl.text = "Game started by you"
                    }
                    meetingGameLbl.text = "Game started by \(gameHost.name ?? "")"
                    meetingGameBtn.setTitle("End \(CommunityService.instance.openMeeting.gameTitle ?? "")", for: .normal)
                }
                if CommunityService.instance.openMeeting.gameCloseTime != "" {
                    //gamed closed
                    meetingGameLbl.text = ""
                    meetingGameTimerLbl.text = ""
                    meetingGameBtn.setTitle("Game Over", for: .normal)
                    meetingGameBtn.backgroundColor = .darkGray
                    meetingGameLbl.text = "Winner: \(CommunityService.instance.openMeeting.gameWinner ?? "")"
                    meetingGameBtn.isEnabled = false
                    self.gameTimer?.invalidate()
                    meetingGameTimerLbl.isHidden = true
                }
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
                gameTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
            } else {
                meetingPrimaryActionBtn.setTitle("START MEETING", for: .normal)
                self.timer?.invalidate()
                self.gameTimer?.invalidate()
                meetingClockLbl.isHidden = true
            }
        }
        // check if meeting is scheduled almost now
        // add observers
        
    }
    


    
    func setupMyPatrolView() {
        myPatrolView.isHidden = leader
        if !leader {
            myPatrol = CommunityService.instance.queryPatrol(user: user)
            myPatrolView.isHidden = myPatrol.name == ""
            myPatrolTitle.text = myPatrol.name
            if user.id == myPatrol.chief.id || user.id == myPatrol.vice.id {
                // check first if meeting is within 48 hrs
                myPatrolActionBtn.isHidden = false
                myPatrolSubtitle.text = "Remind your mates next meeting is scheduled in xx hours"
            }
        }
    }
    
    func setupWebsiteView() {
        websiteAdView.isHidden = AdminService.instance.websiteAdLink == ""
        if AdminService.instance.websiteAdLink != "" {
            websiteBannerLbl.text = AdminService.instance.websiteAdTitle
            websiteImageView.image = AdminService.instance.findImage(id: "websiteAd", ext: "jpg")
            if websiteImageView.image == UIImage() {
                var imageRef = storageRef.child("websiteAd.jpg")
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpg"
                imageRef.getData(maxSize: 15 * 1024 * 1024) { data, error in
                    if let data = data {
                        self.websiteImageView.image = UIImage(data: data)!
                        AdminService.instance.saveImage(id: "websiteAd", image: data, ext: "jpg")
                    }
                }
            } else {
            }
        }
    }
    

    @IBAction func onGroupPatrolOverviewClick(_ sender: Any) {
        performSegue(withIdentifier: "toPatrolSortingVC", sender: self)
    }
    
    @IBAction func onStartMeetingClick(_ sender: Any) {
        if CommunityService.instance.isThereAnOpenMeeting() {
            CommunityService.instance.endMeeting { Success in
                self.timer?.invalidate()
                self.setupMeetingView()
            }
        } else {
            CommunityService.instance.startMeeting { Success in
                self.setupMeetingView()
            }
        }
    }
    @IBAction func onCollectAttendanceClick(_ sender: Any) {
        CommunityService.instance.attendanceMode = "meeting"
        CommunityService.instance.startCollectingAttendances { Success in
            self.performSegue(withIdentifier: "toCollectingAttendanceVC", sender: self)
        }
    }
    
    @IBAction func onStartGameClick(_ sender: Any) {
        performSegue(withIdentifier: "toGameVC", sender: self)
    }
    
    @IBAction func onDisbursePointsClick(_ sender: Any) {
        performSegue(withIdentifier: "toDisburseVC", sender: self)
    }
    
    
    @IBAction func onRemindMyTeamClick(_ sender: Any) {
        
    }
    
    
    @IBAction func onProposeAnEventClick(_ sender: Any) {
        performSegue(withIdentifier: "toEventRequestVC", sender: self)
    }
    
    @IBAction func onVisitWebsiteClick(_ sender: Any) {
        if let url = URL(string: AdminService.instance.websiteAdLink) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Can't open URL on this device.")
            }
        } else {
            print("Invalid URL.")
        }
    }
    
}


extension HomeVC {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return leadedGroup.patrols.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = patrolScoreCollectionView.dequeueReusableCell(withReuseIdentifier: "PatrolScoreCell", for: indexPath) as? PatrolScoreCell {
            cell.setupView(patrol: leadedGroup.patrols[indexPath.row])
            return cell
        }
        return UICollectionViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == groupMemberTableView {
            return CommunityService.instance.selectedGroupMembers.count
        } else if tableView == eventsTableView {
            return CommunityService.instance.events.count
        } else if tableView == eventManagerTableView {
            return CommunityService.instance.queryEventTickets(event: hostingEvent).count
        } else {
            //my patrol tableView
            if myPatrol.name != nil {
                return myPatrol.members.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == eventsTableView {
            CommunityService.instance.selectedEvent = CommunityService.instance.events[indexPath.row]
            performSegue(withIdentifier: "homeToEventVC", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == eventsTableView {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "UpcomingEventCell") as? UpcomingEventCell {
                cell.setupCell(event: CommunityService.instance.events[indexPath.row])
                return cell
            }
            return UpcomingEventCell()
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell") as? GroupMemberCell {
                if tableView == groupMemberTableView {
                    let user = CommunityService.instance.selectedGroupMembers[indexPath.row]
                    let patrol = CommunityService.instance.queryPatrol(user: user) ?? Patrol()
                    cell.setupView(user: user, top: patrol.name ?? "", bottom: "#\(indexPath.row + 1)", subtitle: "\(user.score ?? 0) pts")
                } else if tableView == myPatrolTableView {
                    //my patrol
                    var role = "member"
                    let user = myPatrol.members[indexPath.row]
                    if myPatrol.chief.id == user.id! {
                        role = "chief"
                    } else if myPatrol.vice.id == user.id! {
                        role = "vice"
                    } else if myPatrol.troisieme.id == user.id! {
                        role = "troisieme"
                    } else {
                        role = "member"
                    }
                    var absences = "absences"
                    let absenceCount = CommunityService.instance.countAbsences(user: user)
                    if absenceCount == 1 {
                        absences = "absence"
                    }
                    cell.setupView(user: myPatrol.members[indexPath.row],
                                   top: role,
                                   bottom: "#\(indexPath.row + 1)",
                                   subtitle: "\(absenceCount) \(absences)")

                } else {
                    //hosting event
                    let tickets = CommunityService.instance.queryEventTickets(event: hostingEvent)
                    let ticket = tickets[indexPath.row]
                    let user = CommunityService.instance.queryUser(UserID: ticket.userID)
                    let group = CommunityService.instance.queryGroup(user: user)
                    var bottom = ticket.scanned.isEmpty ? "" : "SCANNED"
                    cell.setupView(user: user,
                                   top: group.name,
                                   bottom: bottom,
                                   subtitle: "")
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    func getElapsedTime(from timestamp: String) -> String? {
        // Step 1: Create a Date Formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss" // 24-hour format
        
        // Parse the timestamp string into a Date object
        guard let date = dateFormatter.date(from: timestamp) else {
            return nil
        }
        
        // Step 2: Calculate the Elapsed Time
        let now = Date()
        let elapsedTime = now.timeIntervalSince(date)
        
        // Calculate minutes and seconds from elapsedTime
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        
        // Format the elapsed time as mm:ss
        let elapsedTimeString = String(format: "%02d:%02d", minutes, seconds)
        
        return elapsedTimeString
    }
    
    @objc func updateElapsedTime() {
        if let elapsedTime = getElapsedTime(from: CommunityService.instance.openMeeting.openTime) {
            meetingClockLbl.text = elapsedTime
        } else {
            meetingClockLbl.text = "Invalid date"
        }
        if let elapsedTime = getElapsedTime(from: CommunityService.instance.openMeeting.gameOpenTime ?? "") {
            meetingGameTimerLbl.text = elapsedTime
        } else {
            meetingGameTimerLbl.text = "Invalid date"
        }
    }

}
