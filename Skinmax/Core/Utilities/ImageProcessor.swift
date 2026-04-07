import UIKit
import Vision

enum ImageProcessor {
    static func processForAnalysis(_ image: UIImage) async -> Data? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(returning: compressImage(image))
                    return
                }

                let request = VNDetectFaceRectanglesRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform([request])
                    if let face = request.results?.first {
                        let cropped = cropToFace(image: image, faceBounds: face.boundingBox)
                        let resized = resize(cropped, maxWidth: 800)
                        continuation.resume(returning: compressImage(resized))
                    } else {
                        let resized = resize(image, maxWidth: 800)
                        continuation.resume(returning: compressImage(resized))
                    }
                } catch {
                    let resized = resize(image, maxWidth: 800)
                    continuation.resume(returning: compressImage(resized))
                }
            }
        }
    }

    private static func cropToFace(image: UIImage, faceBounds: CGRect) -> UIImage {
        let imageSize = image.size
        // Vision coordinates are normalized with origin at bottom-left
        let padding: CGFloat = 0.3
        let x = max(0, (faceBounds.origin.x - padding) * imageSize.width)
        let y = max(0, (1 - faceBounds.origin.y - faceBounds.height - padding) * imageSize.height)
        let width = min(imageSize.width - x, (faceBounds.width + padding * 2) * imageSize.width)
        let height = min(imageSize.height - y, (faceBounds.height + padding * 2) * imageSize.height)

        let cropRect = CGRect(x: x, y: y, width: width, height: height)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private static func resize(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        let currentWidth = image.size.width
        guard currentWidth > maxWidth else { return image }

        let scale = maxWidth / currentWidth
        let newSize = CGSize(width: maxWidth, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private static func compressImage(_ image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.6)
    }
}
