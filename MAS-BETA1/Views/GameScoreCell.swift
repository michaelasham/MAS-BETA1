//
//  GameScoreCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 08/09/2024.
//

import UIKit

class GameScoreCell: UITableViewCell {

    @IBOutlet weak var pointsLbl: UILabel!
    @IBOutlet weak var dominanceLbl: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var titleLbl: UILabel!
    
    var dominance = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onSliderSlide(_ sender: Any) {
        NotificationCenter.default.post(name: NOTIF_SLIDER_SLIDE, object: nil)
        dominanceLbl.text = "\(Int(slider.value*100))%"
        dominance = Int(slider.value*100)
        calculatePoints()
    }
    
    func calculatePoints() {
        let totalPoints = CommunityService.instance.openMeeting.gamePoints ?? 0
        let totalSliderScores = CommunityService.instance.sliderScores

        // If totalSliderScores is zero, this cell should show zero points
        if totalSliderScores == 0 {
            pointsLbl.text = "0"
            return
        }

        // Calculate the points proportionally
        let sliderValue = slider.value * 100
        let proportion = sliderValue / Float(totalSliderScores)

        // If the slider value is greater than zero, calculate points
        if sliderValue > 0 {
            let points = Int(proportion * Float(totalPoints))

            // Ensure that points do not exceed totalPoints
            pointsLbl.text = "\(min(points, totalPoints))"
        } else {
            // If the slider value is zero, it should show zero points
            pointsLbl.text = "0"
        }
    }






    
    func setupCell(patrol: Patrol) {
        titleLbl.text = patrol.name
        dominanceLbl.text = "\(Int(slider.value*100))%"
        calculatePoints()
    }
}
