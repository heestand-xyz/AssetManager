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
        case media
        case file(extension: String)
        public var types: [UTType] {
            switch self {
            case .image:
                return [.image, .png, .jpeg, .heic, .heif, .tiff, .bmp, .gif, .icns]
            case .video:
                return [.video, .movie, .mpeg4Movie, .quickTimeMovie, .mpeg2Video]
            case .media:
                return AssetType.image.types + AssetType.video.types
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
            case .media:
                return .any(of: [.images, .videos])
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
        case badURLAccess
        var errorDescription: String? {
            switch self {
            case .badImageData:
                return "Asset Manager - Bad Image data"
            case .badPhotosObject:
                return "Asset Manager - Bad Photos Object"
            case .fileExtensionNotSupported(let fileExtension):
                return "Asset Manager - File Extension Not Supported (\(fileExtension))"
            case .badURLAccess:
                return "Asset Manager - Bad URL Access"
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
    
    @Published var showOpenFilesPicker: Bool = false
    var filesTypes: [UTType]?
    var filesHasMultiSelect: Bool?
    var filesSelectedCallback: (([URL]) -> ())?
    
    @Published var showOpenFolderPicker: Bool = false
    var folderSelectedCallback: ((URL?) -> ())?
    
    @Published var showSaveFilePicker: Bool = false
    var fileUrl: URL?
    
    @Published var showPhotosPicker: Bool = false
    var photosFilter: PHPickerFilter?
    var photosHasMultiSelect: Bool?
    var photosSelectedCallback: (([Any]) -> ())?
    
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
    
    public func importMedia(
        from source: AssetSource
    ) async throws -> [AMAssetFile] {
        try await withCheckedThrowingContinuation { continuation in
            importMedia(from: source) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importMedia(
        from source: AssetSource,
        completion: @escaping (Result<[AMAssetFile], Error>) -> ()
    ) {
        importAssets(.media, from: source, completion: completion)
    }
    
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
    
    #if os(macOS)
    
    public func importImages(
        completion: @escaping (Result<[AMAssetImageFile], Error>) -> ()
    ) {
        openImages(completion: completion)
    }
    
    public func importImagesAsURLs(
        completion: @escaping (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        openImagesAsURLs(completion: completion)
    }
    
    #endif
    
    public func importImages(
        from source: AssetSource,
        completion: @escaping (Result<[AMAssetImageFile], Error>) -> ()
    ) {
        importAssets(.image, from: source) { result in
            switch result {
            case .success(let assetFiles):
                let assetImageFiles: [AMAssetImageFile] = assetFiles.compactMap({ file in
                   file as? AMAssetImageFile
                })
                completion(.success(assetImageFiles))
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
    
    #if os(macOS)
    
    public func importVideos(
        completion: @escaping (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        openVideos(completion: completion)
    }
    
    #endif
    
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
    
    public func selectFolder() async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                self?.selectFolder() { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    public func selectFolder(
        completion: @escaping (Result<URL?, Error>) -> ()
    ) {
        #if os(macOS)
        openFolder(title: "Select Folder", completion: completion)
        #else
        folderSelectedCallback = { [weak self] url in
            self?.folderSelectedCallback = nil
            self?.showOpenFolderPicker = false
            completion(.success(url))
        }
        showOpenFolderPicker = true
        #endif
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
        name: String,
        as format: ImageAssetFormat = .png
//        completion: @escaping (Error?) -> ()
    ) {
                
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
        
        #if os(macOS)
        saveFile(data: data, title: "Save Image", name: "\(name).\(format.filenameExtension)") { error in
//            completion(error)
        }
        #else
        
        do {
            
            let folderURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(UUID().uuidString)
            
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            
            let url: URL = folderURL
                .appendingPathComponent("\(name).\(format.filenameExtension)")
            
//            _ = url.startAccessingSecurityScopedResource()
            try data.write(to: url)
//            url.stopAccessingSecurityScopedResource()
            
            saveToFiles(url: url)/* { error in
                
                try? FileManager.default.removeItem(at: url)
                
                completion(error)
            }*/
        } catch {
            print("Asset Manager - Temporary Image File Save Failed:", error)
//            completion(error)
        }
        #endif
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
        /// Alpha Fix (Image to Data to Image)
        guard let data: Data = image.pngData() else { return }
        guard let dataImage: UIImage = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(dataImage, self, nil/*#selector(saveCompleted)*/, nil)
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
                case .media:
                    openMedia { result in
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
            filesTypes = type?.types ?? []
            filesHasMultiSelect = false
            filesSelectedCallback = { [weak self] urls in
                self?.filesTypes = nil
                self?.filesHasMultiSelect = nil
                self?.showOpenFilesPicker = false
                self?.filesSelectedCallback = nil
                guard let url: URL = urls.first else {
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
            showOpenFilesPicker = true
            #endif
        case .photos:
            #if os(iOS)
            guard let filter: PHPickerFilter = type?.filter else { return }
            photosFilter = filter
            photosHasMultiSelect = false
            photosSelectedCallback = { [weak self] objects in
                self?.photosFilter = nil
                self?.photosHasMultiSelect = nil
                self?.showPhotosPicker = false
                self?.photosSelectedCallback = nil
                guard let object: Any = objects.first else {
                    completion(.success(nil))
                    return
                }
                if case .image = type {
                    guard let image: UIImage = object as? UIImage else {
                        completion(.failure(AssetError.badPhotosObject))
                        return
                    }
                    completion(.success(AMAssetImageFile(name: nil, image: image)))
                    return
                } else if case .media = type {
                    if let image: UIImage = object as? UIImage {
                        completion(.success(AMAssetImageFile(name: nil, image: image)))
                        return
                    }
                }
                guard let url: URL = object as? URL else {
                    completion(.failure(AssetError.badPhotosObject))
                    return
                }
                completion(.success(AMAssetURLFile(name: nil, url: url)))
            }
            showPhotosPicker = true
            #endif
        }
    }
    
    private func importAssets(
        _ type: AssetType?,
        from source: AssetSource,
        completion: @escaping (Result<[AMAssetFile], Error>) -> ()
    ) {
        switch source {
        case .files:
            #if os(macOS)
            if let type = type {
                switch type {
                case .image:
                    openImages { result in
                        switch result {
                        case .success(let assetImageFiles):
                            completion(.success(assetImageFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .video:
                    openVideos { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .media:
                    openMedia { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .file(let fileExtension):
                    guard let fileType = UTType(filenameExtension: fileExtension) else { return }
                    openFiles(title: "Open \(fileExtension.uppercased()) Files", allowedFileTypes: [fileType]) { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            } else {
                openFiles(title: "Open Files", allowedFileTypes: nil) { result in
                    switch result {
                    case .success(let assetURLFiles):
                        completion(.success(assetURLFiles))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            #elseif os(iOS)
            filesTypes = type?.types ?? []
            filesHasMultiSelect = true
            filesSelectedCallback = { [weak self] urls in
                self?.filesTypes = nil
                self?.filesHasMultiSelect = nil
                self?.showOpenFilesPicker = false
                self?.filesSelectedCallback = nil
                do {
                    let files: [AMAssetFile] = try urls.map { url in
                        let name: String = url.deletingPathExtension().lastPathComponent
                        guard url.startAccessingSecurityScopedResource() else {
                            throw AssetError.badURLAccess
                        }
                        defer { url.stopAccessingSecurityScopedResource() }
                        if case .image = type {
                            guard let image: UIImage = UIImage(contentsOfFile: url.path) else {
                                throw AssetError.badImageData
                            }
                            return AMAssetImageFile(name: name, image: image)
                        } else if case .media = type {
                            if let image: UIImage = UIImage(contentsOfFile: url.path) {
                                return AMAssetImageFile(name: name, image: image)
                            }
                        }
                        return AMAssetURLFile(name: name, url: url)
                    }
                    completion(.success(files))
                } catch {
                    completion(.failure(error))
                }
            }
            showOpenFilesPicker = true
            #endif
        case .photos:
            #if os(iOS)
            guard let filter: PHPickerFilter = type?.filter else { return }
            photosFilter = filter
            photosHasMultiSelect = true
            photosSelectedCallback = { [weak self] objects in
                self?.photosFilter = nil
                self?.photosHasMultiSelect = nil
                self?.showPhotosPicker = false
                self?.photosSelectedCallback = nil
                do {
                    let files: [AMAssetFile] = try objects.map { object in
                        if case .image = type {
                            guard let image: UIImage = object as? UIImage else {
                                throw AssetError.badPhotosObject
                            }
                            return AMAssetImageFile(name: nil, image: image)
                        } else if case .media = type {
                            if let image: UIImage = object as? UIImage {
                                return AMAssetImageFile(image: image)
                            }
                        }
                        guard let url: URL = object as? URL else {
                            throw AssetError.badPhotosObject
                        }
                        return AMAssetURLFile(url: url)
                     }
                    completion(.success(files))
                } catch {
                    completion(.failure(error))
                }
            }
            showPhotosPicker = true
            #endif
        }
    }
}

// TODO: Should work on macOS (Archive Error)
#if os(iOS)

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
    
    func dropMedia(providers: [NSItemProvider], completion: @escaping ([AMAssetFile]) -> ()) {
        
        var providers: [NSItemProvider] = providers
        var assetFiles: [AMAssetFile] = []
        
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
                        
                        let assetFile = AMAssetImageFile(name: nil, image: image)
                        
                        assetFiles.append(assetFile)
                        
                        next()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
                    
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.video.identifier) { url, error in
                        
                        guard error == nil,
                              let url: URL = url else {
                            next()
                            return
                        }
                        
                        let assetFile = AMAssetURLFile(name: nil, url: url)
                        
                        assetFiles.append(assetFile)
                        
                        next()
                    }
                } else {
                    next()
                }
                
            } else {
                completion(assetFiles)
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

#endif

#if os(macOS)

extension NSImage {

    func pngData() -> Data? {
        guard let representation = tiffRepresentation else { return nil }
        guard let bitmap = NSBitmapImageRep(data: representation) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let representation = tiffRepresentation else { return nil }
        guard let bitmap = NSBitmapImageRep(data: representation) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}

#endif
