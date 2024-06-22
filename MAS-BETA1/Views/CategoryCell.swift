//
//  CategoryCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 18/06/2024.
//

import UIKit

class CategoryCell: UITableViewCell {

    @IBOutlet weak var ImageView: UIImageView!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupCell(title: String, count: Int) {
        titleLbl.text = title
        if count == 0 {
            subtitle.text = "\(count) items"
        } else {
            subtitle.text = "\(count) items"
        }
        ImageView.isHidden = false
        switch title {
        case "نيران":
            ImageView.image = UIImage(named: "flame")
        case "ربطات":
            ImageView.image = UIImage(named: "point.bottomleft.forward.to.point.topright.scurvepath")

        case "خيام":
            ImageView.image = UIImage(named: "tent.2")

        case "صلوات":
            ImageView.image = UIImage(named: "cross")

        case "شفرات":
            ImageView.image = UIImage(named: "key.viewfinder")

        case "بروتوكول":
            ImageView.image = UIImage(named: "books.vertical")

        case "صيحات":
            ImageView.image = UIImage(named: "music.note.list")

        default:
            ImageView.isHidden = true
        }
    }
    
    
    
}
