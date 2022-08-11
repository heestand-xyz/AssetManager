//
//  Created by Anton Heestand on 2022-08-11.
//

#if os(iOS)

import SwiftUI

struct AMViewModifier<Content: View>: View {
    
    @ObservedObject var assetManager: AMAssetManager
    
    let content: () -> Content
    
    var body: some View {
        content()
            .sheet(isPresented: $assetManager.showOpenFilePicker, onDismiss: {}, content: {
                OpenFilesView(types: assetManager.fileTypes ?? []) { url in
                    assetManager.fileSelectedCallback?(url)
                } cancelled: {
                    assetManager.fileSelectedCallback?(nil)
                }
            })
            .sheet(isPresented: $assetManager.showSaveFilePicker, onDismiss: {}, content: {
                if let url: URL = assetManager.fileUrl {
                    SaveFilesView(url: url)
                }
            })
            .sheet(isPresented: $assetManager.showPhotosPicker, onDismiss: {}, content: {
                PhotosView(filter: assetManager.photosFilter ?? .images) { object in
                    assetManager.photosSelectedCallback?(object)
                } cancelled: {
                    assetManager.photosSelectedCallback?(nil)
                }
            })
            .sheet(isPresented: $assetManager.showShare, onDismiss: {
                assetManager.shareItem = nil
            }) {
                if let item: Any = assetManager.shareItem {
                    ShareView(item: item)
                }
            }
    }
}

extension View {
    
    public func asset(manager: AMAssetManager) -> some View {
        AMViewModifier(assetManager: manager) {
            self
        }
    }
}

#endif
