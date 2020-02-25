//
//  ViewController.swift
//  pamPhotoFrame
//
//  Created by narongrit kanhanoi on 25/3/2562 BE.
//  Copyright © 2562 narongrit kanhanoi. All rights reserved.
//

import UIKit
import Photos


class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    @IBOutlet weak var cropFrame: UIView!
    let imagePicker = UIImagePickerController()
    var imageView:UIImageView?
    var isDragging = false
    var isScalling = false

    var difX:CGFloat = 0.0
    var difY:CGFloat = 0.0
    var startFingerDistance:CGFloat = 0.0
    var startScaleWidth:CGFloat = 0.0
    var startScaleHeight:CGFloat = 0.0

    var previewImage:UIImageView?

    var imageRealSize:CGSize?

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        cropFrame.layer.masksToBounds = true
        self.view.isMultipleTouchEnabled = true

    }

    @IBAction func takePhoto(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func browsePhoto(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func clickPrint2(_ sender: Any) {
        guard let image = imageView?.image else{
            return
        }
        if let cropPoint = getImageCropPoint() {
            let croppedImage = cropToBounds(image:image , cropPoint: cropPoint)
            guard let photoWithFrame = putToPhotoFrame2(croppedImage) else {
                return
            }

            saveImageToCameraRoll(photoWithFrame)
            printImage(photoWithFrame)
        }
    }

    @IBAction func clickPrint(_ sender: Any) {
        guard let image = imageView?.image else{
            return
        }
        if let cropPoint = getImageCropPoint() {
            let croppedImage = cropToBounds(image:image , cropPoint: cropPoint)
            guard let photoWithFrame = putToPhotoFrame(croppedImage) else {
                return
            }

            saveImageToCameraRoll(photoWithFrame)
            printImage(photoWithFrame)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let originalImage = info[.originalImage] as? UIImage {


            let downScaleImage = resizeImage(image: originalImage, targetSize: CGSize(width:originalImage.size.width/2 , height:originalImage.size.height/2 ))

            imageView?.removeFromSuperview()
            imageView = UIImageView(image: downScaleImage)

            if let imageView = imageView{
                let frameBounds = cropFrame.bounds

                var w:CGFloat = 0
                var h:CGFloat = 0

                imageRealSize = imageView.frame.size

                if(imageView.bounds.width > imageView.bounds.height ){
                    h = frameBounds.height
                    w = imageView.bounds.width * (h/imageView.bounds.height)
                }else{
                    w = frameBounds.width
                    h = imageView.bounds.height * (w/imageView.bounds.width)
                }

                let x = frameBounds.width/2 - w/2
                let y = frameBounds.height/2 - h/2
                imageView.frame = CGRect(x: x, y: y, width: w, height: h)

                cropFrame.addSubview(imageView)
            }

            picker.dismiss(animated: true, completion: nil)
        }

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion:nil)
    }

}


extension ViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let allTouch = event?.allTouches  else{
            return
        }
        if allTouch.count == 1{
            moveMode(topuchs: allTouch)
        }
        if allTouch.count >= 2{
            scaleMode(topuchs: allTouch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let imageView = imageView, let allTouch = event?.allTouches  else{
            return
        }

        if isScalling && allTouch.count == 1 {
            moveMode(topuchs: allTouch)
        }else if isDragging && allTouch.count >= 2 {
            scaleMode(topuchs: allTouch)
        }

        if isDragging{
            guard let point1 = allTouch.first?.location(in: cropFrame) else {
                return
            }
            let currentFrame = imageView.frame
            
            imageView.frame = CGRect(x:point1.x-difX , y: point1.y-difY, width: currentFrame.width, height: currentFrame.height)
        }

        if isScalling{
            var arr:[UITouch] = []
            allTouch.forEach {
                arr.append($0)
            }

            guard arr.count >= 2 else {
                return
            }

            let point1 = arr[0].location(in: cropFrame)
            let point2 = arr[1].location(in: cropFrame)

            let middle = middlePoint(point1: point1, point2: point2)

            let fingerDistance = distance(point1: point1, point2: point2)
            let distanceDiffPercentage = fingerDistance/startFingerDistance

            let w = startScaleWidth * distanceDiffPercentage
            let h = startScaleHeight * distanceDiffPercentage

            imageView.frame = CGRect(x: (middle.x-difX)*distanceDiffPercentage , y: (middle.y-difY)*distanceDiffPercentage, width: w, height: h)

        }

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        isScalling = false

    }


    func moveMode(topuchs:Set<UITouch>){
        guard let imageView = imageView else {
            return
        }

        guard let point1 = topuchs.first?.location(in: cropFrame) else {
            return
        }

        if cropFrame.bounds.contains(point1) {
            difX = point1.x - imageView.frame.minX
            difY = point1.y - imageView.frame.minY
            isDragging = true
            isScalling = false
        }
    }

    func scaleMode(topuchs:Set<UITouch>){
        guard let imageView = imageView else {
            return
        }

        var arr:[UITouch] = []
        topuchs.forEach {
            arr.append($0)
        }

        guard arr.count >= 2 else {
            return
        }

        let point1 = arr[0].location(in: cropFrame)
        let point2 = arr[1].location(in: cropFrame)

        let middle = middlePoint(point1: point1, point2: point2)
        difX = middle.x - imageView.frame.minX
        difY = middle.y - imageView.frame.minY
        startFingerDistance = distance(point1: point1, point2: point2)
        startScaleWidth = imageView.frame.width
        startScaleHeight = imageView.frame.height

        if cropFrame.bounds.contains(point1) && cropFrame.bounds.contains(point2) {
            isDragging = false
            isScalling = true
        }

    }

}



extension ViewController{
    func middlePoint( point1:CGPoint, point2:CGPoint )->CGPoint{
        let middleX = (point1.x + point2.x) * 0.5
        let middleY = (point1.y + point2.y) * 0.5
        return CGPoint(x: middleX, y: middleY)
    }

    func distance( point1:CGPoint, point2:CGPoint )->CGFloat{
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt( (dx*dx) + (dy*dy) )
    }

    func getImageCropPoint() -> CropPoint? {
        guard let imageView = imageView, let imageRealSize = imageRealSize else {
            return nil
        }

        let frameBounds = cropFrame.bounds

        let zoomScale = imageView.frame.width / imageRealSize.width

        var startX = imageView.frame.minX * -1
        var startY = imageView.frame.minY * -1

        if startX < 0 {
            startX = 0
        }
        if startY < 0 {
            startY = 0
        }

        var endX = startX + frameBounds.width
        var endY = startY + frameBounds.height

        if endX > imageView.frame.width  {
            endX = imageView.frame.width
            startX = imageView.frame.width - frameBounds.width
        }
        if endY > imageView.frame.height  {
            endY = imageView.frame.height
            startY = imageView.frame.height - frameBounds.height
        }

        return CropPoint(
            startPoint: CGPoint(x: startX / zoomScale, y: startY / zoomScale),
            endPoint: CGPoint(x: endX / zoomScale , y: endY / zoomScale ))

    }

    func cropToBounds(image: UIImage, cropPoint:CropPoint) -> UIImage {

        let cropRect = CGRect(x: cropPoint.startPoint.x , y: cropPoint.startPoint.y,
                              width: cropPoint.endPoint.x - cropPoint.startPoint.x ,
                              height: cropPoint.endPoint.y - cropPoint.startPoint.y )

        let contextImage = image.cgImage

        let imageRef: CGImage = (contextImage?.cropping(to: cropRect)!)!

        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        return image
    }

    func putToPhotoFrame(_ bottomImage:UIImage) -> UIImage?{
        guard let topImage = UIImage(named: "frame.png") else {
            return nil
        }
        let size = topImage.size

        UIGraphicsBeginImageContextWithOptions(size, false, 1);
        let areaSize = CGRect(x: 70, y: 79, width:1042, height: 1042)
        bottomImage.draw(in: areaSize)
        topImage.draw(in: CGRect(x: 0, y: 0, width:size.width, height: size.height ))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    func putToPhotoFrame2(_ bottomImage:UIImage) -> UIImage?{
        guard let topImage = UIImage(named: "frame2.png") else {
            return nil
        }
        let size = topImage.size

        UIGraphicsBeginImageContextWithOptions(size, false, 1);
        let areaSize = CGRect(x: 79, y: 109, width:1042, height: 1042)
        bottomImage.draw(in: areaSize)
        topImage.draw(in: CGRect(x: 0, y: 0, width:size.width, height: size.height ))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let image = UIImage(cgImage: newImage.cgImage! , scale: newImage.scale, orientation: .right)

        return image
    }

    func saveImage(_ image: UIImage) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            return nil
        }

        do {
            var imageURL = FileManager.default.temporaryDirectory
            imageURL.appendPathComponent("tempPhoto.jpg")
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            return nil
        }
    }


    func saveImageToCameraRoll(_ snapshot: UIImage){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: snapshot)
        }, completionHandler: { success, error in
            if success {
                // Saved successfully!
            }
            else if error != nil {
                // Save photo failed with error
            }
            else {
                // Save photo failed with no error
            }
        })
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width:size.width * heightRatio, height:size.height * heightRatio)
        } else {
            newSize = CGSize(width:size.width * widthRatio,  height:size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func printImage(_ photo:UIImage){
        guard let imageFile = saveImage(photo) else {
            return
        }

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary:nil)
        printInfo.outputType = .photo
        printInfo.jobName = "photo print"
        printController.printInfo = printInfo
        printController.printingItem = imageFile
        printController.present(from: self.view.frame, in: self.view, animated: true, completionHandler: nil)
    }
}


struct CropPoint{
    let startPoint:CGPoint
    let endPoint:CGPoint
}
