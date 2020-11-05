//
//  ViewController.swift
//  Reality
//
//  Created by Line on 7/10/2020.
//

import UIKit
import ARKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var coachingOverlay: ARCoachingOverlayView!
    
    @IBOutlet weak var snapshotImage: UIImageView!
    
    var model: String = "Setup" // "Restore"
    
    var setupConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    var eventStreams = [AnyCancellable]()
    var scene: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupGestures()
        self.setupCoachingView()
        self.setupOverlayView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Load the "Box" scene from the "Experience" Reality File
        if model == "Restore" {
            self.runRestoreModel()
        } else if model == "Setup" {
            self.runSetupModel()
        }
    }
    
    func runSetupModel() {
        self.arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins]
        self.arView.session.delegate = nil
        self.initARView()
        self.arView.session.run(setupConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func runRestoreModel() {
        self.arView.debugOptions = []
        self.arView.session.delegate = self
        self.loadExperience(nil)
    }
    
    @objc func singleTap(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: arView)
        for entity in self.arView.entities(at: point) {
            debugPrint(entity.name)
            if entity.name == "devPanel" {
                self.performSegue(withIdentifier: "devSeg", sender: nil)
                break
            } else if entity.name == "monitorPanel" {
                self.performSegue(withIdentifier: "monitorSeg", sender: nil)
                break
            }
        }
    }
    
    @objc func swipeUpDown(gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up:
            self.showSettingPanel()
            break
        case .down:
            self.hideSettingPanel()
            break
        default:
            break
        }
    }
    
    func showSettingPanel() {
        debugPrint("showSettingPanel")
        bottomContraint.constant = -50
        UIView.animate(withDuration: 0.25) {
            self.stackView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    func hideSettingPanel() {
        bottomContraint.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.stackView.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func initARView() {
        self.arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self) { (event) in
            debugPrint("subscribe_event0", event.anchor.name, event)
            if event.isAnchored, let id = event.anchor.anchorIdentifier,
               !event.anchor.name.isEmpty {
                self.anchorMap[id] = event.anchor.name
                debugPrint("subscribe_event1", self.anchorMap)
            }
        }.store(in: &eventStreams)
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        self.arView.addGestureRecognizer(tapGesture)
        
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeUpDown))
        swipeUpGesture.direction = .up
        self.arView.addGestureRecognizer(swipeUpGesture)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeUpDown))
        swipeDownGesture.direction = .down
        self.arView.addGestureRecognizer(swipeDownGesture)
    }
    
    @objc func placeBox() {
        self.runSetupModel()
//        self.navigationController?.popViewController(animated: true)
//        self.loadBoxScene()
    }
    
    @objc func placeDev() {
//        self.performSegue(withIdentifier: "devSeg", sender: nil)
        self.loadDevScene()
    }
    
    @objc func placeMonitor() {
//        self.performSegue(withIdentifier: "monitorSeg", sender: nil)
        self.loadMonitorScene()
    }
    
    @objc func placeVideoAnchor() {
        self.loadMonitorScene()
    }
    
    @objc func discover() {
//        self.loadBox()
    }
    
    func loadDevScene() {
        Experience.loadDevAsync(completion: { [weak self](result) in
            switch result {
            case .success(let entity):
                guard let self = self else { return }
                entity.name = "Dev"
                self.arView.scene.anchors.append(entity)
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        })
    }
    
    func loadMonitorScene() {
        Experience.loadMonitorAsync(completion: { [weak self](result) in
            switch result {
            case .success(let entity):
                guard let self = self else { return }
                entity.name = "Monitor"
                self.arView.scene.anchors.append(entity)
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        })
    }
    
    func loadBoxScene() {
        Experience.loadBoxAsync(completion: { [weak self](result) in
            switch result {
            case .success(let box):
                guard let self = self else { return }
                box.name = "Box"
                self.arView.scene.anchors.append(box)
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        })
    }
    
    func loadVideoScene() {
        Experience.loadVideoAsync(completion: { [weak self](result) in
            switch result {
            case .success(let video):
                guard let self = self else { return }
                video.name = "Video"
                self.arView.scene.anchors.append(video)
                if let videoE = self.videoAnchor() {
                    video.addChild(videoE)
                }
                debugPrint("video", video.anchoring)
                
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        })
    }
    
    func videoAnchor() -> ModelEntity? {
        guard let pathToVideo = Bundle.main.path(forResource: "video", ofType: "mp4") else {
            return nil
        }
        // AVPLAYER
        let videoURL = URL(fileURLWithPath: pathToVideo)
        let avPlayer = AVPlayer(url: videoURL)
        avPlayer.play()
        // ENTITY
//        let mesh = MeshResource.generatePlane(width: 0.96, depth: 0.54)    // 16:9 video
        let mesh = MeshResource.generateBox(width: 0.8, height: 0.45, depth: 0.02)
        let material = VideoMaterial(avPlayer: avPlayer)
        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        return planeEntity
    }
    
    func loadDev() {
        Experience.loadDevAsync(completion: { [weak self](result) in
            switch result {
            case .success(let dev):
                guard let self = self else { return }
                self.arView.scene.anchors.append(dev)
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        })
    }
    
    lazy var anchorMap: [UUID: String] = {
        return [:]
    }()
    
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
    
    lazy var anchorMapURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("anchorMap.dat")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    var anchorMapDataFromFile: Data? {
        return try? Data(contentsOf: anchorMapURL)
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
                    self.loadButton.isEnabled = true
                }
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
            self.saveAnchorMap()
            self.showAlert(title: "Setup Done", message: "Setup Done. Please restart the App")
        }
    }
    
    func clearSaved() {
        do {
            try FileManager.default.removeItem(at: self.mapSaveURL)
            try FileManager.default.removeItem(at: self.anchorMapURL)
        } catch {
            debugPrint("Clear saved map: \(error.localizedDescription)")
//            fatalError("Clear saved map: \(error.localizedDescription)")
        }
    }
    
    func saveAnchorMap() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self.anchorMap, requiringSecureCoding: true)
            try data.write(to: self.anchorMapURL, options: [.atomic])
        } catch {
            fatalError("Can't save anchor map: \(error.localizedDescription)")
        }
    }
    
    func loadAnchorMap() {
        let map: [UUID: String] = {
            guard let data = anchorMapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let dat = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UUID: String]
                    else { fatalError("No ARWorldMap in archive.") }
                return dat
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        self.anchorMap = map
    }
    
    // - Tag: RunWithWorldMap
    @IBAction func loadExperience(_ button: UIButton?) {
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        // Display the snapshot image stored in the world map to aid user in relocalizing.
        if let snapshotData = worldMap.snapshotAnchor?.imageData,
            let snapshot = UIImage(data: snapshotData) {
            self.snapshotImage.image = snapshot
        } else {
            print("No snapshot image in world map")
        }
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
        self.loadAnchorMap()
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.planeDetection = [.vertical, .horizontal]
        arConfiguration.initialWorldMap = worldMap
        self.arView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @objc func resetExperience() {
        self.arView.scene.anchors.removeAll()
        self.snapshotImage.alpha = 0
        self.clearSaved()
        self.runSetupModel()
        self.showAlert(title: "Anchor Removed", message: "Better to restart the app to re-setup")
//        self.arView.session.run(setupConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setupCoachingView() {
        coachingOverlay.activatesAutomatically = true
//        coachingOverlay.setActive(true, animated: true)
        coachingOverlay.goal = .anyPlane
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
    }
    
    func setupOverlayView() {
        self.setupStackView()
    }
    
    lazy var bottomContraint: NSLayoutConstraint = {
        let bottom = stackView.bottomAnchor.constraint(equalTo: self.arView.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        return bottom
    }()
    
    func setupStackView() {
        stackView.alpha = 0
        stackView.addArrangedSubview(resetButton)
        stackView.addArrangedSubview(saveButton)
//        stackView.addArrangedSubview(resetButton)
//        stackView.addArrangedSubview(discoverButton)
        stackView.addArrangedSubview(placeBoxButton)
        stackView.addArrangedSubview(placeMonitorButton)
        stackView.addArrangedSubview(placeDevButton)
        stackView.addArrangedSubview(placeVideoButton)
        self.arView.addSubview(stackView)
        let centerX = stackView.centerXAnchor.constraint(equalTo: self.arView.centerXAnchor)
        NSLayoutConstraint.activate([centerX, self.bottomContraint])
    }
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 10
        stack.axis = .horizontal
        return stack
    }()
    
    private lazy var placeMonitorButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Monitor", for: [.normal])
        button.addTarget(self, action: #selector(placeMonitor), for: .touchUpInside)
        return button
    }()
    
    private lazy var placeDevButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Dev", for: [.normal])
        button.addTarget(self, action: #selector(placeDev), for: .touchUpInside)
        return button
    }()
    
    private lazy var placeVideoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Video", for: [.normal])
        button.addTarget(self, action: #selector(placeVideoAnchor), for: .touchUpInside)
        return button
    }()
    
    private lazy var placeBoxButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Back", for: [.normal])
        button.addTarget(self, action: #selector(placeBox), for: .touchUpInside)
        return button
    }()
    
    //function buttons
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
        button.addTarget(self, action: #selector(loadExperience(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reset", for: [.normal])
        button.addTarget(self, action: #selector(resetExperience), for: .touchUpInside)
        return button
    }()
    
    private lazy var discoverButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle("Discover", for: [.normal])
        button.addTarget(self, action: #selector(discover), for: .touchUpInside)
        return button
    }()
}

extension ViewController: ARCoachingOverlayViewDelegate {
    
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        debugPrint(#function, anchors, anchors.count)
        for anchor in anchors {
            if let scene = anchorMap[anchor.identifier] {
                self.restoreAnchors(scene: scene, anchor: anchor)
            }
        }
        self.arView.session.delegate = nil
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        debugPrint(session)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return false
    }
}

extension ViewController {
    func restoreAnchors(scene: String, anchor: ARAnchor) {
        func completed<T>(result: Swift.Result<T, Swift.Error>) -> Void where T: HasAnchoring {
            switch result {
            case .success(let entity):
//                guard let self = self else { return }
                debugPrint("restore scene")
//                        entity.playAnimation(named: "Behavior")
                self.arView.scene.anchors.append(entity)
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        }
        switch scene {
        case "Dev":
            Experience.restoreDevSceneAsync(a: anchor) { (result) in
                completed(result: result)
            }
            break
        case "Monitor":
            Experience.restoreMonitorSceneAsync(a: anchor) { (result) in
                completed(result: result)
            }
            break
        default:
            break
        }
    }
}
