//
//  Created by Anton Heestand on 2022-08-11.
//

#if os(iOS)

import SwiftUI

struct AMAssetView<Content: View>: View {
    
    @ObservedObject var assetManager: AMAssetManager
    
    let content: () -> Content
    
    var body: some View {
        content()
            .sheet(isPresented: $assetManager.showOpenFilesPicker, onDismiss: {}, content: {
                OpenFilesView(types: assetManager.filesTypes ?? [],
                              multiSelect: assetManager.filesHasMultiSelect ?? false) { urls in
                    assetManager.filesSelectedCallback?(urls)
                } cancelled: {
                    assetManager.filesSelectedCallback?([])
                }
            })
            .sheet(isPresented: $assetManager.showOpenFolderPicker, onDismiss: {}, content: {
                OpenFolderView { url in
                    assetManager.folderSelectedCallback?(url)
                } cancelled: {
                    assetManager.folderSelectedCallback?(nil)
                }
            })
            .sheet(isPresented: $assetManager.showSaveFilePicker, onDismiss: {}, content: {
                if let url: URL = assetManager.fileUrl {
                    SaveFilesView(url: url)
                }
            })
            .sheet(isPresented: $assetManager.showPhotosPicker, onDismiss: {}, content: {
                if #available(iOS 16.0, *) {
                    PhotosView(filter: assetManager.photosFilter ?? .images,
                               multiSelect: assetManager.photosHasMultiSelect ?? false) { objects in
                        assetManager.photosSelectedCallback?(objects)
                    } cancelled: {
                        assetManager.photosSelectedCallback?([])
                    }
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
        AMAssetView(assetManager: manager) {
            self
        }
    }
}

#endif
