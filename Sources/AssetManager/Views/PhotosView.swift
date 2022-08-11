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
    
    let pickedContent: (Any?) -> ()
    
    let cancelled: () -> ()
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = filter
        configuration.selectionLimit = 1
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
        
        var pickedContent: ((Any?) -> ())?
        
        var cancelled: (() -> ())?
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result: PHPickerResult = results.first else {
                cancelled?()
                return
            }
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] provider, error in
                    guard error == nil else {
                        self?.pickedContent?(nil)
                        return
                    }
                    guard let image: UIImage = provider as? UIImage else {
                        self?.pickedContent?(nil)
                        return
                    }
                    self?.pickedContent?(image)
                })
            } else {
                result.itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { [weak self] object, error in
                    guard error == nil else {
                        self?.pickedContent?(nil)
                        return
                    }
                    guard let url: URL = object as? URL else {
                        self?.pickedContent?(nil)
                        return
                    }
                    self?.pickedContent?(url)
                }
            }
        }
    }
}

#endif
