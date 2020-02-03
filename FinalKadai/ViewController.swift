//
//  ViewController.swift
//  FinalKadai
//
//  Created by Alvin Endratno on 2019/12/09.
//  Copyright © 2019 Alvin Endratno. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var keyword:[String] = ["",""]
    let group = DispatchGroup()
    @IBOutlet weak var resnotText: UILabel!
    @IBOutlet weak var resultText: UILabel!
    @IBOutlet weak var canvas: UIImageView!
    @IBOutlet weak var descText: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var takeButton: UIButton!
    @IBAction func TakeAction(_ sender: Any) {
        startcamera()
    }

// カメラ起動
    func startcamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
// 分析
    func createRequestMobile() -> VNCoreMLRequest{
        let modelUrl = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc")
        let model = try? VNCoreMLModel(for: MLModel(contentsOf: modelUrl!))
        let req = VNCoreMLRequest(model:model!, completionHandler: {req, err in
            DispatchQueue.main.async(execute: {
                guard let results = req.results as? [VNClassificationObservation] else {
                    fatalError("error")
                }
                
                self.keyword[0] = results[0].identifier.components(separatedBy: ",")[0]
                self.resultText.text = "これは\(results[0].identifier)のかな？もしかして\(results[1].identifier)"
            })
        })
        
        req.imageCropAndScaleOption = .centerCrop
        return req
    }
    
    func createRequestResNet() -> VNCoreMLRequest{
        let modelUrl = Bundle.main.url(forResource: "Resnet50", withExtension: "mlmodelc")
        let model = try? VNCoreMLModel(for: MLModel(contentsOf: modelUrl!))
        let req = VNCoreMLRequest(model:model!, completionHandler: {req, err in
            DispatchQueue.main.async(execute: {
                guard let results = req.results as? [VNClassificationObservation] else {
                    fatalError("error")
                }
                self.keyword[1] = results[0].identifier.components(separatedBy: ",")[0]
                self.resnotText.text = "いやいや、これは明らかに\(results[0].identifier)か\(results[1].identifier)だろう"
                })
            })
        
        req.imageCropAndScaleOption = .centerCrop
        return req
        
    }

// 画像分析
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        canvas.image = image
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        group.enter()
        setLoading(loadingDesc: "画像処理中")
        DispatchQueue.main.async {
            try? handler.perform([self.createRequestMobile(),self.createRequestResNet()])
            self.group.leave()
        }
        
        group.notify(queue: .main) {
            self.setLoading(loadingDesc: "分析中")
            self.processWord()
        }
        dismiss(animated: true, completion: nil)
    }

// データ分析
    
    func processWord() {
        var refWord = ""
        if(keyword[0] != keyword[1]) {
            
            func handleOnClickFirstButton(){
                refWord = keyword[0]
                let referenceVC = UIReferenceLibraryViewController(term: refWord)
                self.present(referenceVC, animated: true, completion: nil)
                setFinishedLoading()
            }
            
            func handleOnClickSecondButton(){
                refWord = keyword[1]
                let referenceVC = UIReferenceLibraryViewController(term: refWord)
                self.present(referenceVC, animated: true, completion: nil)
                setFinishedLoading()
            }
            
            optionBox(messageTitle: "複数オブジェクト", messageAlert: "一つ選んでください", alertActionStyle: .default, firstButtonTitle: keyword[0], secondButtonTitle: keyword[1], handleOnClickFirstButton: handleOnClickFirstButton, handleOnClickSecondButton: handleOnClickSecondButton)

        } else {
            refWord = keyword[0]
            let referenceVC = UIReferenceLibraryViewController(term: refWord)
            self.present(referenceVC, animated: true, completion: nil)
            setFinishedLoading()
        }
        
    }

// ここからしたは Utils
    
    func setLoading (loadingDesc: String) {
        takeButton.isEnabled = false
        takeButton.alpha = 0.4
        self.descText.text = loadingDesc
    }
    
    func setFinishedLoading () {
        takeButton.isEnabled = true
        takeButton.alpha = 1
        self.descText.text = "処理完了"
    }
    
    func optionBox(
        messageTitle: String,
        messageAlert: String,
        alertActionStyle: UIAlertAction.Style,
        firstButtonTitle: String,
        secondButtonTitle: String,
        handleOnClickFirstButton: @escaping () -> Void,
        handleOnClickSecondButton: @escaping () -> Void
    )
    {
        let alert = UIAlertController(title: messageTitle, message: messageAlert, preferredStyle: .alert)

        let firstButtonAction = UIAlertAction(title: firstButtonTitle, style: alertActionStyle) { _ in
            handleOnClickFirstButton()
        }
        
        let secondButtonAction = UIAlertAction(title: secondButtonTitle, style: alertActionStyle) { _ in
            handleOnClickSecondButton()
        }
        
        alert.addAction(firstButtonAction)
        alert.addAction(secondButtonAction)

        present(alert, animated: true, completion: nil)
    }

}

