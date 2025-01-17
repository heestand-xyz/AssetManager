//
//  PhotosView.swift
//  Magnet Crop
//
//  Created by Anton Heestand on 2020-07-05.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
import PhotosUI
import MultiViews
import TextureMap

struct PhotosView: ViewControllerRepresentable {
    
    let filter: PHPickerFilter
    let isSpatial: Bool
    let multiSelect: Bool
    let pickedContent: ([Any]) -> ()
    let cancelled: () -> ()
    
    func makeViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = filter
        configuration.selectionLimit = multiSelect ? 0 : 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        context.coordinator.pickedContent = { url in
            DispatchQueue.main.async {
                pickedContent(url)
            }
        }
        context.coordinator.cancelled = {
            DispatchQueue.main.async {
                cancelled()
            }
        }
        context.coordinator.picker = picker
        return picker
    }
    
    func updateViewController(_ view: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isSpatial: isSpatial)
    }
    
    final class Coordinator: PHPickerViewControllerDelegate, Sendable {
        
        enum PhotosAssetError: String, Error {
            case spatialPhotoIsNotHEIC
            case spatialURLNotFound
        }
        
        var picker: PHPickerViewController!
        
        var pickedContent: (([Any]) -> ())?
        
        var cancelled: (() -> ())?
        
        let isSpatial: Bool
        init(isSpatial: Bool) {
            self.isSpatial = isSpatial
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if results.isEmpty {
                cancelled?()
                return
            }
            Task {
                var assets: [Any] = []
                
                for result in results {
                    
                    if isSpatial, result.itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.image.identifier) {
                        do {
                            let spatialType: UTType = .heic
                            if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: spatialType.identifier) {
                                let url: URL = try await withCheckedThrowingContinuation { continuation in
                                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: spatialType.identifier) { fileURL, error in
                                        if let error = error {
                                            continuation.resume(throwing: error)
                                            return
                                        }
                                        guard let fileURL = fileURL else {
                                            continuation.resume(throwing: PhotosAssetError.spatialURLNotFound)
                                            return
                                        }
                                        continuation.resume(returning: fileURL)
                                    }
                                }
                                let mappedURL = try Self.map(url: url)
                                assets.append(mappedURL)
                            } else {
                                throw PhotosAssetError.spatialPhotoIsNotHEIC
                            }
                        } catch {
                            print("Asset Manager Photos Error:", error)
                        }
                        continue
                    }
                    
                    if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.gif.identifier) {
                        
                        if let url: URL = try? await withCheckedThrowingContinuation({ continuation in
                            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.gif.identifier) { url, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                guard let url: URL else {
                                    continuation.resume(returning: nil)
                                    return
                                }
                                Task { @MainActor in
                                    do {
                                        let newURL = try Self.map(url: url)
                                        continuation.resume(returning: newURL)
                                    } catch {
                                        continuation.resume(throwing: error)
                                    }
                                }
                            }
                        }) {
                            assets.append(url)
                        }
                        
                    } else if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.rawImage.identifier) {
                        
                        if let url: URL = try? await withCheckedThrowingContinuation({ continuation in
                            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.rawImage.identifier) { url, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                guard let url: URL else {
                                    continuation.resume(returning: nil)
                                    return
                                }
                                Task { @MainActor in
                                    do {
                                        let newURL = try Self.map(url: url)
                                        continuation.resume(returning: newURL)
                                    } catch {
                                        continuation.resume(throwing: error)
                                    }
                                }
                            }
                        }) {
                            assets.append(url as Any)
                        }
                        
                    } else if result.itemProvider.canLoadObject(ofClass: AMImage.self) {
                        
                        if let image: TMSendableImage = try? await withCheckedThrowingContinuation({ continuation in
                            result.itemProvider.loadObject(ofClass: AMImage.self, completionHandler: { provider, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                continuation.resume(returning: (provider as? AMImage)?.send())
                            })
                        }) {
                            assets.append(image.receive() as Any)
                        }
                        
                    } else if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier) {
                        
                        if let url: URL = try? await withCheckedThrowingContinuation({ continuation in
                            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                guard let url: URL else {
                                    continuation.resume(returning: nil)
                                    return
                                }
                                Task { @MainActor in
                                    do {
                                        let newURL = try Self.map(url: url)
                                        continuation.resume(returning: newURL)
                                    } catch {
                                        continuation.resume(throwing: error)
                                    }
                                }
                            }
                        }) {
                            assets.append(url as Any)
                        }
                    }
                }
                await MainActor.run {
                    pickedContent?(assets)
                }
            }
        }
        
        private static func map(url: URL) throws -> URL {
            
            let _ = url.startAccessingSecurityScopedResource()
            
            let folderURL: URL = FileManager.default.temporaryDirectory
                .appending(component: "temp-media")
                .appending(component: "\(UUID())")
            if !FileManager.default.fileExists(atPath: folderURL.path) {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }
            
            let newURL: URL = folderURL.appending(path: url.lastPathComponent)
            
            try FileManager.default.copyItem(at: url, to: newURL)
            
            url.stopAccessingSecurityScopedResource()
            
            return newURL
        }
    }
}
