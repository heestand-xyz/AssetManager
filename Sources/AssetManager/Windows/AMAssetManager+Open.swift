//
//  AMAssetManager+Open.swift
//  Circles
//
//  Created by Anton Heestand on 2021-05-17.
//

#if os(macOS)

import AppKit
import AVKit

extension AMAssetManager {
    
    enum AssetOpenError: LocalizedError {
        case urlNotFound
        case noFileAccess
        case badImageData
        var errorDescription: String? {
            switch self {
            case .urlNotFound:
                return "Asset Manager - Open - URL Not Found"
            case .noFileAccess:
                return "Asset Manager - Open - No File Access"
            case .badImageData:
                return "Asset Manager - Open - Bad Image data"
            }
        }
    }
    
    func openImage(completion: @escaping (Result<AMAssetImageFile?, Error>) -> ()) {
        openFile(title: "Import Image",
                 allowedFileTypes: AMAssetManager.AssetType.image.types) { result in
            switch result {
            case .success(let assetURLFile):
                guard let assetURLFile: AMAssetURLFile = assetURLFile else {
                    completion(.success(nil))
                    return
                }
                do {
                    let data: Data = try Data(contentsOf: assetURLFile.url)
                    guard let image = NSImage(data: data) else {
                        completion(.failure(AssetError.badImageData))
                        return
                    }
                    let imageFile = AMAssetImageFile(name: assetURLFile.name, image: image)
                    completion(.success(imageFile))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func openVideo(completion: @escaping (Result<AMAssetURLFile?, Error>) -> ()) {
        openFile(title: "Import Video",
                 allowedFileTypes: AMAssetManager.AssetType.video.types,
                 completion: completion)
    }
    
    func openFile(title: String,
                  allowedFileTypes: [UTType]?,
                  completion: @escaping (Result<AMAssetURLFile?, Error>) -> ()) {
        
        let openPanel = NSOpenPanel()
        
        openPanel.title = title
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = allowedFileTypes ?? []
        
        openPanel.begin { response in
            guard response == .OK else {
                completion(.success(nil))
                return
            }
            guard let url: URL = openPanel.url else {
                completion(.failure(AssetOpenError.urlNotFound))
                return
            }
            guard url.startAccessingSecurityScopedResource() else {
                completion(.failure(AssetOpenError.noFileAccess))
                return
            }
            let name: String = url.deletingPathExtension().lastPathComponent
            url.stopAccessingSecurityScopedResource()
            let assetUrlFile = AMAssetURLFile(name: name, url: url)
            completion(.success(assetUrlFile))
        }
    }
    
    func openFolder(title: String,
                    completion: @escaping (Result<URL?, Error>) -> ()) {
        
        let openPanel = NSOpenPanel()
        
        openPanel.title = title
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = []
        
        openPanel.begin { response in
            guard response == .OK else {
                completion(.success(nil))
                return
            }
            guard let url: URL = openPanel.url else {
                completion(.failure(AssetOpenError.urlNotFound))
                return
            }
            completion(.success(url))
        }
    }
}

#endif
