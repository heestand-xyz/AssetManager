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
    let completed: (Error?) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        shareController.completionWithItemsHandler = { (activityType, _: Bool, returnedItems: [Any]?, error: Error?) in
            completed(error)
        }
        return shareController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#endif
