//
//  PatrolScoreCell.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//

import UIKit

class PatrolScoreCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var denominatorView: CircleView!
    @IBOutlet weak var numeratorView: CircleView!
    
    
    var score = 0
    
    func setupView(patrol: Patrol) {
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 300),
            self.widthAnchor.constraint(equalToConstant: 82)
        ])
        
        titleLbl.text = patrol.name
        // Calculate maximum score
        guard let maxScore = CommunityService.instance.selectedGroup.patrols.compactMap({ $0.score }).max() else {
            print("No scores found in patrols.")
            return
        }
        // Calculate height of view relative to DenominatorView
        let superHeight = denominatorView.bounds.height
        let factor: CGFloat = superHeight / CGFloat(maxScore)
        guard let score = patrol.score else {
            print("Patrol score is nil.")
            return
        }
        let newHeight = CGFloat(score) * factor
        // Create the view
        numeratorView.translatesAutoresizingMaskIntoConstraints = false
        numeratorView.backgroundColor = UIColor.blue  // Set desired background color
        numeratorView.layer.cornerRadius = numeratorView.bounds.width / 2  // Set corner radius based on width
        numeratorView.clipsToBounds = true  // Ensure subviews respect corner radius
        
        // Add to DenominatorView

        // Calculate final frame (bottom of DenominatorView)
        let finalFrame = CGRect(x: 2, y: denominatorView.bounds.height - newHeight + 10, width: denominatorView.bounds.width - 4, height: newHeight)
//        let initialFrame = CGRect(x: 2, y: denominatorView.bounds.height + 10, width: denominatorView.bounds.width - 4, height: 10)
        let initialFrame = CGRect(x: 2, y: denominatorView.bounds.height + 10 - CGFloat(self.score)*factor, width: denominatorView.bounds.width - 4, height: CGFloat(self.score)*factor)

        // Set final frame (height zero) and prepare for animation
        numeratorView.frame = initialFrame
        numeratorView.layer.cornerRadius = numeratorView.bounds.width / 2  // Adjust corner radius initially
        
        // Calculate initial frame (growing upwards from bottom)
        
        // Animate the height change
        UIView.animate(withDuration: 1.0) {
            self.numeratorView.frame = finalFrame
        }
        self.score = patrol.score

    }

    
}
