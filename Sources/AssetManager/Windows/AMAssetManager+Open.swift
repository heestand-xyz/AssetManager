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

    func openImagesAsURLs(completion: @escaping (Result<[AMAssetURLFile], Error>) -> ()) {
        openFiles(title: "Import Images",
                  allowedFileTypes: AMAssetManager.AssetType.image.types, completion: completion)
    }
    
    func openImages(completion: @escaping (Result<[AMAssetFile], Error>) -> ()) {
        openFiles(title: "Import Images",
                  allowedFileTypes: AMAssetManager.AssetType.image.types) { result in
            switch result {
            case .success(let urlFiles):
                var imageFiles: [AMAssetFile] = []
                for urlFile in urlFiles {
                    guard let imageFile = AMAssetManager.AssetType.image(url: urlFile.url) else {
                        completion(.failure(AssetError.badImageData))
                        return
                    }
                    imageFiles.append(imageFile)
                }
                completion(.success(imageFiles))
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
    
    func openVideos(completion: @escaping (Result<[AMAssetURLFile], Error>) -> ()) {
        openFiles(title: "Import Videos",
                  allowedFileTypes: AMAssetManager.AssetType.video.types, completion: completion)
    }
    
    func openMedia(completion: @escaping (Result<AMAssetFile?, Error>) -> ()) {
        openFile(title: "Import Media",
                 allowedFileTypes: AMAssetManager.AssetType.media.types) { result in
            switch result {
            case .success(let urlFile):
                if let urlFile {
                    if AssetType.isImage(url: urlFile.url) {
                        guard let assetFile: AMAssetFile = AssetType.image(url: urlFile.url) else {
                            completion(.failure(AssetError.badImageData))
                            return
                        }
                        completion(.success(assetFile))
                        return
                    }
                    completion(.success(urlFile))
                } else {
                    completion(.success(nil))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func openMedia(completion: @escaping (Result<[AMAssetFile], Error>) -> ()) {
        openFiles(title: "Import Media",
                  allowedFileTypes: AMAssetManager.AssetType.media.types) { result in
            switch result {
            case .success(let urlFiles):
                let files: [AMAssetFile] = urlFiles.compactMap { urlFile in
                    if AssetType.isImage(url: urlFile.url) {
                        guard let assetFile: AMAssetFile = AssetType.image(url: urlFile.url) else {
                            return nil
                        }
                        return assetFile
                    }
                    return urlFile
                }
                completion(.success(files))
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
    
    func openFiles(title: String,
                   allowedFileTypes: [UTType]?,
                   completion: @escaping (Result<[AMAssetURLFile], Error>) -> ()) {
        
        let openPanel = NSOpenPanel()
        
        openPanel.title = title
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = allowedFileTypes ?? []
        
        openPanel.begin { response in
            guard response == .OK else {
                completion(.success([]))
                return
            }
            var files: [AMAssetURLFile] = []
            for url in openPanel.urls {
                guard url.startAccessingSecurityScopedResource()
                else {
                    completion(.failure(AssetOpenError.noFileAccess))
                    return
                }
                let name: String = url.deletingPathExtension().lastPathComponent
                url.stopAccessingSecurityScopedResource()
                let file = AMAssetURLFile(name: name, url: url)
                files.append(file)
            }
            completion(.success(files))
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
