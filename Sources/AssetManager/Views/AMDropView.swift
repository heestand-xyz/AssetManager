//
//  Created by Anton Heestand on 2022-08-12.
//

#if os(iOS)

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
            of: AMAssetManager.AssetType.image.types,
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
            of: AMAssetManager.AssetType.image.types + AMAssetManager.AssetType.video.types,
            isTargeted: isTargeted
        ) { providers in
            
            assetManager.dropMedia(providers: providers) { assetFiles in
                completion(assetFiles)
            }
            
            return true
        }
    }
    
    @ViewBuilder
    public func onDropOfURLs(
        filenameExtension: String,
        assetManager: AMAssetManager,
        isTargeted: Binding<Bool>? = nil,
        completion: @escaping ([URL]) -> ()
    ) -> some View {
        
        if let type = UTType(filenameExtension: filenameExtension) {
            
            self.onDrop(
                of: [type],
                isTargeted: isTargeted
            ) { providers in
                
                assetManager.dropURLs(type: type, providers: providers) { urls in
                    completion(urls)
                }
                
                return true
            }
        }
    }
}

#endif
