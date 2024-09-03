//
//  HomeVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit
import Firebase

class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {

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
    @IBOutlet weak var websiteBannerLbl: UILabel!
    @IBOutlet weak var websiteImageView: UIImageView!
    @IBOutlet weak var myPatrolActionBtn: BorderButton!
    @IBOutlet weak var myPatrolSubtitle: UILabel!
    @IBOutlet weak var myPatrolTableView: UITableView!
    @IBOutlet weak var myPatrolTitle: UILabel!
    @IBOutlet weak var meetingPointsBtn: BorderButton!
    @IBOutlet weak var meetingGameBtn: BorderButton!
    @IBOutlet weak var meetingAttendanceBtn: BorderButton!
    
    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var timer: Timer?
    
    var leader = false
    var leadedGroup = Group()
    var myPatrol = Patrol()
    let user = UserDataService.instance.user
    
    override func viewDidLoad() {
        super.viewDidLoad()
        meetingPrimaryActionBtn.titleLabel?.textAlignment = .center
        patrolScoreCollectionView.delegate = self
        patrolScoreCollectionView.dataSource = self
        groupMemberTableView.delegate = self
        groupMemberTableView.dataSource = self
        myPatrolTableView.delegate = self
        myPatrolTableView.dataSource = self
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.isEditing = false
        myPatrolTableView.isEditing = false
        groupMemberTableView.isEditing = false
        patrolScoreCollectionView.isEditing = false
        setupViews()
        attachPatrolSocket()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePatrolMembers), name: NOTIF_PATROL_MEMBER_UPDATE, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupEventCreationRequestView), name: NOTIF_EVENT_CREATION_REQUEST, object: nil)

    }
    //SOCKETS
    func attachMeetingSocket() {
        _ = ref.child("groups").child(leadedGroup.id!).child("meetings").observe(.value) { snapshot,xx  in
            CommunityService.instance.pullMeetings { Success in
                let meeting = CommunityService.instance.isThereAnOpenMeeting()
                self.setupMeetingView()
            }
        }
    }
    func attachPatrolSocket() {
        _ = ref.child("groups").child(leadedGroup.id!).child("patrols").observe(.value) { snapshot,xx  in
            guard let value = snapshot.value as? NSDictionary else { return }
            for id in value.allKeys {
                for i in 0..<self.leadedGroup.patrols.count {
                    if self.leadedGroup.patrols[i].name == id as! String {
                        let subvalue = value.value(forKey: id as! String) as? NSDictionary ?? NSDictionary()
                        if self.leadedGroup.patrols[i].score != subvalue.value(forKey: "score") as? Int ?? 0 {
                            self.leadedGroup.patrols[i].score = subvalue.value(forKey: "score") as? Int ?? 0
                            let cell = self.patrolScoreCollectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? PatrolScoreCell
                            cell?.setupView(patrol: self.leadedGroup.patrols[i])
                        }
                    }
                }
            }
        }
    }
    
    @objc func updatePatrolMembers() {
//        leadedGroup = CommunityService.instance.selectedGroup
        setupGroupPatrolOverview()
    }
    
    func setupViews() {
        welcomingLbl.text = "Welcome back \(user.name ?? "")!"
        leadedGroup = CommunityService.instance.checkIfUserIsLeader()
        CommunityService.instance.selectedGroup = leadedGroup
        meetingView.isHidden = leadedGroup.id == ""
        eventsView.isHidden = CommunityService.instance.events.count == 0
        eventCreationRequestView.isHidden = UserDataService.instance.user.dash ?? 0 >= 0
        leader = leadedGroup.id != ""
        CommunityService.instance.queryGroupMembers()
        
        setupGroupPatrolOverview()
        setupMyPatrolView()
        setupMeetingView()
        setupUpcomingEvents()
        setupGroupMemberOverview()
        setupWebsiteView()
        setupEventCreationRequestView()
    }
    
    func setupGroupPatrolOverview() {
        groupPatrolTitleLbl.text = "\(leadedGroup.name!) Patrol Overview"
        if leader {
            if CommunityService.instance.groupStillNeedsSorting(group: leadedGroup) {
                patrolScoreCollectionView.isHidden = true
                groupPatrolActionBtn.isEnabled = true
                groupPatrolActionBtn.isHidden = false
                groupPatrolActionBtn.setTitle("Sort Patrols", for: .normal)
            } else {
                patrolScoreCollectionView.isHidden = false
                groupPatrolActionBtn.isHidden = true
            }
        } else {
//            CommunityService.instance.selectedGroup = leadedGroup
            let patrols = CommunityService.instance.selectedGroup.patrols
            if patrols?.count == 0 {
                groupPatrolActionBtn.isHidden = false
                groupPatrolActionBtn.isEnabled = false
                groupPatrolActionBtn.setTitle("Patrols not sorted yet", for: .normal)
            } else {
                groupPatrolActionBtn.isHidden = true
                patrolScoreCollectionView.isHidden = false
            }
        }
    }
    
    func setupGroupMemberOverview() {
        groupMemberOverviewView.isHidden = CommunityService.instance.selectedGroupMembers.count == 0
        groupMemberTitleLbl.text = "\(CommunityService.instance.selectedGroup.name!) Member Overview"
    }
    
    func setupUpcomingEvents() {
        CommunityService.instance.filterEvents()
        eventsView.isHidden = CommunityService.instance.events.count == 0
    }
    
    func setupMeetingView() {
        meetingView.isHidden = !leader
        meetingSubtitleLbl.text = ""
        meetingClockLbl.text = ""
        if leader {
            attachMeetingSocket()
            meetingPointsBtn.isHidden = !CommunityService.instance.isThereAnOpenMeeting()
            meetingAttendanceBtn.isHidden = !CommunityService.instance.isThereAnOpenMeeting()
            meetingGameBtn.isHidden = !CommunityService.instance.isThereAnOpenMeeting()
            if CommunityService.instance.isThereAnOpenMeeting() {
                meetingPrimaryActionBtn.setTitle("END MEETING", for: .normal)
                let user = CommunityService.instance.queryUser(UserID: CommunityService.instance.openMeeting.hostID)
                meetingSubtitleLbl.text = "Hosted by \(user.id)"
                if user.id == UserDataService.instance.user.id {
                    meetingSubtitleLbl.text = "Hosted by you"
                }
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
            } else {
                meetingPrimaryActionBtn.setTitle("START MEETING", for: .normal)
                self.timer?.invalidate()
            }
        }
        // check if meeting is scheduled almost now
        // add observers
        
    }
    
    @objc func setupEventCreationRequestView() {
        eventCreationRequestView.isHidden = !leader || CommunityService.instance.requestedAnEvent
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
        performSegue(withIdentifier: "toCollectingAttendanceVC", sender: self)
    }
    @IBAction func onStartGameClick(_ sender: Any) {
        
    }
    @IBAction func onDisbursePointsClick(_ sender: Any) {
        
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
                NSLayoutConstraint.activate([
                    cell.heightAnchor.constraint(equalToConstant: 70)
                ])
                cell.setupCell(event: CommunityService.instance.events[indexPath.row])
                return cell
            }
            return UpcomingEventCell()
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell") as? GroupMemberCell {
                if tableView == groupMemberTableView {
                    let user = CommunityService.instance.selectedGroupMembers[indexPath.row]
                    let patrol = CommunityService.instance.queryPatrol(user: user)
                    cell.setupView(user: user, top: patrol.name, bottom: "#\(indexPath.row + 1)", subtitle: "")
                } else {
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
                    cell.setupView(user: myPatrol.members[indexPath.row], top: role, bottom: "#\(indexPath.row + 1)", subtitle: "")

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
    }

}
