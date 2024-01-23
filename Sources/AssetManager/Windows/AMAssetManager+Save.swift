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
    }
    
    func saveFilesInFolder(_ items: [(data: Data, name: String)],
                           title: String? = nil,
                           completion: ((Error?) -> ())? = nil) {
        openFolder(title: title ?? "Save Files in Folder") { result in
            switch result {
            case .success(let folderURL):
                guard let folderURL else {
                    completion?(nil)
                    return
                }
                do {
                    for item in items {
                        let url = folderURL.appending(component: item.name)
                        try item.data.write(to: url)
                    }
                    completion?(nil)
                } catch {
                    completion?(error)
                }
            case .failure(let error):
                completion?(error)
            }
        }
    }
}

#endif
