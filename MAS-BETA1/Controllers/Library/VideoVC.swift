//
//  VideoViewController.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 20/06/2024.
//
import UIKit
import AVKit
import AVFoundation

class VideoViewController: UIViewController {
    
    var videoURL: URL?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoURL = videoURL else {
            print("No video URL found")
            return
        }
        
        let player = AVPlayer(url: videoURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        if let playerVC = playerViewController {
            // Add the player view controller's view to the view hierarchy
            self.addChild(playerVC)
            self.view.addSubview(playerVC.view)
            playerVC.view.frame = self.view.bounds
            playerVC.didMove(toParent: self)
            
            // Start playing the video
            player.play()
        }
    }
    
//    // To present the video player in fullscreen mode initially
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        if let playerVC = playerViewController {
//            present(playerVC, animated: true) {
//                playerVC.player?.play()
//            }
//        }
//    }
}
