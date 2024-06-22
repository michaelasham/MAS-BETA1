//
//  MiniBadgeCell.swift
//  MAS-BETA
//
//  Created by Michael Asham on 18/06/2024.
//

import UIKit
import FirebaseStorage

class MiniBadgeCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    func setupCell(badgeActivity: BadgeActivity) {
        imageView.image = AdminService.instance.findImage(id: badgeActivity.badge.id, ext: "png")
        if imageView.image?.size.width == 0 {
            let imageRef = storageRef.child("badges/\(badgeActivity.badge.id).png")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { [self] data, error in
                if let error = error {
                    // uh-oh
                    print(error.localizedDescription)
                } else {
                    //success
                    self.imageView.image = UIImage(data: data!)
                    AdminService.instance.saveImage(id: badgeActivity.badge.id, image: data!, ext: "png")
                }
            }
        }
    }
}
