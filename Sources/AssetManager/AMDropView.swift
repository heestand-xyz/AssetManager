//
//  Created by Anton Heestand on 2022-08-12.
//

import SwiftUI
import UniformTypeIdentifiers
import TextureMap

extension View {
    
    public func onDropOfImages(
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([AMAssetImageFile], CGPoint) -> ()
    ) -> some View {
        
        self.onDrop(
            of: AMAssetManager.AssetType.image.types,
            isTargeted: isTargeted
        ) { providers, location in
            Task {
                guard let images: [AMAssetImageFile] = try? await assetManager.dropImages(providers: providers), !images.isEmpty else { return }
                completion(images, location)
            }
            return true
        }
    }
    
    public func onDropOfVideos(
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([URL], CGPoint) -> ()
    ) -> some View {
        
        self.onDrop(
            of: AMAssetManager.AssetType.video.types,
            isTargeted: isTargeted
        ) { providers, location in
            Task {
                guard let urls: [URL] = try? await assetManager.dropVideos(providers: providers), !urls.isEmpty else { return }
                completion(urls, location)
            }
            return true
        }
    }
    
    public func onDropOfMedia(
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([AMAssetFile], CGPoint) -> ()
    ) -> some View {
        
        self.onDrop(
            of: AMAssetManager.AssetType.media.types,
            isTargeted: isTargeted
        ) { providers, location in
            Task {
                guard let assetFiles: [AMAssetFile] = try? await assetManager.dropMedia(providers: providers), !assetFiles.isEmpty else { return }
                completion(assetFiles, location)
            }
            return true
        }
    }
    
    @ViewBuilder
    public func onDropOfURLs(
        filenameExtension: String,
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        asCopy: Bool,
        completion: @escaping (Result<[URL], Error>, CGPoint) -> ()
    ) -> some View {
        if let type = UTType(filenameExtension: filenameExtension) {
            onDropOfURLs(types: [type], assetManager: assetManager, isTargeted: isTargeted, asCopy: asCopy, completion: completion)
        }
    }
    
    public func onDropOfURLs(
        types: [UTType],
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        asCopy: Bool,
        completion: @escaping (Result<[URL], Error>, CGPoint) -> ()
    ) -> some View {
        onDrop(
            of: types,
            isTargeted: isTargeted
        ) { providers, location in
            Task {
                do {
                    let urls: [URL] = try await assetManager.dropURLs(types: types, providers: providers, asCopy: asCopy)
                    await MainActor.run {
                        completion(.success(urls), location)
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error), location)
                    }
                }
            }
            return true
        }
    }
}
