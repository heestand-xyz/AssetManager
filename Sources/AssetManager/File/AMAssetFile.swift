//
//  AMAssetFile.swift
//  Circles
//
//  Created by Anton Heestand on 2021-05-17.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)
public typealias AMImage = NSImage
#else
public typealias AMImage = UIImage
#endif

public protocol AMAssetFile {
    var name: String? { get }
}

public struct AMAssetURLFile: AMAssetFile {
    public let name: String?
    public let url: URL
    public init(name: String? = nil, url: URL) {
        self.name = name
        self.url = url
    }
}

public struct AMAssetDataFile: AMAssetFile {
    public let name: String?
    public let data: Data
    public init(name: String? = nil, data: Data) {
        self.name = name
        self.data = data
    }
}

public struct AMAssetImageFile: AMAssetFile {
    public let name: String?
    public let image: AMImage
    public init(name: String? = nil, image: AMImage) {
        self.name = name
        self.image = image
    }
}
