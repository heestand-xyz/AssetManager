//
//  Created by Anton Heestand on 2022-08-11.
//

import SwiftUI

struct AMAssetView<Content: View>: View {
    
    @ObservedObject var assetManager: AMAssetManager
    
    let content: () -> Content
    
    var body: some View {
        content()
#if os(iOS)
            .sheet(isPresented: $assetManager.showOpenFilesPicker, content: {
                OpenFilesView(types: assetManager.filesTypes ?? [],
                              multiSelect: assetManager.filesHasMultiSelect ?? false) { urls in
                    assetManager.filesSelectedCallback?(urls)
                } cancelled: {
                    assetManager.filesSelectedCallback?([])
                }
            })
            .sheet(isPresented: $assetManager.showOpenFolderPicker, content: {
                OpenFolderView { url in
                    assetManager.folderSelectedCallback?(url)
                } cancelled: {
                    assetManager.folderSelectedCallback?(nil)
                }
            })
            .sheet(isPresented: $assetManager.showSaveFilePicker, content: {
                if let url: URL = assetManager.fileUrl {
                    SaveFilesView(url: url, asCopy: assetManager.saveFileAsCopy)
                }
            })
            .fullScreenCover(isPresented: $assetManager.showCameraPicker) {
                if let mode = assetManager.cameraMode {
                    CameraView(isShowing: $assetManager.showCameraPicker,
                               mode: mode,
                               pickedImage: assetManager.cameraImageCallback,
                               pickedVideo: assetManager.cameraVideoCallback)
                }
            }
#endif
            .sheet(isPresented: $assetManager.showPhotosPicker, content: {
                PhotosView(filter: assetManager.photosFilter ?? .images,
                           multiSelect: assetManager.photosHasMultiSelect ?? false) { objects in
                    assetManager.photosSelectedCallback?(objects)
                } cancelled: {
                    assetManager.photosSelectedCallback?([])
                }
            })
#if os(iOS)
            .sheet(isPresented: $assetManager.showShare, onDismiss: {
                assetManager.shareItem = nil
            }) {
                if let item: Any = assetManager.shareItem {
                    ShareView(item: item)
                }
            }
#endif
    }
}

extension View {
    
    public func asset(manager: AMAssetManager) -> some View {
        AMAssetView(assetManager: manager) {
            self
        }
    }
}
