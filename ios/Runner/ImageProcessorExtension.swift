import UIKit
import CoreImage
import Accelerate

extension ImageProcessor {
    
    // MARK: - Advanced Perspective Correction
    func advancedPerspectiveCorrection(image: CGImage, corners: [CGPoint]) -> CGImage? {
        guard corners.count == 4 else { return nil }
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let ciImage = CIImage(cgImage: image)
        
        // Sắp xếp corners theo thứ tự đúng
        let sortedCorners = orderCorners(corners)
        
        // Sử dụng CIPerspectiveCorrection filter
        guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            return nil
        }
        
        perspectiveFilter.setValue(ciImage, forKey: kCIInputImageKey)
        perspectiveFilter.setValue(CIVector(cgPoint: sortedCorners[0]), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(cgPoint: sortedCorners[1]), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(cgPoint: sortedCorners[2]), forKey: "inputBottomRight")
        perspectiveFilter.setValue(CIVector(cgPoint: sortedCorners[3]), forKey: "inputBottomLeft")
        
        guard let outputImage = perspectiveFilter.outputImage else {
            return nil
        }
        
        // Tạo CGImage từ CIImage
        let outputRect = outputImage.extent
        return context.createCGImage(outputImage, from: outputRect)
    }
    
    private func orderCorners(_ corners: [CGPoint]) -> [CGPoint] {
        // Tìm center point
        let centerX = corners.map { $0.x }.reduce(0, +) / CGFloat(corners.count)
        let centerY = corners.map { $0.y }.reduce(0, +) / CGFloat(corners.count)
        let center = CGPoint(x: centerX, y: centerY)
        
        // Phân loại các góc dựa trên vị trí so với center
        var topLeft: CGPoint?
        var topRight: CGPoint?
        var bottomLeft: CGPoint?
        var bottomRight: CGPoint?
        
        for corner in corners {
            if corner.x < center.x && corner.y < center.y {
                topLeft = corner
            } else if corner.x > center.x && corner.y < center.y {
                topRight = corner
            } else if corner.x < center.x && corner.y > center.y {
                bottomLeft = corner
            } else {
                bottomRight = corner
            }
        }
        
        // Trả về theo thứ tự: topLeft, topRight, bottomRight, bottomLeft
        return [
            topLeft ?? corners[0],
            topRight ?? corners[1], 
            bottomRight ?? corners[2],
            bottomLeft ?? corners[3]
        ]
    }
    
    // MARK: - Image Enhancement
    func enhanceImage(_ image: CGImage) -> CGImage? {
        let context = CIContext()
        let ciImage = CIImage(cgImage: image)
        
        // Áp dụng các filter để cải thiện chất lượng
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust"),
              let contrastFilter = CIFilter(name: "CIColorControls"),
              let sharpenFilter = CIFilter(name: "CISharpenLuminance") else {
            return image
        }
        
        // Điều chỉnh exposure
        exposureFilter.setValue(ciImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(0.3, forKey: kCIInputEVKey)
        
        guard let exposedImage = exposureFilter.outputImage else { return image }
        
        // Điều chỉnh contrast
        contrastFilter.setValue(exposedImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
        contrastFilter.setValue(1.1, forKey: kCIInputSaturationKey)
        
        guard let contrastedImage = contrastFilter.outputImage else { return image }
        
        // Sharpen
        sharpenFilter.setValue(contrastedImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
        
        guard let finalImage = sharpenFilter.outputImage else { return image }
        
        return context.createCGImage(finalImage, from: finalImage.extent)
    }
    
    // MARK: - Document Detection Utilities
    func findLargestQuadrangle(in image: UIImage) -> [CGPoint]? {
        guard let cgImage = image.cgImage else { return nil }
        
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 3.0
        request.minimumSize = 0.2
        request.maximumObservations = 10
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let results = request.results as? [VNRectangleObservation] else {
                return nil
            }
            
            // Tìm rectangle lớn nhất
            let largestRect = results.max { first, second in
                first.boundingBox.width * first.boundingBox.height < 
                second.boundingBox.width * second.boundingBox.height
            }
            
            guard let rect = largestRect else { return nil }
            
            // Chuyển đổi coordinates
            let imageSize = image.size
            return [
                CGPoint(x: rect.topLeft.x * imageSize.width, 
                       y: (1 - rect.topLeft.y) * imageSize.height),
                CGPoint(x: rect.topRight.x * imageSize.width, 
                       y: (1 - rect.topRight.y) * imageSize.height),
                CGPoint(x: rect.bottomRight.x * imageSize.width, 
                       y: (1 - rect.bottomRight.y) * imageSize.height),
                CGPoint(x: rect.bottomLeft.x * imageSize.width, 
                       y: (1 - rect.bottomLeft.y) * imageSize.height)
            ]
            
        } catch {
            print("Error detecting rectangles: \(error)")
            return nil
        }
    }
    
    // MARK: - Image Quality Check
    func isImageQualityGood(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        // Kiểm tra độ phân giải tối thiểu
        let minResolution: CGFloat = 500
        if image.size.width < minResolution || image.size.height < minResolution {
            return false
        }
        
        // Có thể thêm các kiểm tra chất lượng khác như blur detection
        return true
    }
}

// MARK: - Utility Extensions
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
    
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
