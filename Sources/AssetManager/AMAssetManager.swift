//
//  AMAssetManager.swift
//  Pixel Nodes (iOS)
//
//  Created by Anton Heestand on 2021-05-17.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import UniformTypeIdentifiers
import PhotosUI
import TextureMap
import CoreImage
import ImageIO

@Observable
public final class AMAssetManager: NSObject, Sendable {
    
    public enum AssetSource: Sendable {
        case photos
        case files(directory: URL?)
        case camera
        public static let files: AssetSource = .files(directory: nil)
        var isFiles: Bool {
            if case .files = self {
                true
            } else {
                false
            }
        }
    }
    
    public enum AssetType: Sendable {
        
        case image
        case spatialImage
        case video
        case spatialVideo
        case audio
        case media
        case spatialMedia
        case lut
        case text
        case geometry
        case image3d
        case file(extension: String)
        
        public var types: [UTType] {
            switch self {
            case .image:
                return [.image]
            case .spatialImage:
                return [.image]
            case .video:
                return [.movie]
            case .spatialVideo:
                return [.movie]
            case .audio:
                return [.audio]
            case .media:
                return Self.image.types + Self.video.types + Self.audio.types
            case .spatialMedia:
                return Self.image.types + Self.video.types
            case .lut:
                var types: [UTType] = []
                if let cube = UTType(filenameExtension: "cube") {
                    types.append(cube)
                }
                return types
            case .text:
                return [.text]
            case .geometry:
                return [
                    UTType(filenameExtension: "obj"),
                    UTType(filenameExtension: "stl"),
                    UTType(filenameExtension: "dae"),
                    UTType(filenameExtension: "usdz"),
                    UTType(filenameExtension: "fbx"),
                    UTType(filenameExtension: "glb"),
                    UTType(filenameExtension: "gltf"),
                    UTType(filenameExtension: "ply"),
                ].compactMap({ $0 })
            case .image3d:
                var types: [UTType] = []
                if let cube = UTType(filenameExtension: "png3d") {
                    types.append(cube)
                }
                return types
            case .file(let fileExtension):
                if let type = UTType(filenameExtension: fileExtension) {
                    return [type]
                }
                return []
            }
        }
        
        public var isSpatial: Bool {
            switch self {
            case .spatialImage, .spatialVideo, .spatialMedia:
                true
            default:
                false
            }
        }
        
