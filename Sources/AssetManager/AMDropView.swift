//
//  Created by Anton Heestand on 2022-08-12.
//

import SwiftUI
import UniformTypeIdentifiers

extension View {
    
    public func onDropOfImages(
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([AMImage]) -> ()
    ) -> some View {
        
        self.onDrop(
            of: AMAssetManager.AssetType.image.types,
            isTargeted: isTargeted
        ) { providers in
            
            assetManager.dropImages(providers: providers) { images in
                completion(images)
            }
            
            return true
        }
    }
    
    public func onDropOfVideos(
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([URL]) -> ()
    ) -> some View {
        
        self.onDrop(
            of: AMAssetManager.AssetType.video.types,
            isTargeted: isTargeted
        ) { providers in
            
            assetManager.dropVideos(providers: providers) { urls in
                completion(urls)
            }
            
            return true
        }
    }
    
    public func onDropOfMedia(
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([AMAssetFile]) -> ()
    ) -> some View {
        
        self.onDrop(
            of: AMAssetManager.AssetType.media.types,
            isTargeted: isTargeted
        ) { providers in
            
            assetManager.dropMedia(providers: providers) { assetFiles in
                completion(assetFiles)
            }
            
            return true
        }
    }
    
    @available(*, deprecated, renamed: "onDropOfURLs(filenameExtension:assetManager:isTargeted:asCopy:completion:)")
    @ViewBuilder
    public func onDropOfURLs(
        filenameExtension: String,
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([URL]) -> ()
    ) -> some View {
        if let type = UTType(filenameExtension: filenameExtension) {
            onDropOfURLs(types: [type], assetManager: assetManager, isTargeted: isTargeted, asCopy: false, completion: {
                if case .success(let urls) = $0 {
                    completion(urls)
                }
            })
        }
    }
    
    @ViewBuilder
    public func onDropOfURLs(
        filenameExtension: String,
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        asCopy: Bool,
        completion: @escaping (Result<[URL], Error>) -> ()
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
        completion: @escaping (Result<[URL], Error>) -> ()
    ) -> some View {
        onDrop(
            of: types,
            isTargeted: isTargeted
        ) { providers in
            Task {
                do {
                    let urls: [URL] = try await assetManager.dropURLs(types: types, providers: providers, asCopy: asCopy)
                    await MainActor.run {
                        completion(.success(urls))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
            }
            return true
        }
    }
}
