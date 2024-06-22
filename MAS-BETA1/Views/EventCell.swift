//
//  EventCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//


import UIKit
import FirebaseStorage

class EventCell: UITableViewCell {
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var background: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(event: Event) {
        title.text = event.title
        background.image = AdminService.instance.findImage(id: event.id, ext: "jpg")
        if background.image?.size.width == 0 {
            let imageRef = storageRef.child("events/\(event.id).jpg")
            imageRef.getData(maxSize: 15 * 1024 * 1024) { [self] data, error in
                if let error = error {
                    // uh-oh
                    print(error.localizedDescription)
                } else {
                    //success
                    self.background.image = UIImage(data: data!)
                    AdminService.instance.saveImage(id: event.id, image: data!, ext: "jpg")
                }
            }
        }
    }
}
