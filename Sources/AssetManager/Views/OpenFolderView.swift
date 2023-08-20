#if os(iOS) || os(xrOS)

import UIKit
import SwiftUI
import UniformTypeIdentifiers

struct OpenFolderView: UIViewControllerRepresentable {
    
    let pickedFolder: (URL) -> ()
    let cancelled: () -> ()
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        context.coordinator.pickedFolder = { url in
            DispatchQueue.main.async {
                pickedFolder(url)
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
        
        var pickedFolder: ((URL) -> ())?
        
        var cancelled: (() -> ())?
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first
            else { return }
            pickedFolder?(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            cancelled?()
        }
    }
}

#endif
