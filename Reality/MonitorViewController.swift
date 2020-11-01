//
//  MonitorViewController.swift
//  Reality
//
//  Created by Line on 1/11/2020.
//

import UIKit
import AVKit

class MonitorViewController: UIViewController {
    @IBOutlet weak var videoContainerView: UIView!
    
    private(set) var playerViewControllerIfLoaded: AVPlayerViewController? {
        didSet {
            guard playerViewControllerIfLoaded != oldValue else {
                return
            }
            // 1) Invalidate KVO, delegate, player, status for old player view controller
//            readyForDisplayObservation?.invalidate()
//            readyForDisplayObservation = nil
            
            if oldValue?.delegate === self {
                oldValue?.delegate = nil
            }
            
            // 2) Set up the new playerViewController
            
            if let playerViewController = playerViewControllerIfLoaded {
                // 2a) Assign self as delegate
                playerViewController.delegate = self
                // 2b) Create player for video
                if let pathToVideo = Bundle.main.path(forResource: "video", ofType: "mp4") {
                    let videoURL = URL(fileURLWithPath: pathToVideo)
                    let playerItem = AVPlayerItem(url: videoURL)
                    // Note that we seek to the resume time *before* giving the player view controller the player.
                    // This is more efficient and provides better UI since media is only loaded at the actual start time.
                    playerItem.seek(to: CMTime(seconds: 0, preferredTimescale: 90_000), completionHandler: nil)
                    playerViewController.player = AVPlayer(playerItem: playerItem)
                }
                
                // 2c) Update ready for display status and start observing the property
                if playerViewController.isReadyForDisplay {
//                    status.insert(.readyForDisplay)
                }
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        self.playerViewControllerIfLoaded = AVPlayerViewController()
        if let playerViewController = playerViewControllerIfLoaded {
            self.addChild(playerViewController)
            playerViewController.view.backgroundColor = UIColor.white
            self.videoContainerView.addSubview(playerViewController.view)
            playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                playerViewController.view.centerXAnchor.constraint(equalTo: self.videoContainerView.centerXAnchor),
                playerViewController.view.centerYAnchor.constraint(equalTo: self.videoContainerView.centerYAnchor),
                playerViewController.view.widthAnchor.constraint(equalTo: self.videoContainerView.widthAnchor),
                playerViewController.view.heightAnchor.constraint(equalTo: self.videoContainerView.heightAnchor)
            ])
            playerViewController.didMove(toParent: parent)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension MonitorViewController: AVPlayerViewControllerDelegate {
    
}
