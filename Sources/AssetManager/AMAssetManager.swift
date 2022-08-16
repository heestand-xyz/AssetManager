//
//  AMAssetManager.swift
//  Pixel Nodes (iOS)
//
//  Created by Anton Heestand on 2021-05-17.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif
import UniformTypeIdentifiers
import PhotosUI

public final class AMAssetManager: ObservableObject {
    
    public enum AssetSource {
        case photos
        case files
    }
    
    public enum AssetType {
        case image
        case video
        case file(extension: String)
        public var types: [UTType] {
            switch self {
            case .image:
                return [.image, .png, .jpeg, .heic, .heif, .tiff, .bmp, .gif, .icns]
            case .video:
                return [.video, .movie, .mpeg4Movie, .quickTimeMovie, .mpeg2Video]
            case .file(let filenameExtension):
                if let type = UTType(filenameExtension: filenameExtension) {
                    return [type]
                }
                return []
            }
        }
        #if os(iOS)
        public var filter: PHPickerFilter? {
            switch self {
            case .image:
                return .images
            case .video:
                return .videos
            case .file:
                return nil
            }
        }
        #endif
    }
    
    enum AssetError: LocalizedError {
        case badImageData
        case badPhotosObject
        case fileExtensionNotSupported(_ fileExtension: String)
        var errorDescription: String? {
            switch self {
            case .badImageData:
                return "Asset Manager - Bad Image data"
            case .badPhotosObject:
                return "Asset Manager - Bad Photos Object"
            case .fileExtensionNotSupported(let fileExtension):
                return "Asset Manager - File Extension Not Supported (\(fileExtension))"
            }
        }
    }
    
    public enum ImageAssetFormat {
        case png
        case jpg(compressionQuality: CGFloat)
        var filenameExtension: String {
            switch self {
            case .png:
                return "png"
            case .jpg:
                return "jpg"
            }
        }
    }
    
    #if os(iOS)
    
    @Published var showOpenFilePicker: Bool = false
    var fileTypes: [UTType]?
    var fileSelectedCallback: ((URL?) -> ())?
    
    @Published var showSaveFilePicker: Bool = false
    var fileUrl: URL?
    
    @Published var showPhotosPicker: Bool = false
    var photosFilter: PHPickerFilter?
    var photosSelectedCallback: ((Any?) -> ())?
    
    @Published var showShare: Bool = false
    var shareItem: Any?
    
//    private var imageSaveCompletionHandler: ((Error?) -> ())?
    
    #endif
    
    public init() {}
}

extension AMAssetManager {
    
    #if os(iOS)
    
    public func share(image: AMImage) {
        shareItem = image
        showShare = true
    }
    
    public func share(url: URL) {
        shareItem = url
        showShare = true
    }
    
    #endif
    
