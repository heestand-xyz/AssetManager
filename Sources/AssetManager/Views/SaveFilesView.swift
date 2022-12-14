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

struct SaveFilesView: UIViewControllerRepresentable {
    
    let url: URL
    let asCopy: Bool
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: asCopy)
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
}

#endif
