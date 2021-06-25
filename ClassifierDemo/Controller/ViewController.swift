//
//  ViewController.swift
//  ClassifierDemo
//
//  Created by Vitor Bryan on 21/06/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet var classificationLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    @IBAction func loadImageButton(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: AnimalClassifier().model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .scaleFit
            return request
            
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func processClassifications(for request: VNRequest, error: Error?) {
            DispatchQueue.main.async {
                guard let results = request.results else {
                    self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                    return
                }
                let classifications = results as! [VNClassificationObservation]

                if classifications.isEmpty {
                    self.classificationLabel.text = "Nothing recognized."
                } else {
                    let topClassifications = classifications.prefix(2)
                         let descriptions = topClassifications.map { classification in
                           return String(format: "(%.2f) %@", classification.confidence * 100, classification.identifier)
                       }
                       self.classificationLabel.text = descriptions.joined(separator: " | ")
                }
            }
        }
    
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
        guard let ciImage = CIImage(image: image)
        else {
            fatalError("Unable to create \(CIImage.self) from \(image)")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
            
            updateClassifications(for: pickedImage)
        }
        dismiss(animated: true, completion: nil)
    }
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navigationItem.title = "Animal Classifier"
    }
    
    



}