    public func importImage(
        from source: AssetSource
    ) async throws -> AMAssetImageFile? {
        try await withCheckedThrowingContinuation { continuation in
            importImage(from: source) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importImage(
        from source: AssetSource,
        completion: @escaping (Result<AMAssetImageFile?, Error>) -> ()
    ) {
        importAsset(.image, from: source) { result in
            switch result {
            case .success(let assetFile):
                guard let assetFile: AMAssetFile = assetFile else {
                    completion(.success(nil))
                    return
                }
                guard let assetImageFile: AMAssetImageFile = assetFile as? AMAssetImageFile else {
                    completion(.success(nil))
                    return
                }
                completion(.success(assetImageFile))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func importVideo(
        from source: AssetSource
    ) async throws -> AMAssetURLFile? {
        try await withCheckedThrowingContinuation { continuation in
            importVideo(from: source) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importVideo(
        from source: AssetSource,
        completion: @escaping (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        importAsset(.video, from: source) { result in
            switch result {
            case .success(let assetFile):
                guard let assetFile: AMAssetFile = assetFile else {
                    completion(.success(nil))
                    return
                }
                guard let assetURLFile: AMAssetURLFile = assetFile as? AMAssetURLFile else {
                    completion(.success(nil))
                    return
                }
                completion(.success(assetURLFile))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func importFile(
        filenameExtension: String
    ) async throws -> AMAssetURLFile? {
        try await withCheckedThrowingContinuation { continuation in
            importFile(filenameExtension: filenameExtension) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importFile(
        filenameExtension: String,
        completion: @escaping (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        importAsset(.file(extension: filenameExtension), from: .files) { result in
            switch result {
            case .success(let assetFile):
                guard let assetFile: AMAssetFile = assetFile else {
                    completion(.success(nil))
                    return
                }
                guard let assetURLFile: AMAssetURLFile = assetFile as? AMAssetURLFile else {
                    completion(.success(nil))
                    return
                }
                completion(.success(assetURLFile))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func importAnyFile() async throws -> AMAssetURLFile? {
        try await withCheckedThrowingContinuation { continuation in
            importAnyFile() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importAnyFile(
        completion: @escaping (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        importAsset(nil, from: .files) { result in
            switch result {
            case .success(let assetFile):
                guard let assetFile: AMAssetFile = assetFile else {
                    completion(.success(nil))
                    return
                }
                guard let assetURLFile: AMAssetURLFile = assetFile as? AMAssetURLFile else {
                    completion(.success(nil))
                    return
                }
                completion(.success(assetURLFile))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
//    public func saveImageToFiles(_ image: AMImage, as format: ImageAssetFormat = .png) async throws {
//        let _: Void = try await withCheckedThrowingContinuation { continuation in
//            saveImageToFiles(image, as: format) { error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                continuation.resume()
//            }
//        }
//    }
    
    public func saveImageToFiles(
        _ image: AMImage,
        as format: ImageAssetFormat = .png
//        completion: @escaping (Error?) -> ()
    ) {
        
        let url: URL = FileManager.default.temporaryDirectory
            .appendingPathExtension("image-asset-\(UUID().uuidString).\(format.filenameExtension)")
        
        let data: Data
        switch format {
        case .png:
            guard let pngData = image.pngData() else {
//                completion(AssetError.badImageData)
                return
            }
            data = pngData
        case .jpg(let compressionQuality):
            guard let jpgData = image.jpegData(compressionQuality: compressionQuality) else {
//                completion(AssetError.badImageData)
                return
            }
            data = jpgData
        }
        
        do {
            try data.write(to: url)
            
            saveToFiles(url: url)/* { error in
                
                try? FileManager.default.removeItem(at: url)
                
                completion(error)
            }*/
        } catch {
//            completion(error)
        }
    }
    
//    public func saveToFiles(
//        url: URL
//    ) async throws {
//        let _: Void = try await withCheckedThrowingContinuation { continuation in
//            saveToFiles(url: url) { error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                continuation.resume()
//            }
//        }
//    }
    
    public func saveToFiles(
        url: URL//, completion: @escaping (Error?) -> ()
    ) {
        #if os(iOS)
        fileUrl = url
        showSaveFilePicker = true
        #elseif os(macOS)
        saveFile(url: url, completion: nil)
        #endif
    }
    
    #if os(iOS)
   
//    public func saveImageToPhotos(
//        _ image: AMImage
//    ) async throws {
//        let _: Void = try await withCheckedThrowingContinuation { continuation in
//            saveImageToPhotos(image) { error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                continuation.resume()
//            }
//        }
//    }
    
    public func saveImageToPhotos(
        _ image: AMImage/*, completion: @escaping (Error?) -> ()*/
    ) {
        UIImageWriteToSavedPhotosAlbum(image, self, nil/*#selector(saveCompleted)*/, nil)
//        imageSaveCompletionHandler = completion
    }
      
//    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//        imageSaveCompletionHandler?(error)
//    }
    
    public func saveVideoToPhotos(
        url: URL
    ) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            saveVideoToPhotos(url: url) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }
    
    public func saveVideoToPhotos(
        url: URL, completion: @escaping (Error?) -> ()
    ) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: url, options: nil)
            }) { result, error in
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    public func requestAuthorization(
        completion: @escaping () -> ()
    ) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else if PHPhotoLibrary.authorizationStatus() == .authorized {
            completion()
        }
    }
    
    #endif
}

extension AMAssetManager {
    
    private func importAsset(
        _ type: AssetType?,
        from source: AssetSource,
        completion: @escaping (Result<AMAssetFile?, Error>) -> ()
    ) {
        switch source {
        case .files:
            #if os(macOS)
            if let type = type {
                switch type {
                case .image:
                    openImage { result in
                        switch result {
                        case .success(let assetImageFile):
                            completion(.success(assetImageFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .video:
                    openVideo { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .file(let fileExtension):
                    guard let fileType = UTType(filenameExtension: fileExtension) else { return }
                    openFile(title: "Open \(fileExtension.uppercased()) File", allowedFileTypes: [fileType]) { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            } else {
                openFile(title: "Open File", allowedFileTypes: nil) { result in
                    switch result {
                    case .success(let assetURLFile):
                        completion(.success(assetURLFile))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            #elseif os(iOS)
            fileTypes = type?.types ?? []
            fileSelectedCallback = { [weak self] url in
                self?.fileTypes = nil
                self?.showOpenFilePicker = false
                self?.fileSelectedCallback = nil
                guard let url: URL = url else {
                    completion(.success(nil))
                    return
                }
                let name: String = url.deletingPathExtension().lastPathComponent
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if case .image = type {
                    guard let image: UIImage = UIImage(contentsOfFile: url.path) else {
                        completion(.failure(AssetError.badImageData))
                        return
                    }
                    completion(.success(AMAssetImageFile(name: name, image: image)))
                } else {
                    completion(.success(AMAssetURLFile(name: name, url: url)))
                }
            }
            showOpenFilePicker = true
            #endif
        case .photos:
            #if os(iOS)
            guard let filter: PHPickerFilter = type?.filter else { return }
            photosFilter = filter
            photosSelectedCallback = { [weak self] object in
                self?.photosFilter = nil
                self?.showPhotosPicker = false
                self?.photosSelectedCallback = nil
                guard let object: Any = object else {
                    completion(.success(nil))
                    return
                }
                if case .image = type {
                    guard let image: UIImage = object as? UIImage else {
                        completion(.failure(AssetError.badPhotosObject))
                        return
                    }
                    completion(.success(AMAssetImageFile(name: nil, image: image)))
                } else {
                    guard let url: URL = object as? URL else {
                        completion(.failure(AssetError.badPhotosObject))
                        return
                    }
                    completion(.success(AMAssetURLFile(name: nil, url: url)))
                }
            }
            showPhotosPicker = true
            #endif
        }
    }
}

extension AMAssetManager {
    
    func dropImages(providers: [NSItemProvider], completion: @escaping ([AMImage]) -> ()) {
        
        var providers: [NSItemProvider] = providers
        var images: [AMImage] = []
        
        func next() {
            
            if !providers.isEmpty {
                
                let provider = providers.removeFirst()
             
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    
                    provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                        
                        guard error == nil,
                              let data: Data = data,
                              let image = AMImage(data: data) else {
                            next()
                            return
                        }
                        
                        images.append(image)
                        
                        next()
                    }
                } else {
                    next()
                }
                
            } else {
                completion(images)
                return
            }
        }
        
        next()
    }
    
    func dropVideos(providers: [NSItemProvider], completion: @escaping ([URL]) -> ()) {
        
        var providers: [NSItemProvider] = providers
        var urls: [URL] = []
        
        func next() {
            
            if !providers.isEmpty {
                
                let provider = providers.removeFirst()
                
                if provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
                    
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.video.identifier) { url, error in
                        
                        guard error == nil,
                              let url: URL = url else {
                            next()
                            return
                        }
                        
                        urls.append(url)
                        
                        next()
                    }
                } else {
                    next()
                }
                
            } else {
                completion(urls)
                return
            }
        }
        
        next()
    }
    
    func dropURLs(type: UTType, providers: [NSItemProvider], completion: @escaping ([URL]) -> ()) {
                
        var providers: [NSItemProvider] = providers
        var urls: [URL] = []
        
        func next() {
            
            if !providers.isEmpty {
                
                let provider = providers.removeFirst()
                
                if provider.canLoadObject(ofClass: AMImage.self) {
                    
                    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                        
                        guard error == nil,
                              let url: URL = url else {
                            next()
                            return
                        }
                        
                        urls.append(url)
                        
                        next()
                    }
                } else {
                    next()
                }
                
            } else {
                completion(urls)
                return
            }
        }
        
        next()
    }
}
