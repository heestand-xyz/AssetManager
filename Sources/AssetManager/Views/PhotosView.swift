//
//  PhotosView.swift
//  Magnet Crop
//
//  Created by Anton Heestand on 2020-07-05.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SwiftUI
import PhotosUI
import MultiViews

struct PhotosView: ViewRepresentable {
    
    let filter: PHPickerFilter
    let multiSelect: Bool
    let pickedContent: ([Any]) -> ()
    let cancelled: () -> ()
    
    func makeView(context: Context) -> NSView {
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
        return picker.view
    }
    
    func updateView(_ view: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        
        var picker: PHPickerViewController!
        
        var pickedContent: (([Any]) -> ())?
        
        var cancelled: (() -> ())?
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if results.isEmpty {
                cancelled?()
                return
            }
            Task {
                var assets: [Any] = []
                
                for result in results {
                    
                    if result.itemProvider.canLoadObject(ofClass: AMImage.self) {
                        
                        if let image: AMImage = try? await withCheckedThrowingContinuation({ continuation in
                            result.itemProvider.loadObject(ofClass: AMImage.self, completionHandler: { provider, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                continuation.resume(returning: provider as? AMImage)
                            })
                        }) {
                            assets.append(image as Any)
                        }
                        
                    } else {
                        
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
                                do {
                                    let _ = url.startAccessingSecurityScopedResource()
                                    
                                    let folderURL: URL = FileManager.default.temporaryDirectory
                                        .appending(component: "import-video")
                                        .appending(component: "\(UUID())")
                                    if !FileManager.default.fileExists(atPath: folderURL.path) {
                                        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                                    }
                                    
                                    let newURL: URL = folderURL.appending(path: url.lastPathComponent)
                                    
                                    let data = try Data(contentsOf: url)
                                    try data.write(to: newURL)
                                    
                                    url.stopAccessingSecurityScopedResource()
                                    
                                    continuation.resume(returning: newURL)
                                } catch {
                                    continuation.resume(throwing: error)
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
    }
}
