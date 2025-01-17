//
//  Created by Anton Heestand on 2022-08-11.
//

import SwiftUI

extension View {
    
    public func asset(manager: AMAssetManager) -> some View {
        AMAssetView(assetManager: manager) {
            self
        }
    }
}

struct AMAssetView<Content: View>: View {
    
    @Bindable var assetManager: AMAssetManager
    
    let content: () -> Content
    
    var body: some View {
        content()
#if os(iOS) || os(visionOS)
            .sheet(isPresented: $assetManager.showOpenFilesPicker,
                   content: {
                OpenFilesView(
                    types: assetManager.filesTypes ?? [],
                    directoryURL: assetManager.filesDirectoryURL,
                    multiSelect: assetManager.filesHasMultiSelect ?? false
                ) { urls in
                    assetManager.filesSelectedCallback?(urls)
                } cancelled: {
                    assetManager.filesSelectedCallback?([])
                }
                .ignoresSafeArea()
            })
            .sheet(isPresented: $assetManager.showOpenFolderPicker,
                   content: {
                OpenFolderView(
                    directoryURL: assetManager.folderDirectoryURL
                ) { url in
                    assetManager.folderSelectedCallback?(url)
                } cancelled: {
                    assetManager.folderSelectedCallback?(nil)
                }
                .ignoresSafeArea()
            })
            .sheet(isPresented: $assetManager.showSaveFilePicker,
                   content: {
                if let urls: [URL] = assetManager.fileUrls {
                    SaveFilesView(urls: urls,
                                  directoryURL: assetManager.saveDirectoryURL,
                                  asCopy: assetManager.saveFileAsCopy,
                                  completion: { urls in
                        assetManager.saveFileCompletion?(urls)
                    })
                    .ignoresSafeArea()
                }
            })
#endif
#if os(iOS)
            .fullScreenCover(isPresented: $assetManager.showCameraPicker) {
                if let mode = assetManager.cameraMode {
                    CameraView(isShowing: $assetManager.showCameraPicker,
                               mode: mode,
                               pickedImage: { image in
                        assetManager.cameraImageCallback?(image)
                    },
                               pickedVideo: { url in
                        assetManager.cameraVideoCallback?(url)
                    }, cancelled: {
                        assetManager.cameraCancelCallback?()
                    })
                    .ignoresSafeArea()
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
                .ignoresSafeArea()
#if os(macOS)
                .frame(minWidth: 800, minHeight: 400)
#endif
            })
#if os(iOS) || os(visionOS)
            .sheet(isPresented: $assetManager.showShare, onDismiss: {
                assetManager.shareItems = nil
            }) {
                if let items: [Any] = assetManager.shareItems {
                    ShareView(items: items)
                        .ignoresSafeArea()
                }
            }
#endif
    }
}
