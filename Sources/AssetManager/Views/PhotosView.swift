//
//  PhotosView.swift
//  Magnet Crop
//
//  Created by Anton Heestand on 2020-07-05.
//

#if os(iOS)

import UIKit
import SwiftUI
import PhotosUI

struct PhotosView: UIViewControllerRepresentable {
    
    let filter: PHPickerFilter
    let multiSelect: Bool
    let pickedContent: ([Any]) -> ()
    let cancelled: () -> ()
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
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
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        
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
                    
                    if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                        
                        let image: UIImage? = try? await withCheckedThrowingContinuation { continuation in
                            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { provider, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                continuation.resume(returning: provider as? UIImage)
                            })
                        }
                        assets.append(image as Any)
                        
                    } else {
                        
                        let url: URL? = try? await withCheckedThrowingContinuation { continuation in
                            result.itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { object, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                    return
                                }
                                continuation.resume(returning: object as? URL)
                            }
                        }
                        assets.append(url as Any)
                    }
                }
                await MainActor.run {
                    pickedContent?(assets)
                }
            }
        }
    }
}

#endif
