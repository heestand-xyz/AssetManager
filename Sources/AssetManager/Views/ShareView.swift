//
//  ShareView.swift
//  Magnet Crop
//
//  Created by Anton Heestand on 2020-07-12.
//

#if os(iOS) || os(xrOS)

import Foundation
import SwiftUI

struct ShareView: UIViewControllerRepresentable {

    var item: Any

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [item], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#endif
