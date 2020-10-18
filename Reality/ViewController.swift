//
//  ViewController.swift
//  Reality
//
//  Created by Line on 7/10/2020.
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var coachingOverlay: ARCoachingOverlayView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.planeDetection = [.vertical, .horizontal]
        arView.session.run(arConfiguration)
        self.setupARView()
        self.setupStackView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Load the "Box" scene from the "Experience" Reality File
        
    }
    
    @objc func discover() {
//        self.setupARView()
        self.loadBox()
//        self.loadWall()
        
    }
    
    func loadWall() {
        Experience.loadWallAsync(completion: { [weak self](result) in
            switch result {
            case .success(let wall):
                guard let self = self else { return }
                
//                if self.gameAnchor == nil {
//                    self.gameAnchor = game
//                    self.observer?.gameControllerContentDidLoad(self)
//                }
//
//                if case let .waitingForContent(nextState) = self.currentState {
//                    self.transition(to: nextState)
//                }
                self.arView.scene.anchors.append(wall)
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
            
            
        })
    }
    
    func loadBox() {
        let boxAnchor = try! Experience.loadBox()
        let videoAnchor = self.videoAnchor()
    
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
        if let video = videoAnchor {
            debugPrint(video)
            arView.scene.anchors.append(video)
        }
    }
    
    func videoAnchor() -> AnchorEntity? {
        guard let pathToVideo = Bundle.main.path(forResource: "video", ofType: "mp4") else {
            return nil
        }
        // AVPLAYER
        let videoURL = URL(fileURLWithPath: pathToVideo)
        let avPlayer = AVPlayer(url: videoURL)
        avPlayer.play()
        // ENTITY
        let mesh = MeshResource.generatePlane(width: 0.96, depth: 0.54)    // 16:9 video
        let material = VideoMaterial(avPlayer: avPlayer)
        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        planeEntity.transform.rotation = simd_quatf(angle: Float.pi / 180 * 90, axis: [1, 0, 0])
        
//        let anchor = AnchorEntity(.plane(.vertical,
//                                    classification: .table,
//                                     minimumBounds: [0.3, 0.3]))
        let anchor = AnchorEntity(world: [0, 0, -2])
        anchor.addChild(planeEntity)
//        anchor.transform.rotation = simd_quatf(angle: Float.pi / 180 * 90, axis: [1, 0, 0])
        return anchor
    }
    
    func setupARView() {
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.setActive(true, animated: true)
        coachingOverlay.goal = .anyPlane
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        self.arView.session.delegate = self
        arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins]
    }
    
    func setupStackView() {
        stackView.addArrangedSubview(saveButton)
        stackView.addArrangedSubview(loadButton)
        stackView.addArrangedSubview(discoverButton)
        self.arView.addSubview(stackView)
        let centerX = stackView.centerXAnchor.constraint(equalTo: self.arView.centerXAnchor)
        let bottom = stackView.bottomAnchor.constraint(equalTo: self.arView.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        NSLayoutConstraint.activate([centerX, bottom])
    }
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    /// - Tag: GetWorldMap
    @IBAction func saveExperience(_ button: UIButton) {
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else {
                self.showAlert(title: "Can't get current world map", message: error!.localizedDescription);
                return
            }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.arView)
                else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.mapSaveURL, options: [.atomic])
                DispatchQueue.main.async {
//                    self.loadExperienceButton.isHidden = false
//                    self.loadExperienceButton.isEnabled = true
                }
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Persistence: Saving and Loading
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 10
        stack.axis = .horizontal
        return stack
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: [.normal])
        button.addTarget(self, action: #selector(saveExperience), for: .touchUpInside)
        return button
    }()
    
    private lazy var loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Load", for: [.normal])
        button.addTarget(self, action: #selector(saveExperience), for: .touchUpInside)
        return button
    }()
    
    private lazy var discoverButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Discover", for: [.normal])
        button.addTarget(self, action: #selector(discover), for: .touchUpInside)
        return button
    }()
    
    
}

extension ViewController: ARCoachingOverlayViewDelegate {
    
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        debugPrint(session)
    }
}
