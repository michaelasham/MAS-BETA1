//
//  GroupMemberCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//

import UIKit
import FirebaseStorage

class GroupMemberCell: UITableViewCell {

    @IBOutlet weak var badgeImage: CircleImageView!
    @IBOutlet weak var bottomLbl: UILabel!
    @IBOutlet weak var topLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var profileImage: CircleImageView!
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setupView(user: User, top: String, bottom: String, subtitle: String) {
        topLbl.text = top
        bottomLbl.text = bottom
        titleLbl.text = user.name
        subtitleLbl.text = subtitle
        if user.id == UserDataService.instance.user.id {
            titleLbl.text = "You"
        }
        profileImage.image = AdminService.instance.findImage(id: user.id, ext: "jpg")
        if AdminService.instance.findImage(id: user.id, ext: "jpg") == UIImage() {
            let imageRef = storageRef.child("users/\(user.id!).jpg")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { data, error in
                if let error = error {
                    // uh-oh
                    print("pfperror")
                    print(error.localizedDescription)
                    // might be no image
                } else {
                    //success
                    AdminService.instance.saveImage(id: user.id, image: data!, ext: "jpg")
                    self.profileImage.image = UIImage(data: data!)
                }
            }
        }
        
        // badge
        if let badge = BadgeService.instance.queryUserMostSignificantBadgeActivity(user: user).badge {
            badgeImage.image = AdminService.instance.findImage(id: badge.id, ext: "png")
            if AdminService.instance.findImage(id: badge.id, ext: "png") == UIImage() {
                let imageRef = storageRef.child("badges/\(badge.id!).png")
                imageRef.getData(maxSize: 15 * 1024 * 1024) { data, error in
                    if let error = error {
                        // uh-oh
                        print("badgeerror")
                        print(error.localizedDescription)
                        // might be no image
                    } else {
                        //success
                        AdminService.instance.saveImage(id: badge.id, image: data!, ext: "png")
                        self.badgeImage.image = UIImage(data: data!)
                    }
                }
            }
        }

    }
}
