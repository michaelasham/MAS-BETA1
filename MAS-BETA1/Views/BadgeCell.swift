//
//  BadgeCell.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit
import FirebaseStorage

class BadgeCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var title: UILabel!
    
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    func setupCell(badge: Badge) {
        title.text = badge.name
        
        imageView.image = AdminService.instance.findImage(id: badge.id, ext: "png")
        if imageView.image?.size.width == 0 {
            let imageRef = storageRef.child("badges/\(badge.id).png")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { [self] data, error in
                if let error = error {
                    // uh-oh
                    print(error.localizedDescription)
                } else {
                    //success
                    self.imageView.image = UIImage(data: data!)
                    AdminService.instance.saveImage(id: badge.id, image: data!, ext: "png")
                }
            }
        }
    }
}
