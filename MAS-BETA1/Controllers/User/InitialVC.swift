//
//  InitialVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit

class InitialVC: UIViewController {

    
    @IBOutlet weak var loadingBar: UIProgressView!
    @IBOutlet weak var loadingLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load()
        // Do any additional setup after loading the view.
    }
    
    
    func load() {
        UserDataService.instance.pullUserData { Success in
            self.postProgess(progress: 15)
            CommunityService.instance.pullUsers { Success in
                self.postProgess(progress: 32)
                CommunityService.instance.pullEvents { Success in
                    self.postProgess(progress: 40)
                    BadgeService.instance.pullBadges { Success in
                        self.postProgess(progress: 55)
                        BadgeService.instance.pullBadgeActivities { Success in
                            self.postProgess(progress: 67)
                            MaterialService.instance.pullMaterials { Success in
                                self.postProgess(progress: 72)
                                CommunityService.instance.pullGroups { Success in
                                    self.postProgess(progress: 83)
                                    AdminService.instance.pullWebsiteAdDetails { Success in
                                        self.postProgess(progress: 91)
                                        CommunityService.instance.pullMeetings { Success in
                                            self.postProgess(progress: 95)
                                            self.proceed()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func proceed() {
        if AuthService.instance.isLoggedIn {
            performSegue(withIdentifier: "toMainVC", sender: self)
        } else {
            performSegue(withIdentifier: "toReceptionVC", sender: self)
        }
    }
    
    func postProgess(progress: Int) {
        UIProgressView.animate(withDuration: 0.2) {
            self.loadingBar.progress = Float(progress)/100
        }
        loadingLbl.text = "\(progress)%"
    }
}
