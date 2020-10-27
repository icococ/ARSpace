//
//  ExperienceController.swift
//  Reality
//
//  Created by Feng Wang on 10/27/20.
//

import Foundation
import RealityKit
import ARKit

func restoreScene<T>(scene: String, a: ARAnchor) throws -> T where T: HasAnchoring {
    guard let realityFileURL = Foundation.Bundle(for: Experience.Box.self).url(forResource: "Experience", withExtension: "reality") else {
        throw Experience.LoadRealityFileError.fileNotFound("Experience.reality")
    }
    let realityFileSceneURL = realityFileURL.appendingPathComponent(scene, isDirectory: false)
//    let req = T.loadAsync(contentsOf: realityFileSceneURL)
//    req.sink { (<#Subscribers.Completion<Error>#>) in
//        <#code#>
//    } receiveValue: { (<#Entity#>) in
//        <#code#>
//    }

    let entity = try T.loadAsync(contentsOf: realityFileSceneURL)
    let ae = AnchorEntity(anchor: a)
    ae.addChild(entity)
    let box = T()
    box.anchoring = ae.anchoring
    box.addChild(ae)
    return box
}

extension Experience {
    
    static func restoreScene<T>(scene: String, a: ARAnchor) throws -> T where T: HasAnchoring {
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
