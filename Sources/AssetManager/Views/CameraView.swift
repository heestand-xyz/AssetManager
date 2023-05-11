import SwiftUI

#if os(iOS)

struct CameraView: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentationMode

    let mode: UIImagePickerController.CameraCaptureMode
    
    let picked: (UIImage) -> ()
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = mode
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ picker: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator { image in
            if let image {
                picked(image)
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
        
        let picked: (UIImage?) -> ()
        
        init(picked: @escaping (UIImage?) -> Void) {
            self.picked = picked
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                picked(nil)
                return
            }
            picked(image)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picked(nil)
        }
    }
}

#endif
