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
                  completion: ((Error?) -> ())? = nil) {
        do {
            
            let data: Data = try Data(contentsOf: url)
            
            saveFile(data: data, title: title, name: url.lastPathComponent, completion: completion)
            
        } catch {
            completion?(error)
        }
    }
    
    func saveFile(data: Data,
                  title: String? = nil,
                  name: String,
                  completion: ((Error?) -> ())? = nil) {
        
        do {
            
            let savePanel = NSSavePanel()
            savePanel.title = title ?? "Save File"
            savePanel.canCreateDirectories = true
            savePanel.nameFieldStringValue = name
            
            savePanel.begin { response in
                
                guard response != .cancel, let url: URL = savePanel.url else {
                    completion?(nil)
                    return
                }
                
                do {
                    try data.write(to: url)
                    completion?(nil)
                } catch {
                    completion?(error)
                }
            }
        } catch {
            completion?(error)
        }
    }
}

#endif
