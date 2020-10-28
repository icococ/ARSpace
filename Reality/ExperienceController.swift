//
//  ExperienceController.swift
//  Reality
//
//  Created by Feng Wang on 10/27/20.
//

import Foundation
import RealityKit
import ARKit
import Combine

func restoreScene<T>(scene: String, a: ARAnchor) throws -> T where T: HasAnchoring {
    guard let realityFileURL = Foundation.Bundle(for: Experience.Box.self).url(forResource: "Experience", withExtension: "reality") else {
        throw Experience.LoadRealityFileError.fileNotFound("Experience.reality")
    }
    let realityFileSceneURL = realityFileURL.appendingPathComponent(scene, isDirectory: false)
    let entity = try T.load(contentsOf: realityFileSceneURL)
    let ae = AnchorEntity(anchor: a)
    ae.addChild(entity)
    let box = T()
    box.anchoring = ae.anchoring
    box.addChild(ae)
    return box
}


extension Experience {
    private static var streams = [Combine.AnyCancellable]()
    
    static func restoreDevSceneAsync(a: ARAnchor,
                                     completion: @escaping (Swift.Result<Experience.Dev, Swift.Error>) -> Void) {
        guard let realityFileURL = Foundation.Bundle(for: Experience.Dev.self).url(forResource: "Experience", withExtension: "reality") else {
            completion(.failure(Experience.LoadRealityFileError.fileNotFound("Experience.reality")))
            return
        }
        let realityFileSceneURL = realityFileURL.appendingPathComponent("Dev", isDirectory: false)
        var cancellable: Combine.AnyCancellable?
        let loadRequest = Experience.Box.loadAsync(contentsOf: realityFileSceneURL)
        cancellable = loadRequest.sink(receiveCompletion: { loadCompletion in
            if case let .failure(error) = loadCompletion {
                completion(.failure(error))
            }
            streams.removeAll { $0 === cancellable }
        }, receiveValue: { entity in
            let ae = AnchorEntity(anchor: a)
            ae.addChild(entity)
            let scene = Experience.Dev()
            scene.anchoring = ae.anchoring
            scene.addChild(ae)
            completion(.success(scene))
        })
        cancellable?.store(in: &streams)
    }
    
    static func restoreMonitorSceneAsync(a: ARAnchor, completion: @escaping (Swift.Result<Experience.Dev, Swift.Error>) -> Void) {
        guard let realityFileURL = Foundation.Bundle(for: Experience.Dev.self).url(forResource: "Experience", withExtension: "reality") else {
            completion(.failure(Experience.LoadRealityFileError.fileNotFound("Experience.reality")))
            return
        }
        let realityFileSceneURL = realityFileURL.appendingPathComponent("Monitor", isDirectory: false)
        var cancellable: Combine.AnyCancellable?
        let loadRequest = Experience.Box.loadAsync(contentsOf: realityFileSceneURL)
        cancellable = loadRequest.sink(receiveCompletion: { loadCompletion in
            if case let .failure(error) = loadCompletion {
                completion(.failure(error))
            }
            streams.removeAll { $0 === cancellable }
        }, receiveValue: { entity in
            let ae = AnchorEntity(anchor: a)
            ae.addChild(entity)
            let scene = Experience.Dev()
            scene.anchoring = ae.anchoring
            scene.addChild(ae)
            completion(.success(scene))
        })
        cancellable?.store(in: &streams)
    }
    
    static func restoreBoxSceneAsync(scene: String, a: ARAnchor,
                                     completion: @escaping (Swift.Result<Experience.Box, Swift.Error>) -> Void) {
        guard let realityFileURL = Foundation.Bundle(for: Experience.Box.self).url(forResource: "Experience", withExtension: "reality") else {
            completion(.failure(Experience.LoadRealityFileError.fileNotFound("Experience.reality")))
            return
        }
        let realityFileSceneURL = realityFileURL.appendingPathComponent(scene, isDirectory: false)
        var cancellable: Combine.AnyCancellable?
        let loadRequest = Experience.Box.loadAsync(contentsOf: realityFileSceneURL)
        cancellable = loadRequest.sink(receiveCompletion: { loadCompletion in
            if case let .failure(error) = loadCompletion {
                completion(.failure(error))
            }
            streams.removeAll { $0 === cancellable }
        }, receiveValue: { entity in
            let ae = AnchorEntity(anchor: a)
            ae.addChild(entity)
            let scene = Experience.Box()
            scene.anchoring = ae.anchoring
            scene.addChild(ae)
            completion(.success(scene))
        })
        cancellable?.store(in: &streams)
    }
    
    static func restoreScene<T>(scene: String, a: ARAnchor) throws -> T where T: HasAnchoring {
        guard 
            let realityFileURL = Foundation.Bundle(for: Experience.Box.self).url(forResource: "Experience", withExtension: "reality") else {
            throw Experience.LoadRealityFileError.fileNotFound("Experience.reality")
        }
        let realityFileSceneURL = realityFileURL.appendingPathComponent(scene, isDirectory: false)
        let entity = try T.load(contentsOf: realityFileSceneURL)
        let ae = AnchorEntity(anchor: a)
        ae.addChild(entity)
        let box = T()
        box.anchoring = ae.anchoring
        box.addChild(ae)
        return box
    }
    
    public static func loadBoxA(a: ARAnchor) throws -> Experience.Box {
        guard let realityFileURL = Foundation.Bundle(for: Experience.Box.self).url(forResource: "Experience", withExtension: "reality") else {
            throw Experience.LoadRealityFileError.fileNotFound("Experience.reality")
        }
        let realityFileSceneURL = realityFileURL.appendingPathComponent("Box", isDirectory: false)
        let entity = try Experience.Box.load(contentsOf: realityFileSceneURL)
        let ae = AnchorEntity(anchor: a)
        ae.addChild(entity)
        let box = Experience.Box()
        box.anchoring = ae.anchoring
        box.addChild(ae)
        return box
    }

    public static func createDevModel(from anchorEntity: RealityKit.AnchorEntity) -> Experience.Dev {
        let dev = Experience.Dev()
        dev.anchoring = anchorEntity.anchoring
        dev.addChild(anchorEntity)
        return dev
    }
    
    public static func createVideoModel(from anchorEntity: RealityKit.AnchorEntity) -> Experience.Video {
        let dev = Experience.Video()
        dev.anchoring = anchorEntity.anchoring
        dev.addChild(anchorEntity)
        return dev
    }
    
    public static func createBoxModel(from anchorEntity: RealityKit.AnchorEntity) -> Experience.Box {
        let dev = Experience.Box()
        dev.anchoring = anchorEntity.anchoring
        dev.addChild(anchorEntity)
        return dev
    }

}
