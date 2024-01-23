//
//  ShareView.swift
//  Magnet Crop
//
//  Created by Anton Heestand on 2020-07-12.
//

#if os(iOS) || os(visionOS)

import Foundation
import SwiftUI

struct ShareView: UIViewControllerRepresentable {

    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#endif
