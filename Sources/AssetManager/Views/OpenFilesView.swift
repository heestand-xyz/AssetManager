//
//  FilesView.swift
//  Magnet Crop
//
//  Created by Anton Heestand on 2020-07-05.
//

#if os(iOS)

import UIKit
import SwiftUI
import UniformTypeIdentifiers

struct OpenFilesView: UIViewControllerRepresentable {
    
    let types: [UTType]
    
    let pickedFiles: (URL) -> ()
    
    let cancelled: () -> ()
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        context.coordinator.pickedFiles = { url in
            DispatchQueue.main.async {
                pickedFiles(url)
            }
        }
        context.coordinator.cancelled = {
            DispatchQueue.main.async {
                cancelled()
            }
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        var pickedFiles: ((URL) -> ())?
        
        var cancelled: (() -> ())?
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url: URL = urls.first else { return }
            pickedFiles?(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            cancelled?()
        }
        
    }
    
}

#endif
