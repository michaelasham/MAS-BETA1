//
//  GroupMemberCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//

import UIKit
import FirebaseStorage

class GroupMemberCell: UITableViewCell, UIContextMenuInteractionDelegate {

    @IBOutlet weak var badgeImage: CircleImageView!
    @IBOutlet weak var bottomLbl: UILabel!
    @IBOutlet weak var topLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var profileImage: CircleImageView!
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    var user = User()
    var leader = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [self] suggestedActions in
            // Create the action for the context menu
            if leader {
                let firstActionButton = UIAction(title: "Call \(user.phone!)", image: UIImage.init(systemName: "phone")) { action in
                    if let phoneURL = URL(string: "tel://\(user.phone!)") {
                        if UIApplication.shared.canOpenURL(phoneURL) {
                            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
                        }
                    }
                    
                }
            return UIMenu(title: user.name, children: [firstActionButton])
            }

                return UIMenu()
                
            }
    }
    func setupView(user: User, top: String, bottom: String, subtitle: String) {
        let group = CommunityService.instance.checkIfUserIsLeader()
        leader = group.id != ""
        self.user = user
        topLbl.text = top
        bottomLbl.text = bottom
        titleLbl.text = user.name
        subtitleLbl.text = subtitle
        if user.id == UserDataService.instance.user.id {
            titleLbl.text = "You"
        }
        profileImage.image = generatePlaceholderImage(forName: user.name)
        profileImage.image = AdminService.instance.findImage(id: user.id, ext: "jpg")
        if AdminService.instance.findImage(id: user.id, ext: "jpg") == UIImage() {
            let imageRef = storageRef.child("users/\(user.id!).jpg")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { [self] data, error in
                if let error = error {
                    // uh-oh
                    print("pfperror")
                    print(error.localizedDescription)
                    self.profileImage.image = generatePlaceholderImage(forName: user.name)
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
    
    
    func generatePlaceholderImage(forName name: String, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let initials = name.components(separatedBy: " ").compactMap { $0.first }.prefix(2)
        let initialsString = String(initials).uppercased()

        // Generate a random color
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]
        let backgroundColor = colors.randomElement() ?? .systemGray

        // Create a UILabel to draw the initials
        let label = UILabel(frame: CGRect(origin: .zero, size: size))
        label.backgroundColor = backgroundColor
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: size.width / 2)
        label.textAlignment = .center
        label.text = initialsString

        // Render the label as an image
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        label.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        return image
    }
}
