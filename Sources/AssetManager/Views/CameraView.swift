#if os(iOS)

import SwiftUI
import MobileCoreServices
import UniformTypeIdentifiers

struct CameraView: UIViewControllerRepresentable {

    @Binding var isShowing: Bool

    let mode: UIImagePickerController.CameraCaptureMode
    
    let pickedImage: (UIImage) -> ()
    let pickedVideo: (URL) -> ()
    let cancelled: () -> ()
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        if mode == .video {
            picker.mediaTypes = [UTType.movie.identifier]
            picker.videoQuality = .typeHigh
        }
        picker.cameraCaptureMode = mode
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ picker: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(mode: mode) { image in
            pickedImage(image)
            isShowing = false
        } pickedVideo: { url in
            pickedVideo(url)
            isShowing = false
        } cancelled: {
            cancelled()
            isShowing = false
        }
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
        
        let mode: UIImagePickerController.CameraCaptureMode
        let pickedImage: (UIImage) -> ()
        let pickedVideo: (URL) -> ()
        let cancelled: () -> ()
        
        init(mode: UIImagePickerController.CameraCaptureMode,
             pickedImage: @escaping (UIImage) -> Void,
             pickedVideo: @escaping (URL) -> Void,
             cancelled: @escaping () -> Void) {
            self.mode = mode
            self.pickedImage = pickedImage
            self.pickedVideo = pickedVideo
            self.cancelled = cancelled
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            switch mode {
            case .photo:
                guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                    cancelled()
                    return
                }
                pickedImage(image)
            case .video:
                guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                    cancelled()
                    return
                }
                pickedVideo(url)
            @unknown default:
                break
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            cancelled()
        }
    }
}

#endif