        public var filter: PHPickerFilter? {
            switch self {
            case .image:
                return .images
            case .spatialImage:
                if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                    return .all(of: [.images, .spatialMedia])
                } else {
                    return .images
                }
            case .video:
                return .videos
            case .spatialVideo:
                if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                    return .all(of: [.videos, .spatialMedia])
                } else {
                    return .videos
                }
            case .media:
                return .any(of: [.images, .videos])
            case .spatialMedia:
                if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                    return .all(of: [.any(of: [.images, .videos]), .spatialMedia])
                } else {
                    return .any(of: [.images, .videos])
                }
            case .file, .lut, .audio, .text, .geometry, .image3d:
                return nil
            }
        }
        
        public static func isRawImage(url: URL) -> Bool {
            let format: String = url.pathExtension
            guard let type = UTType(filenameExtension: format) else { return false }
            return isRawImage(type: type)
        }
        
        private static func isRawImage(type: UTType) -> Bool {
            // Raw Image Formats
            // CR2: Canon Raw version 2, used by Canon cameras.
            // NEF: Nikon Electronic Format, used by Nikon cameras.
            // ARW: Sony Alpha Raw, used by Sony cameras.
            // ORF: Olympus Raw Format, used by Olympus cameras.
            // RAF: Raw Image File, used by Fujifilm cameras.
            // RW2: Raw file format used by Panasonic cameras.
            // DNG: Digital Negative, an open standard raw file format created by Adobe.
            // SRF: Sony Raw Files, used in older Sony models. (1)
            // SR2: Sony Raw Files, used in older Sony models. (2)
            // PEF: Pentax Electronic File, used by Pentax cameras.
            // NRW: A variation of NEF used in some of Nikon's compact cameras.
            // KDC: Kodak Digital Camera Raw Image Format, used by Kodak.
            // MRW: Minolta Raw, used by older Minolta and newer Konica Minolta cameras.
            // 3FR: Hasselblad's 3F Raw Image, used by Hasselblad cameras.
            // X3F: Sigma Raw format, used by Sigma cameras.
            // MOS: Used by Leaf cameras.
            // IIQ: Used by Phase One cameras.
            return type.conforms(to: .rawImage)
        }
        
        public static func isImage(url: URL) -> Bool {
            let format: String = url.pathExtension
            guard let type = UTType(filenameExtension: format) else { return false }
            return type.conforms(to: .image)
        }
        
        public static func image(url: URL) -> AMAssetFile? {
            let name: String = url.deletingPathExtension().lastPathComponent
            let format: String = url.pathExtension
            guard let type = UTType(filenameExtension: format) else { return nil }
            if type == .gif {
                return AMAssetURLFile(name: name, url: url)
            } else if type == .heic {
                return AMAssetURLFile(name: name, url: url)
            } else if isRawImage(type: type) {
                return rawImage(url: url)
            } else if type.conforms(to: .image) {
                if let image: AMImage = AMImage(contentsOfFile: url.path) {
                    return AMAssetImageFile(name: name, image: image)
                }
            }
            return nil
        }
        
        public static func rawImage(url: URL) -> AMAssetRawImageFile? {
            let name: String = url.deletingPathExtension().lastPathComponent
            let format: String = url.pathExtension
            guard let type = UTType(filenameExtension: format) else { return nil }
            guard isRawImage(type: type) else { return nil }
            guard let data: Data = try? Data(contentsOf: url) else { return nil }
            guard let rawFilter = CIRAWFilter(imageURL: url) else { return nil }
            rawFilter.extendedDynamicRangeAmount = 2.0
            guard let rawImage: CIImage = rawFilter.outputImage else { return nil }
            #if os(macOS)
            let rep = NSCIImageRep(ciImage: rawImage)
            let image = NSImage(size: rep.size)
            image.addRepresentation(rep)
            #else
            guard let cgImage: CGImage = try? TextureMap.cgImage(ciImage: rawImage, colorSpace: .sRGB, bits: ._16) else { return nil }
            guard let image: UIImage = try? TextureMap.image(cgImage: cgImage) else {  return nil }
            #endif
            return AMAssetRawImageFile(name: name, format: format, image: image, data: data)
        }
    }
    
    public enum AssetError: LocalizedError {
        case badImageData
        case badPhotosObject
        case fileExtensionNotSupported(_ fileExtension: String)
        case badURLAccess
        case videoNotCompatibleWithPhotosLibrary
        case alphaFixFailed
        case notAuthorized(PHAuthorizationStatus)
        public var errorDescription: String? {
            switch self {
            case .badImageData:
                return "Asset Manager - Bad Image data"
            case .badPhotosObject:
                return "Asset Manager - Bad Photos Object"
            case .fileExtensionNotSupported(let fileExtension):
                return "Asset Manager - File Extension Not Supported (\(fileExtension))"
            case .badURLAccess:
                return "Asset Manager - Bad URL Access"
            case .videoNotCompatibleWithPhotosLibrary:
                return "Asset Manager - Video Not Compatible with Photos Library"
            case .alphaFixFailed:
                return "Asset Manager - Alpha Fix Failed"
            case .notAuthorized(let status):
                return "Asset Manager - Not Authorized (Status: \(status.rawValue))"
            }
        }
    }
    
    public enum ImageAssetFormat: Sendable {
        case png
        case jpg(compressionQuality: CGFloat)
        case heic
        var fileExtension: String {
            switch self {
            case .png:
                "png"
            case .jpg:
                "jpg"
            case .heic:
                "heic"
            }
        }
    }
    
    #if os(iOS) || os(visionOS)
    
    @MainActor var showOpenFilesPicker: Bool = false
    @MainActor var filesTypes: [UTType]?
    @MainActor var filesHasMultiSelect: Bool?
    @MainActor var filesDirectoryURL: URL?
    @MainActor @ObservationIgnored var filesSelectedCallback: (([URL]) -> ())?
    
    @MainActor var showOpenFolderPicker: Bool = false
    @MainActor var folderDirectoryURL: URL?
    @MainActor @ObservationIgnored var folderSelectedCallback: ((URL?) -> ())?
    
    @MainActor var showSaveFilePicker: Bool = false
    @MainActor var saveFileAsCopy: Bool = true
    @MainActor var saveDirectoryURL: URL?
    @MainActor var fileUrls: [URL]?
    @MainActor @ObservationIgnored var saveFileCompletion: (([URL]?) -> ())?
    
    @MainActor var showShare: Bool = false
    @MainActor var shareItems: [Any]?
    
    #if os(iOS)
    @MainActor var showCameraPicker: Bool = false
    @MainActor var cameraMode: UIImagePickerController.CameraCaptureMode?
    @MainActor @ObservationIgnored var cameraImageCallback: ((UIImage) -> ())?
    @MainActor @ObservationIgnored var cameraVideoCallback: ((URL) -> ())?
    @MainActor @ObservationIgnored var cameraCancelCallback: (() -> ())?
    #endif
    
    @MainActor @ObservationIgnored private var imageSaveCompletionHandler: ((Error?) -> ())?
    @MainActor @ObservationIgnored private var videoSaveCompletionHandler: ((Error?) -> ())?
    
    #endif
    
    
    @MainActor var showPhotosPicker: Bool = false
    @MainActor @ObservationIgnored var photosFilter: PHPickerFilter?
    @MainActor @ObservationIgnored var photosIsSpatial: Bool?
    @MainActor @ObservationIgnored var photosHasMultiSelect: Bool?
    @MainActor @ObservationIgnored var photosSelectedCallback: (([Any]) -> ())?
}

// MARK: - Share

extension AMAssetManager {
    
    #if os(iOS) || os(visionOS)
    
    public func share(image: AMImage) {
        Task { @MainActor in
            shareItems = [image]
            showShare = true
        }
    }
    
    public func share(images: [AMImage]) {
        Task { @MainActor in
            shareItems = images
            showShare = true
        }
    }
    
    public func share(url: URL) {
        Task { @MainActor in
            shareItems = [url]
            showShare = true
        }
    }
    
    public func share(urls: [URL]) {
        Task { @MainActor in
            shareItems = urls
            showShare = true
        }
    }
    
    #endif
}

// MARK: - Import

extension AMAssetManager {
    
    // MARK: Media
    
