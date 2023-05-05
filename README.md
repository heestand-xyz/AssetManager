# Asset Manager

Import, export and share files on iOS and macOS

## Setup

```swift
import SwiftUI
import AssetManager

@main
struct RenderApp: App {
    
    @StateObject private var assetManager = AMAssetManager()

    var body: some Scene {
        WindowGroup {
            ContentView(assetManager: assetManager)
                .asset(manager: assetManager)
        }
    }
}
```

## Usage

```swift
import SwiftUI
import AssetManager

struct ContentView: View {
    
    @ObservedObject var assetManager: AMAssetManager

    var body: some View {
        Button {
            assetManager.importMedia(from: .photos) { result in
                // Access imported media
            }
        } label: {
            Text("Import")
        }   
    }
}
```
