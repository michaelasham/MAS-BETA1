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
    @IBOutlet weak var ptsLbl: UILabel!
    
    var score = 0
    var currentHeight: CGFloat = 0.0
    
    
    func setupView(patrol: Patrol) {
        print(patrol.score!)
        let group = CommunityService.instance.checkIfUserIsLeader()
        if group.id != "" {
            ptsLbl.isHidden = false
            animateLabelChange(to: patrol.score!)
        }
        print(patrol.score!)

        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]
        numeratorView.backgroundColor = colors.randomElement() ?? .systemGray
        print(patrol.score!)

        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 300),
            self.widthAnchor.constraint(equalToConstant: 82)
        ])
        print(patrol.score!)

        titleLbl.text = patrol.name
        // Calculate maximum score
        guard var maxScore = CommunityService.instance.patrols.compactMap({ $0.score! }).max() else {
            print("No scores found in patrols.")
            return
        }
        print(patrol.score!)

        maxScore = max(maxScore, patrol.score!, 1)
        // Calculate height of view relative to DenominatorView
        let superHeight = denominatorView.bounds.height
        print(superHeight, CGFloat(abs(maxScore)))
        let factor: CGFloat = superHeight / CGFloat(abs(maxScore))
        guard let score = patrol.score else {
            print("Patrol score is nil.")
            return
        }
        print(patrol.score!)

        let newHeight = CGFloat(patrol.score!) * factor
        // Create the view
        numeratorView.translatesAutoresizingMaskIntoConstraints = false
        numeratorView.layer.cornerRadius = numeratorView.bounds.width / 2  // Set corner radius based on width
        numeratorView.clipsToBounds = true  // Ensure subviews respect corner radius
        
        // Add to DenominatorView

        // Calculate final frame (bottom of DenominatorView)
        let finalFrame = CGRect(x: 2, y: denominatorView.bounds.height - newHeight + 2, width: denominatorView.bounds.width - 4, height: newHeight - 3)
//        let initialFrame = CGRect(x: 2, y: denominatorView.bounds.height + 10, width: denominatorView.bounds.width - 4, height: 10)
        let initialFrame = CGRect(x: 2, y: denominatorView.bounds.height - currentHeight + 2, width: denominatorView.bounds.width - 4, height: currentHeight - 3)

        // Set final frame (height zero) and prepare for animation
        numeratorView.frame = initialFrame
        numeratorView.layer.cornerRadius = numeratorView.bounds.width / 2  // Adjust corner radius initially
        print(patrol.score!)

        // Calculate initial frame (growing upwards from bottom)
        
        // Animate the height change
        print(finalFrame)
        UIView.animate(withDuration: 1.0) {
            self.numeratorView.frame = finalFrame
        }
        self.score = patrol.score!
        self.currentHeight = newHeight
        print(patrol.score!)

    }
    
    func animateLabelChange(to finalValue: Int) {
        let currentValue = score
        
        let duration: TimeInterval = 1.0
        let steps = abs(finalValue - currentValue) // The number of steps to reach the final value
        let interval = duration / Double(steps) // Calculate the time interval for each step
        
        let stepValue = finalValue > currentValue ? 1 : -1 // Determine the direction of the counting

        var currentStep = 0
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1
            let newValue = currentValue + (stepValue * currentStep)
            self.ptsLbl.text = "\(newValue) pts"
            
            if newValue == finalValue {
                timer.invalidate() // Stop the timer when we reach the final value
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
}
