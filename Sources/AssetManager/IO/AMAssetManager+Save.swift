//
//  AMAssetManager+Save.swift
//  AMAssetManager+Save
//
//  Created by Anton Heestand on 2021-09-19.
//

#if os(macOS)

import AppKit
import AVKit

extension AMAssetManager {
    
    func saveFile(url: URL,
                  title: String? = nil,
                  completion: @escaping (Error?) -> ()) {
        do {
            
            let data: Data = try Data(contentsOf: url)
            
            let savePanel = NSSavePanel()
            savePanel.title = title ?? "Save File"
            savePanel.canCreateDirectories = true
            savePanel.nameFieldStringValue = url.lastPathComponent
            
            savePanel.begin { response in
                
                guard response != .cancel, let url: URL = savePanel.url else {
                    completion(nil)
                    return
                }
                
                do {
                    try data.write(to: url)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        } catch {
            completion(error)
        }
    }
}

#endif
