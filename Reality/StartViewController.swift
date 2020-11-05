//
//  StartViewController.swift
//  Reality
//
//  Created by Feng Wang on 11/4/20.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var snapshotImage: UIImageView!
    
    @IBOutlet weak var startButton: UIButton!
    
    lazy var snapshot: UIImage? = {
        return MapController.loadSnapshot() 
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let snapshot = self.snapshot {
            snapshotImage.image = snapshot
            startButton.setTitle("Start To Explore", for: [.normal])
        } else {
            startButton.setTitle("Setup", for: [.normal])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "startSeg") {
            if let vc = segue.destination as? ViewController {
                if let _ = self.snapshot {
                    vc.model = "Restore"
                } else {
                    vc.model = "Setup"
                }
            }
        }
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
