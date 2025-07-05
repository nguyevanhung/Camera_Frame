import UIKit
import CoreImage
import Vision

class ImageProcessor {
    
    // MARK: - Detect Corners
    func detectCorners(imagePath: String, completion: @escaping ([CGPoint]?) -> Void) {
        guard let image = UIImage(contentsOfFile: imagePath) else {
            completion(nil)
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectRectanglesRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNRectangleObservation],
                  let firstRect = results.first else {
                // Nếu không detect được, trả về 4 góc mặc định
                let defaultCorners = self.getDefaultCorners(for: image.size)
                completion(defaultCorners)
                return
            }
            
            // Chuyển đổi từ normalized coordinates sang pixel coordinates
            let imageSize = image.size
            let corners = [
                CGPoint(x: firstRect.topLeft.x * imageSize.width, 
                       y: (1 - firstRect.topLeft.y) * imageSize.height),
                CGPoint(x: firstRect.topRight.x * imageSize.width, 
                       y: (1 - firstRect.topRight.y) * imageSize.height),
                CGPoint(x: firstRect.bottomRight.x * imageSize.width, 
                       y: (1 - firstRect.bottomRight.y) * imageSize.height),
                CGPoint(x: firstRect.bottomLeft.x * imageSize.width, 
                       y: (1 - firstRect.bottomLeft.y) * imageSize.height)
            ]
            
            completion(corners)
        }
        
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.2
        request.maximumObservations = 1
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(nil)
            }
        }
    }
    
    private func getDefaultCorners(for imageSize: CGSize) -> [CGPoint] {
        let margin = min(imageSize.width, imageSize.height) * 0.1
        return [
            CGPoint(x: margin, y: margin),
            CGPoint(x: imageSize.width - margin, y: margin),
            CGPoint(x: imageSize.width - margin, y: imageSize.height - margin),
            CGPoint(x: margin, y: imageSize.height - margin)
        ]
    }
    
    // MARK: - Crop Image
    func cropImage(imagePath: String, corners: [CGPoint], completion: @escaping (Data?) -> Void) {
        guard let image = UIImage(contentsOfFile: imagePath) else {
            completion(nil)
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let croppedImage = self.perspectiveCorrection(image: cgImage, corners: corners)
            
            DispatchQueue.main.async {
                if let croppedImage = croppedImage,
                   let croppedUIImage = UIImage(cgImage: croppedImage),
                   let imageData = croppedUIImage.jpegData(compressionQuality: 0.8) {
                    completion(imageData)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func perspectiveCorrection(image: CGImage, corners: [CGPoint]) -> CGImage? {
        guard corners.count == 4 else { return nil }
        
        // Sử dụng advanced perspective correction
        return advancedPerspectiveCorrection(image: image, corners: corners)
    }
    
    private func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func advancedPerspectiveCorrection(image: CGImage, corners: [CGPoint]) -> CGImage? {
        // Sort corners to ensure correct order: topLeft, topRight, bottomRight, bottomLeft
        let sortedCorners = sortCorners(corners)
        
        // Calculate output dimensions
        let topWidth = distance(sortedCorners[0], sortedCorners[1])
        let bottomWidth = distance(sortedCorners[3], sortedCorners[2])
        let leftHeight = distance(sortedCorners[0], sortedCorners[3])
        let rightHeight = distance(sortedCorners[1], sortedCorners[2])
        
        let outputWidth = max(topWidth, bottomWidth)
        let outputHeight = max(leftHeight, rightHeight)
        
        // Create output context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(outputWidth),
            height: Int(outputHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        // Define destination rectangle (perfect rectangle)
        let destPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: outputWidth, y: 0),
            CGPoint(x: outputWidth, y: outputHeight),
            CGPoint(x: 0, y: outputHeight)
        ]
        
        // Calculate perspective transform matrix
        guard let transform = calculatePerspectiveTransform(
            from: sortedCorners,
            to: destPoints
        ) else {
            return nil
        }
        
        // Apply transform
        context.concatenate(transform)
        context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        
        return context.makeImage()
    }
    
    private func sortCorners(_ corners: [CGPoint]) -> [CGPoint] {
        // Sort points to get consistent order: topLeft, topRight, bottomRight, bottomLeft
        let center = corners.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let centerPoint = CGPoint(x: center.x / CGFloat(corners.count), y: center.y / CGFloat(corners.count))
        
        var topLeft: CGPoint?
        var topRight: CGPoint?
        var bottomLeft: CGPoint?
        var bottomRight: CGPoint?
        
        for point in corners {
            if point.x < centerPoint.x && point.y < centerPoint.y {
                topLeft = point
            } else if point.x > centerPoint.x && point.y < centerPoint.y {
                topRight = point
            } else if point.x < centerPoint.x && point.y > centerPoint.y {
                bottomLeft = point
            } else {
                bottomRight = point
            }
        }
        
        return [
            topLeft ?? corners[0],
            topRight ?? corners[1],
            bottomRight ?? corners[2],
            bottomLeft ?? corners[3]
        ]
    }
    
    private func calculatePerspectiveTransform(from sourcePoints: [CGPoint], to destPoints: [CGPoint]) -> CGAffineTransform? {
        guard sourcePoints.count == 4 && destPoints.count == 4 else {
            return nil
        }
        
        // For simplicity, use a basic affine transform
        // In a real implementation, you'd want to calculate a proper perspective transform matrix
        
        let sx = destPoints[1].x / max(sourcePoints[1].x - sourcePoints[0].x, 1)
        let sy = destPoints[3].y / max(sourcePoints[3].y - sourcePoints[0].y, 1)
        
        let transform = CGAffineTransform(scaleX: sx, y: sy)
            .translatedBy(x: -sourcePoints[0].x, y: -sourcePoints[0].y)
        
        return transform
    }
}

// MARK: - Extensions
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