    /// Auto converted to an image when `source` is not `.files`
    public func importOneMedia(
        from source: AssetSource,
        autoImageConvert: Bool? = nil
    ) async throws -> AMAssetFile? {
        try await withCheckedThrowingContinuation { continuation in
            importOneMedia(from: source, autoImageConvert: autoImageConvert) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Auto converted to an image when `source` is not `.files`
    public func importOneMedia(
        from source: AssetSource,
        autoImageConvert: Bool? = nil,
        completion: @escaping @Sendable (Result<AMAssetFile?, Error>) -> ()
    ) {
        let autoImageConvert: Bool = !source.isFiles
        Task { @MainActor in
            importAsset(.media, from: source, autoImageConvert: autoImageConvert, completion: completion)
        }
    }
    
    /// Auto converted to an image when `source` is not `.files`
    public func importMultipleMedia(
        from source: AssetSource,
        autoImageConvert: Bool? = nil
    ) async throws -> [AMAssetFile] {
        try await withCheckedThrowingContinuation { continuation in
            importMultipleMedia(from: source, autoImageConvert: autoImageConvert) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Auto converted to an image when `source` is not `.files`
    public func importMultipleMedia(
        from source: AssetSource,
        autoImageConvert: Bool? = nil,
        completion: @escaping @Sendable (Result<[AMAssetFile], Error>) -> ()
    ) {
        let autoImageConvert: Bool = !source.isFiles
        Task { @MainActor in
            importAssets(.media, from: source, autoImageConvert: autoImageConvert, completion: completion)
        }
    }
    
    /// Auto converted to an image when `source` is not `.files`
    public func importMultipleSpatialMedia(
        from source: AssetSource,
        autoImageConvert: Bool? = nil
    ) async throws -> [AMAssetFile] {
        try await withCheckedThrowingContinuation { continuation in
            importMultipleSpatialMedia(from: source, autoImageConvert: autoImageConvert) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Auto converted to an image when `source` is not `.files`
    public func importMultipleSpatialMedia(
        from source: AssetSource,
        autoImageConvert: Bool? = nil,
        completion: @escaping @Sendable (Result<[AMAssetFile], Error>) -> ()
    ) {
        let autoImageConvert: Bool = !source.isFiles
        Task { @MainActor in
            importAssets(.spatialMedia, from: source, autoImageConvert: autoImageConvert, completion: completion)
        }
    }
    
    // MARK: Images

    public func importImage(
        from source: AssetSource
    ) async throws -> AMAssetImageFile? {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.importImage(from: source) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importImage(
        from source: AssetSource,
        completion: @escaping @Sendable (Result<AMAssetImageFile?, Error>) -> ()
    ) {
        Task { @MainActor in
            self.importAsset(.image, from: source, autoImageConvert: true) { result in
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
    }
    
    #if os(macOS)
    
    public func importImages(
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<[AMAssetFile], Error>) -> ()
    ) {
        openImages(directoryURL: directory, completion: completion)
    }
    
    public func importImagesAsURLs(
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        openImagesAsURLs(directoryURL: directory, completion: completion)
    }
    
    #endif
    
    public func importImages(
        from source: AssetSource
    ) async throws -> [AMAssetFile] {
        try await withCheckedThrowingContinuation { continuation in
            importImages(from: source) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importImages(
        from source: AssetSource,
        completion: @escaping @Sendable (Result<[AMAssetFile], Error>) -> ()
    ) {
        Task { @MainActor in
            self.importAssets(.image, from: source, autoImageConvert: true) { result in
                switch result {
                case .success(let assetFiles):
                    let assetFiles: [AMAssetFile] = assetFiles.compactMap({ file in
                        if let imageFile = file as? AMAssetImageFile {
                            return imageFile
                        } else if let rawImageFile = file as? AMAssetRawImageFile {
                            return rawImageFile
                        }
                        return nil
                    })
                    completion(.success(assetFiles))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: Video

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
        completion: @escaping @Sendable (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        Task { @MainActor in
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
    }
    
    public func importVideos(
        from source: AssetSource
    ) async throws -> [AMAssetURLFile] {
        try await withCheckedThrowingContinuation { continuation in
            importVideos(from: source) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importVideos(
        from source: AssetSource,
        completion: @escaping @Sendable (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        Task { @MainActor in
            self.importAssets(.video, from: source) { result in
                switch result {
                case .success(let assetFiles):
                    let urlFiles: [AMAssetURLFile] = assetFiles.compactMap({ file in
                        if let urlFile = file as? AMAssetURLFile {
                            return urlFile
                        }
                        return nil
                    })
                    completion(.success(urlFiles))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    #if os(macOS)
    
    public func importVideos(
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        openVideos(directoryURL: directory, completion: completion)
    }
    
    #endif
    
    // MARK: File

    public func importFileURL(
        title: String? = nil,
        withExtension fileExtension: String,
        directory: URL? = nil
    ) async throws -> URL? {
        try await importFile(title: title, withExtension: fileExtension, directory: directory)?.url
    }

    public func importFile(
        title: String? = nil,
        withExtension fileExtension: String,
        directory: URL? = nil
    ) async throws -> AMAssetURLFile? {
        try await withCheckedThrowingContinuation { continuation in
            importFile(title: title, withExtension: fileExtension, directory: directory) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importFile(
        title: String? = nil,
        withExtension fileExtension: String,
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        importFile(title: title, type: .file(extension: fileExtension), directory: directory, completion: completion)
    }
    
    public func importFileURL(
        title: String? = nil,
        type: AssetType,
        directory: URL? = nil
    ) async throws -> URL? {
        try await importFile(title: title, type: type, directory: directory)?.url
    }
    
    public func importFile(
        title: String? = nil,
        type: AssetType,
        directory: URL? = nil
    ) async throws -> AMAssetURLFile? {
        try await withCheckedThrowingContinuation { continuation in
            importFile(title: title, type: type, directory: directory) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importFile(
        title: String? = nil,
        type: AssetType,
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        Task { @MainActor in
            importAsset(title: title, type, from: .files(directory: directory), autoImageConvert: false) { result in
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
    }
    
    // MARK: Files

    public func importFileURLs(
        title: String? = nil,
        withExtension fileExtension: String,
        directory: URL? = nil
    ) async throws -> [URL] {
        let assetURLFiles: [AMAssetURLFile] = try await importFiles(title: title, withExtension: fileExtension, directory: directory)
        return assetURLFiles.map(\.url)
    }
    
    public func importFiles(
        title: String? = nil,
        withExtension fileExtension: String,
        directory: URL? = nil
    ) async throws -> [AMAssetURLFile] {
        try await withCheckedThrowingContinuation { continuation in
            importFiles(title: title, withExtension: fileExtension, directory: directory) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importFiles(
        title: String? = nil,
        withExtension fileExtension: String,
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        importFiles(title: title, type: .file(extension: fileExtension), directory: directory, completion: completion)
    }
    
    public func importFileURLs(
        title: String? = nil,
        type: AssetType,
        directory: URL? = nil
    ) async throws -> [URL] {
        let assetURLFiles: [AMAssetURLFile] = try await importFiles(title: title, type: type, directory: directory)
        return assetURLFiles.map(\.url)
    }
    
    public func importFiles(
        title: String? = nil,
        type: AssetType,
        directory: URL? = nil
    ) async throws -> [AMAssetURLFile] {
        try await withCheckedThrowingContinuation { continuation in
            importFiles(title: title, type: type, directory: directory) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importFiles(
        title: String? = nil,
        type: AssetType,
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<[AMAssetURLFile], Error>) -> ()
    ) {
        Task { @MainActor in
            importAssets(title: title, type, from: .files(directory: directory), autoImageConvert: false) { result in
                switch result {
                case .success(let assetFiles):
                    let assetURLFiles: [AMAssetURLFile] = assetFiles.compactMap({ $0 as? AMAssetURLFile })
                    completion(.success(assetURLFiles))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: Any File
    
    public func importAnyFileURL(
        directory: URL? = nil
    ) async throws -> URL? {
        try await importAnyFile(directory: directory)?.url
    }
    
    public func importAnyFile(
        directory: URL? = nil
    ) async throws -> AMAssetURLFile? {
        try await withCheckedThrowingContinuation { continuation in
            importAnyFile(directory: directory) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func importAnyFile(
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<AMAssetURLFile?, Error>) -> ()
    ) {
        Task { @MainActor in
            importAsset(nil, from: .files(directory: directory), autoImageConvert: false) { result in
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
    }
}

// MARK: - Select Folder

extension AMAssetManager {
    
    public func selectFolder(
        title: String = "Select Folder",
        directory: URL? = nil
    ) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor [weak self] in
                self?.selectFolder(title: title, directory: directory) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    @MainActor
    public func selectFolder(
        title: String = "Select Folder",
        directory: URL? = nil,
        completion: @escaping @Sendable (Result<URL?, Error>) -> ()
    ) {
        #if os(macOS)
        openFolder(title: title, directoryURL: directory, completion: completion)
        #else
        folderSelectedCallback = { [weak self] url in
            self?.folderSelectedCallback = nil
            self?.showOpenFolderPicker = false
            self?.folderDirectoryURL = nil
            completion(.success(url))
        }
        folderDirectoryURL = directory
        showOpenFolderPicker = true
        #endif
    }
}

// MARK: - Save

extension AMAssetManager {
    
    @discardableResult
    public func saveImageToFiles(
        _ image: AMImage,
        name: String,
        as format: ImageAssetFormat = .png
    ) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            saveImageToFiles(image, name: name, as: format) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func saveImageToFiles(
        _ image: AMImage,
        name: String,
        as format: ImageAssetFormat = .png,
        completion: @escaping @Sendable (Result<URL?, Error>) -> ()
    ) {
                
        let data: Data
        switch format {
        case .png:
            guard let pngData = image.pngData() else {
                completion(.failure(AssetError.badImageData))
                return
            }
            data = pngData
        case .jpg(let compressionQuality):
            guard let jpgData = image.jpegData(compressionQuality: compressionQuality) else {
                completion(.failure(AssetError.badImageData))
                return
            }
            data = jpgData
        case .heic:
            guard let heicData = image.heicData() else {
                completion(.failure(AssetError.badImageData))
                return
            }
            data = heicData
        }
        
        #if os(macOS)
        saveFile(data: data, title: "Save Image", name: "\(name).\(format.fileExtension)") { result in
            completion(result)
        }
        #else
        
        do {
            
            let folderURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(UUID().uuidString)
            
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            
            let url: URL = folderURL
                .appendingPathComponent("\(name).\(format.fileExtension)")
            
//            _ = url.startAccessingSecurityScopedResource()
            try data.write(to: url)
//            url.stopAccessingSecurityScopedResource()
            
            Task { @MainActor in
                saveToFiles(url: url) { result in
                    
                    try? FileManager.default.removeItem(at: url)
                    
                    completion(result)
                }
            }
        } catch {
            print("Asset Manager - Temporary Image File Save Failed:", error)
            completion(.failure(error))
        }
        #endif
    }
    
    @discardableResult
    public func saveImageDataToFiles(
        _ data: Data,
        name: String,
        as format: ImageAssetFormat
    ) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            saveImageDataToFiles(data, name: name, as: format) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func saveImageDataToFiles(
        _ data: Data,
        name: String,
        as format: ImageAssetFormat,
        completion: @escaping @Sendable (Result<URL?, Error>) -> ()
    ) {
        
        #if os(macOS)
        saveFile(data: data, title: "Save Image", name: "\(name).\(format.fileExtension)") { result in
            completion(result)
        }
        #else
        
        do {
            
            let folderURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(UUID().uuidString)
            
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            
            let url: URL = folderURL
                .appendingPathComponent("\(name).\(format.fileExtension)")
            
//            _ = url.startAccessingSecurityScopedResource()
            try data.write(to: url)
//            url.stopAccessingSecurityScopedResource()
            
            Task { @MainActor in
                saveToFiles(url: url) { result in
                    
                    try? FileManager.default.removeItem(at: url)
                    
                    completion(result)
                }
            }
        } catch {
            print("Asset Manager - Temporary Image File Save Failed:", error)
            completion(.failure(error))
        }
        #endif
    }
    
    @discardableResult
    public func saveImagesToFiles(
        _ images: [AMImage],
        name: String,
        as format: ImageAssetFormat = .png
    ) async throws -> [URL]? {
        try await withCheckedThrowingContinuation { continuation in
            saveImagesToFiles(images, name: name, as: format) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func saveImagesToFiles(
        _ images: [AMImage],
        name: String,
        as format: ImageAssetFormat = .png,
        completion: @escaping @Sendable (Result<[URL]?, Error>) -> ()
    ) {
                
        var data: [Data] = []
        for image in images {
            switch format {
            case .png:
                guard let pngData = image.pngData() else {
                    completion(.failure(AssetError.badImageData))
                    return
                }
                data.append(pngData)
            case .jpg(let compressionQuality):
                guard let jpgData = image.jpegData(compressionQuality: compressionQuality) else {
                    completion(.failure(AssetError.badImageData))
                    return
                }
                data.append(jpgData)
            case .heic:
                guard let heicData = image.heicData() else {
                    completion(.failure(AssetError.badImageData))
                    return
                }
                data.append(heicData)
            }
        }
        
        #if os(macOS)
        let items: [(data: Data, name: String)] = data.enumerated().map { index, data in
            (data: data, name: "\(name) (\(index + 1)).\(format.fileExtension)")
        }
        saveFilesInFolder(items, title: "Save Images") { result in
            completion(result)
        }
        #else
        
        do {
            
            let folderURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(UUID().uuidString)
            
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            
            var urls: [URL] = []
            for (index, data) in data.enumerated() {
                let url: URL = folderURL
                    .appendingPathComponent("\(name) (\(index + 1)).\(format.fileExtension)")
//                _ = url.startAccessingSecurityScopedResource()
                try data.write(to: url)
//                url.stopAccessingSecurityScopedResource()
                urls.append(url)
            }
            
            Task { @MainActor in
                let urls = urls
                saveToFiles(urls: urls) { result in
                    for url in urls {
                        try? FileManager.default.removeItem(at: url)
                    }
                    completion(result)
                }
            }
        } catch {
            print("Asset Manager - Temporary Images File Save Failed:", error)
            completion(.failure(error))
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
    
    @discardableResult
    public func saveToFiles(
        url: URL,
        title: String? = nil,
        asCopy: Bool = true
    ) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                saveToFiles(url: url, title: title, asCopy: asCopy) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    @MainActor
    public func saveToFiles(
        url: URL,
        directory: URL? = nil,
        title: String? = nil,
        asCopy: Bool = true,
        completion: (@Sendable (Result<URL?, Error>) -> ())? = nil
    ) {
        #if os(iOS) || os(visionOS)
        fileUrls = [url]
        showSaveFilePicker = true
        saveFileAsCopy = asCopy
        saveDirectoryURL = directory
        saveFileCompletion = { [weak self] urls in
            completion?(.success(urls?.first))
            self?.saveDirectoryURL = nil
            self?.saveFileCompletion = nil
        }
        #elseif os(macOS)
        saveFile(url: url, title: title, completion: completion)
        #endif
    }
    
    @discardableResult
    public func saveToFiles(
        urls: [URL],
        title: String? = nil,
        asCopy: Bool = true
    ) async throws -> [URL]? {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                saveToFiles(urls: urls, title: title, asCopy: asCopy) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    @MainActor
    public func saveToFiles(
        urls: [URL],
        directory: URL? = nil,
        title: String? = nil,
        asCopy: Bool = true,
        completion: (@Sendable (Result<[URL]?, Error>) -> ())? = nil
    ) {
        #if os(iOS) || os(visionOS)
        fileUrls = urls
        showSaveFilePicker = true
        saveFileAsCopy = asCopy
        saveDirectoryURL = directory
        saveFileCompletion = { [weak self] urls in
            completion?(.success(urls))
            self?.saveFileCompletion = nil
            self?.saveDirectoryURL = nil
        }
        #elseif os(macOS)
        do {
            var items: [(data: Data, name: String)] = []
            for url in urls {
                let item = (data: try Data(contentsOf: url), name: url.lastPathComponent)
                items.append(item)
            }
            saveFilesInFolder(items, title: title, completion: completion)
        } catch {
            completion?(.failure(error))
        }
        #endif
    }
    
    #if os(iOS) || os(visionOS)
   
    public func saveImageToPhotos(
        _ image: AMImage,
        alphaFix: Bool = true
    ) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            saveImageToPhotos(image, alphaFix: alphaFix) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }
    
    public func saveImageToPhotos(
        _ image: AMImage,
        alphaFix: Bool = true,
        completion: @escaping @Sendable (Error?) -> ()
    ) {
        var image: AMImage = image
        if alphaFix {
            /// Alpha Channel Fix (Image to Data to Image)
            guard let data: Data = image.pngData(),
                  let dataImage: UIImage = UIImage(data: data) else {
                completion(AssetError.alphaFixFailed)
                return
            }
            image = dataImage
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaveCompleted), nil)
        Task { @MainActor in
            imageSaveCompletionHandler = completion
        }
    }
   
    public func saveImageDataToPhotos(
        _ data: Data,
        as format: ImageAssetFormat
    ) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            saveImageDataToPhotos(data, as: format) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }
    
    public func saveImageDataToPhotos(
        _ data: Data,
        as format: ImageAssetFormat,
        completion: @escaping @Sendable (Error?) -> ()
    ) {
        let tempURL = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(format.fileExtension)
        do {
            try data.write(to: tempURL)
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: tempURL, options: nil)
            } completionHandler: { success, error in
                if let error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        } catch {
            completion(error)
        }
    }
    
    public func saveGIF(url: URL) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            saveGIF(url: url) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }
    public func saveGIF(url: URL, completion: @escaping @Sendable (Error?) -> ()) {
        requestAuthorization(for: .addOnly) { status in
            if status != .authorized {
                completion(AssetError.notAuthorized(status))
                return
            }
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: url, options: nil)
            }) { success, error in
                completion(error)
            }
        }
    }
      
    @objc func imageSaveCompleted(_ image: UIImage,
                                  didFinishSavingWithError error: Error?,
                                  contextInfo: UnsafeRawPointer) {
        Task { @MainActor in
            imageSaveCompletionHandler?(error)
            imageSaveCompletionHandler = nil
        }
    }
    
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
        url: URL,
        completion: @escaping @Sendable (Error?) -> ()
    ) {
        let path: String = url.path(percentEncoded: false)
        guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) else {
            completion(AssetError.videoNotCompatibleWithPhotosLibrary)
            return
        }
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(videoSaveCompleted), nil)
        Task { @MainActor in
            videoSaveCompletionHandler = completion
        }
//        requestAuthorization {
//            PHPhotoLibrary.shared().performChanges({
//                let request = PHAssetCreationRequest.forAsset()
//                request.addResource(with: .video, fileURL: url, options: nil)
//            }) { result, error in
//                DispatchQueue.main.async {
//                    completion(error)
//                }
//            }
//        }
    }
    
    @objc func videoSaveCompleted(_ videoPath: String?,
                                  didFinishSavingWithError error: Error?,
                                  contextInfo: UnsafeMutableRawPointer?) {
        Task { @MainActor in
            videoSaveCompletionHandler?(error)
            videoSaveCompletionHandler = nil
        }
    }
    
    public func requestAuthorization(
        for level: PHAccessLevel,
        completion: @escaping @Sendable (PHAuthorizationStatus) -> ()
    ) {
        let status = PHPhotoLibrary.authorizationStatus(for: level)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: level) { status in
                Task { @MainActor in
                    completion(status)
                }
            }
        } else {
            completion(status)
        }
    }
    
    #endif
}

// MARK: - Import Assets

extension AMAssetManager {
    
    @MainActor
    private func importAsset(
        title: String? = nil,
        _ type: AssetType?,
        from source: AssetSource,
        autoImageConvert: Bool = false,
        completion: @escaping @Sendable (Result<AMAssetFile?, Error>) -> ()
    ) {
        switch source {
        case .files(let directoryURL):
            #if os(macOS)
            if let type = type {
                switch type {
                case .image, .spatialImage:
                    if autoImageConvert {
                        openImage(
                            directoryURL: directoryURL
                        ) { result in
                            switch result {
                            case .success(let assetImageFile):
                                completion(.success(assetImageFile))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    } else {
                        openImageAsURL(
                            directoryURL: directoryURL
                        ) { result in
                            switch result {
                            case .success(let assetURLFile):
                                completion(.success(assetURLFile))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                case .video, .spatialVideo:
                    openVideo(
                        directoryURL: directoryURL
                    ) { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .media, .spatialMedia:
                    openMedia(
                        autoImageConvert: autoImageConvert,
                        directoryURL: directoryURL
                    ) { result in
                        switch result {
                        case .success(let assetFile):
                            completion(.success(assetFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .text:
                    openFile(
                        title: title ?? "Open Text File",
                        directoryURL: directoryURL,
                        allowedFileTypes: [.text]
                    ) { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .geometry:
                    openFile(
                        title: title ?? "Open Geometry File",
                        directoryURL: directoryURL,
                        allowedFileTypes: AssetType.geometry.types
                    ) { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .image3d:
                    openFile(
                        title: title ?? "Open 3D Image File",
                        directoryURL: directoryURL,
                        allowedFileTypes: AssetType.image3d.types
                    ) { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .file(let fileExtension):
                    guard let fileType = UTType(filenameExtension: fileExtension) else { return }
                    openFile(
                        title: title ?? "Open \(fileExtension.uppercased()) File",
                        directoryURL: directoryURL,
                        allowedFileTypes: [fileType]
                    ) { result in
                        switch result {
                        case .success(let assetURLFile):
                            completion(.success(assetURLFile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .lut:
                    break
                case .audio:
                    break
                }
            } else {
                openFile(
                    title: title ?? "Open File",
                    directoryURL: directoryURL,
                    allowedFileTypes: nil
                ) { result in
                    switch result {
                    case .success(let assetURLFile):
                        completion(.success(assetURLFile))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            #elseif os(iOS) || os(visionOS)
            filesTypes = type?.types ?? []
            filesHasMultiSelect = false
            filesDirectoryURL = directoryURL
            filesSelectedCallback = { [weak self] urls in
                self?.filesTypes = nil
                self?.filesHasMultiSelect = nil
                self?.filesDirectoryURL = nil
                self?.showOpenFilesPicker = false
                self?.filesSelectedCallback = nil
                guard let url: URL = urls.first else {
                    completion(.success(nil))
                    return
                }
                let name: String = url.deletingPathExtension().lastPathComponent
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if autoImageConvert, AssetType.isImage(url: url) {
                    guard let assetFile: AMAssetFile = AssetType.image(url: url) else {
                        completion(.failure(AssetError.badImageData))
                        return
                    }
                    completion(.success(assetFile))
                    return
                }
                completion(.success(AMAssetURLFile(name: name, url: url)))
            }
            Task { @MainActor in
                self.showOpenFilesPicker = true
            }
            #endif
        case .photos:
            guard let filter: PHPickerFilter = type?.filter else { return }
            photosFilter = filter
            photosIsSpatial = type?.isSpatial ?? false
            photosHasMultiSelect = false
            photosSelectedCallback = { [weak self] objects in
                self?.photosFilter = nil
                self?.photosIsSpatial = nil
                self?.photosHasMultiSelect = nil
                self?.showPhotosPicker = false
                self?.photosSelectedCallback = nil
                guard let object: Any = objects.first else {
                    completion(.success(nil))
                    return
                }
                if let image: AMImage = object as? AMImage {
                    completion(.success(AMAssetImageFile(name: nil, image: image)))
                    return
                }
                guard let url: URL = object as? URL else {
                    completion(.failure(AssetError.badPhotosObject))
                    return
                }
                if autoImageConvert, AssetType.isImage(url: url) {
                    guard let assetFile: AMAssetFile = AssetType.image(url: url) else {
                        completion(.failure(AssetError.badImageData))
                        return
                    }
                    completion(.success(assetFile))
                    return
                }
                let name: String = url.deletingPathExtension().lastPathComponent
                completion(.success(AMAssetURLFile(name: name, url: url)))
            }
            showPhotosPicker = true
        case .camera:
            #if os(iOS)
            if let type {
                if case .video = type {
                    cameraMode = .video
                    cameraVideoCallback = { url in
                        completion(.success(AMAssetURLFile(url: url)))
                    }
                } else {
                    cameraMode = .photo
                    cameraImageCallback = { image in
                        completion(.success(AMAssetImageFile(name: nil, image: image)))
                    }
                }
                cameraCancelCallback = {
                    completion(.success(nil))
                }
                showCameraPicker = true
            }
            #endif
        }
    }
    
    @MainActor
    private func importAssets(
        title: String? = nil,
        _ type: AssetType?,
        from source: AssetSource,
        autoImageConvert: Bool = false,
        completion: @escaping @Sendable (Result<[AMAssetFile], Error>) -> ()
    ) {
        switch source {
        case .files(let directoryURL):
            #if os(macOS)
            if let type = type {
                switch type {
                case .image, .spatialImage:
                    openImages(
                        directoryURL: directoryURL
                    ) { result in
                        switch result {
                        case .success(let assetImageFiles):
                            completion(.success(assetImageFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .video, .spatialVideo:
                    openVideos(
                        directoryURL: directoryURL
                    ) { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .media, .spatialMedia:
                    openMedia(
                        autoImageConvert: autoImageConvert,
                        directoryURL: directoryURL
                    ) { result in
                        switch result {
                        case .success(let assetFiles):
                            completion(.success(assetFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .text:
                    openFiles(
                        title: title ?? "Open Text Files",
                        directoryURL: directoryURL,
                        allowedFileTypes: [.text]
                    ) { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .geometry:
                    openFiles(
                        title: title ?? "Open Geometry Files",
                        directoryURL: directoryURL,
                        allowedFileTypes: AssetType.geometry.types
                    ) { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .image3d:
                    openFiles(
                        title: title ?? "Open 3D Image Files",
                        directoryURL: directoryURL,
                        allowedFileTypes: AssetType.image3d.types
                    ) { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .file(let fileExtension):
                    guard let fileType = UTType(filenameExtension: fileExtension) else { return }
                    openFiles(
                        title: title ?? "Open \(fileExtension.uppercased()) Files",
                        directoryURL: directoryURL,
                        allowedFileTypes: [fileType]
                    ) { result in
                        switch result {
                        case .success(let assetURLFiles):
                            completion(.success(assetURLFiles))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .lut:
                    break
                case .audio:
                    break
                }
            } else {
                openFiles(
                    title: title ?? "Open Files",
                    directoryURL: directoryURL,
                    allowedFileTypes: nil
                ) { result in
                    switch result {
                    case .success(let assetURLFiles):
                        completion(.success(assetURLFiles))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            #elseif os(iOS) || os(visionOS)
            filesTypes = type?.types ?? []
            filesHasMultiSelect = true
            filesDirectoryURL = directoryURL
            filesSelectedCallback = { [weak self] urls in
                self?.filesTypes = nil
                self?.filesHasMultiSelect = nil
                self?.filesDirectoryURL = nil
                self?.showOpenFilesPicker = false
                self?.filesSelectedCallback = nil
                do {
                    let files: [AMAssetFile] = try urls.map { url in
                        let name: String = url.deletingPathExtension().lastPathComponent
                        guard url.startAccessingSecurityScopedResource() else {
                            throw AssetError.badURLAccess
                        }
                        defer { url.stopAccessingSecurityScopedResource() }
                        if autoImageConvert, AssetType.isImage(url: url) {
                            guard let assetFile: AMAssetFile = AssetType.image(url: url) else {
                                throw AssetError.badImageData
                            }
                            return assetFile
                        }
                        return AMAssetURLFile(name: name, url: url)
                    }
                    completion(.success(files))
                } catch {
                    completion(.failure(error))
                }
            }
            Task { @MainActor in
                self.showOpenFilesPicker = true
            }
            #endif
        case .photos:
            guard let filter: PHPickerFilter = type?.filter else { return }
            photosFilter = filter
            photosIsSpatial = type?.isSpatial ?? false
            photosHasMultiSelect = true
            photosSelectedCallback = { [weak self] objects in
                self?.photosFilter = nil
                self?.photosIsSpatial = nil
                self?.photosHasMultiSelect = nil
                self?.showPhotosPicker = false
                self?.photosSelectedCallback = nil
                do {
                    let files: [AMAssetFile] = try objects.map { object in
                        if autoImageConvert, let image = object as? AMImage {
                            return AMAssetImageFile(name: nil, image: image)
                        }
                        guard let url: URL = object as? URL else {
                            throw AssetError.badPhotosObject
                        }
                        if autoImageConvert, AssetType.isImage(url: url) {
                            guard let assetFile: AMAssetFile = AssetType.image(url: url) else {
                                throw AssetError.badImageData
                            }
                            return assetFile
                        }
                        return AMAssetURLFile(url: url)
                     }
                    completion(.success(files))
                } catch {
                    completion(.failure(error))
                }
            }
            showPhotosPicker = true
        case .camera:
            importAsset(type, from: .camera) { result in
                switch result {
                case .success(let asset):
                    if let asset {
                        completion(.success([asset]))
                    } else {
                        completion(.success([]))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Drop

extension AMAssetManager {
    
    enum DropError: Error {
//        case noImage
        case noData
        case noURL
        case badImageData
    }
    
//    private func loadImage(from provider: NSItemProvider) async throws -> AMImage? {
//        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return nil }
//        return try await withCheckedThrowingContinuation { continuation in
//            provider.loadObject(ofClass: AMImage.self) { image, error in
//                if let error: Error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                guard let image: AMImage else {
//                    continuation.resume(throwing: DropError.noImage)
//                    return
//                }
//                continuation.resume(returning: image)
//            }
//        }
//    }
    
    private func loadData(as type: UTType, from provider: NSItemProvider) async throws -> Data? {
        guard provider.hasItemConformingToTypeIdentifier(type.identifier) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                if let error: Error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data: Data else {
                    continuation.resume(throwing: DropError.noData)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
    
    private func loadURL(as type: UTType, from provider: NSItemProvider) async throws -> URL? {
        guard provider.hasItemConformingToTypeIdentifier(type.identifier) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
//            provider.loadItem(forTypeIdentifier: type.identifier) { url, error in
            provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                if let error: Error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url: URL else {
                    continuation.resume(throwing: DropError.noURL)
                    return
                }
                continuation.resume(returning: url)
            }
        }
    }
    
    func dropImages(providers: [NSItemProvider]) async throws -> [AMAssetImageFile] {
        var imageFiles: [AMAssetImageFile] = []
        for provider in providers {
            guard let data: Data = try await loadData(as: .image, from: provider) else { continue }
            guard let image = AMImage(data: data) else {
                throw DropError.badImageData
            }
            let imageFile = AMAssetImageFile(image: image)
            imageFiles.append(imageFile)
        }
        return imageFiles
    }
    
//    func dropImages(providers: [NSItemProvider], completion: @escaping ([AMImage]) -> ()) {
//        Task {
//            let images: [AMImage] = try await dropImages(providers: providers)
//            await MainActor.run {
//                completion(images)
//            }
//        }
//    }
    
    func dropVideos(providers: [NSItemProvider]) async throws -> [URL] {
        var urls: [URL] = []
        for provider in providers {
            guard let url: URL = try await loadURL(as: .movie, from: provider) else { continue }
            urls.append(url)
        }
        return urls
    }
    
//    func dropVideos(providers: [NSItemProvider], completion: @escaping ([URL]) -> ()) {
//        Task {
//            let urls: [URL] = try await dropVideos(providers: providers)
//            await MainActor.run {
//                completion(urls)
//            }
//        }
//    }
    
    func dropMedia(providers: [NSItemProvider]) async throws -> [AMAssetFile] {
        var assetFiles: [AMAssetFile] = []
        for provider in providers {
            
            if provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                guard let url: URL = try await loadURL(as: .gif, from: provider) else { continue }
                let name: String = url.deletingPathExtension().lastPathComponent
                let assetFile = AMAssetURLFile(name: name, url: url)
                assetFiles.append(assetFile)
                
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                guard let data: Data = try await loadData(as: .image, from: provider) else { continue }
                guard let image = AMImage(data: data) else {
                    throw DropError.badImageData
                }
                let assetFile = AMAssetImageFile(image: image)
                assetFiles.append(assetFile)
                
            } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                guard let url: URL = try await loadURL(as: .movie, from: provider) else { continue }
                let name: String = url.deletingPathExtension().lastPathComponent
                let assetFile = AMAssetURLFile(name: name, url: url)
                assetFiles.append(assetFile)
                
            } else {
                if let lutType: UTType = AMAssetManager.AssetType.lut.types.first(where: { type in
                    provider.hasItemConformingToTypeIdentifier(type.identifier)
                }) {
                    guard let url: URL = try await loadURL(as: lutType, from: provider) else { continue }
                    let name: String = url.deletingPathExtension().lastPathComponent
                    let assetFile = AMAssetURLFile(name: name, url: url)
                    assetFiles.append(assetFile)
                }
            }
        }
        return assetFiles
    }
    
//    func dropMedia(providers: [NSItemProvider], completion: @escaping ([AMAssetFile]) -> ()) {
//        Task {
//            let assetFiles: [AMAssetFile] = try await dropMedia(providers: providers)
//            await MainActor.run {
//                completion(assetFiles)
//            }
//        }
//    }
    
    func dropURLs(types: [UTType], providers: [NSItemProvider], asCopy: Bool) async throws -> [URL] {
        
        var providers: [NSItemProvider] = providers
        var urls: [URL] = []
        
        var folderURL: URL!
        if asCopy {
            folderURL = FileManager.default.temporaryDirectory
                .appending(component: "import-on-drop-of-files")
                .appending(component: UUID().uuidString)
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        while !providers.isEmpty {
            guard let provider: NSItemProvider = providers.first else { break }
            
            for type in types {
                
                if provider.hasRepresentationConforming(toTypeIdentifier: type.identifier) {
                    
                    let url: URL? = try await withCheckedThrowingContinuation({ continuation in
                        _ = provider.loadFileRepresentation(for: type, openInPlace: asCopy) { url, _, error in
                            if let error {
                                continuation.resume(throwing: error)
                                return
                            }
                            continuation.resume(returning: url)
                        }
                    })
                    
                    if let url {
                        if asCopy {
                            let access: Bool = url.startAccessingSecurityScopedResource()
                            defer {
                                if access {
                                    url.stopAccessingSecurityScopedResource()
                                }
                            }
                            let fileURL: URL = folderURL.appending(component: url.lastPathComponent)
                            try FileManager.default.copyItem(at: url, to: fileURL)
                            urls.append(fileURL)
                        } else {
                            urls.append(url)
                        }
                    }
                    
                    break
                }
            }
            providers.removeFirst()
        }
        
        return urls
    }
}

// MARK: - Data

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

    func heicData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            return nil
        }
        
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, AVFileType.heic as CFString, 1, nil) else {
            return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
}

#endif
