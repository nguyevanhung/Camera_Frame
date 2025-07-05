import UIKit

// MARK: - Test Helper Class
class ImageProcessorTestHelper {
    
    static func testDetectCorners() {
        let imageProcessor = ImageProcessor()
        
        // Test với một image path giả định
        let testImagePath = "/path/to/test/image.jpg"
        
        imageProcessor.detectCorners(imagePath: testImagePath) { corners in
            if let corners = corners {
                print("Detected corners:")
                for (index, corner) in corners.enumerated() {
                    print("Corner \(index): x=\(corner.x), y=\(corner.y)")
                }
            } else {
                print("Failed to detect corners")
            }
        }
    }
    
    static func testCropImage() {
        let imageProcessor = ImageProcessor()
        
        // Test corners
        let testCorners = [
            CGPoint(x: 50, y: 50),
            CGPoint(x: 200, y: 50),
            CGPoint(x: 200, y: 300),
            CGPoint(x: 50, y: 300)
        ]
        
        let testImagePath = "/path/to/test/image.jpg"
        
        imageProcessor.cropImage(imagePath: testImagePath, corners: testCorners) { imageData in
            if let data = imageData {
                print("Successfully cropped image, data size: \(data.count) bytes")
            } else {
                print("Failed to crop image")
            }
        }
    }
}

// MARK: - Debug Extensions
extension ImageProcessor {
    
    func debugPrintCorners(_ corners: [CGPoint], title: String = "Corners") {
        print("\n=== \(title) ===")
        for (index, corner) in corners.enumerated() {
            print("Point \(index): (\(corner.x), \(corner.y))")
        }
        print("==================\n")
    }
    
    func debugImageInfo(_ image: UIImage) {
        print("\n=== Image Info ===")
        print("Size: \(image.size)")
        print("Scale: \(image.scale)")
        print("Orientation: \(image.imageOrientation.rawValue)")
        print("==================\n")
    }
}
