//
//  ViewController.swift
//  Flowers
//
//  Created by Osama Fahim on 26/06/2019.
//  Copyright © 2019 Osama Fahim. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var discriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        // Do any additional setup after loading the view, typically from a nib.
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            imageView.image = userPickedImage
            imagePicker.dismiss(animated: true, completion: nil)
            
            guard let ciImage = CIImage(image: userPickedImage) else { fatalError("Image failed to Convert to ciimage")}
            
            detect(ciimage: ciImage)
        
        }
        
    }
    
    func detect (ciimage: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{fatalError(" Failed to upload the model (VNCoreMl model)")}
        
        let requestt = VNCoreMLRequest(model: model) { (requestt, error) in
            guard let results = requestt.results as? [VNClassificationObservation],
                let firstResult = results.first
                else {fatalError("Error in VnclassificationObservation")}
            
            self.navigationItem.title = firstResult.identifier.capitalized
            //print("\(firstResult.identifier.contains)")
            self.navigationController?.navigationItem.title = "\(firstResult.identifier.contains)"
            
            let params : [String:String] = [
                "format" : "json",
                "action" : "query",
                "prop" : "extracts|pageimages",
                "exintro" : "",
                "explaintext" : "",
                "titles" : firstResult.identifier.capitalized,
                "indexpageids" : "",
                "redirects" : "1",
                "pithumbsize" : "500"
                ]
            
            self.getDetail(url : self.wikipediaURl, parameters: params)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: ciimage)
        
        do{
            try handler.perform([requestt])
        }catch{
            print("Error in performing requestn \(error)")
        }
        
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func getDetail(url: String , parameters: [ String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess{
                let detailJSON : JSON = (JSON(response.result.value!))
                let pageid = detailJSON["query"]["pageids"][0].stringValue
                let details = detailJSON ["query"]["pages"][pageid]["extract"].stringValue
                self.discriptionLabel.text = details
                
                let flowerimageURL = detailJSON ["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                print(flowerimageURL)
                self.imageView.sd_setImage(with: URL(string: flowerimageURL))
                
            }
            else{
                print("Error in getting JSON data")
            }
            
        }
        
    }

}

