//
//  MaterialCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 18/06/2024.
//

import UIKit

class MaterialCell: UITableViewCell {

    @IBOutlet weak var likeLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var dislikeLbl: UILabel!
    @IBOutlet weak var dislikeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupCell(material: Material) {
        titleLbl.text = material.name
        likeLbl.text = "\(material.likes.count)"
        dislikeLbl.text = "\(material.dislikes.count)"
        dislikeImageView.isHidden = material.dislikes.count == 0 && material.likes.count == 0
        likeImageView.isHidden = material.dislikes.count == 0 && material.likes.count == 0
        likeLbl.isHidden = material.dislikes.count == 0 && material.likes.count == 0
        dislikeLbl.isHidden = material.dislikes.count == 0 && material.likes.count == 0
    }
    
}
