//
//  CloudinaryUploader.swift
//  PersonalExpensesTracker
//

import Foundation
import UIKit

enum CloudinaryUploader {
    // MARK: - Errors
    
    enum UploadError: LocalizedError {
        case missingConfiguration
        case invalidImageData
        case invalidResponse
        case uploadFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Cloudinary is not configured. Add CloudinaryCloudName and CloudinaryUploadPreset to Info.plist."
            case .invalidImageData:
                return "Unable to prepare the selected image for upload."
            case .invalidResponse:
                return "Cloudinary returned an invalid response."
            case .uploadFailed(let message):
                return message
            }
        }
    }
    
    // MARK: - Configuration
    
    static var isConfigured: Bool {
        cloudName != nil && uploadPreset != nil
    }
    
    // MARK: - Uploading
    
    static func uploadReceiptImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cloudName = cloudName, let uploadPreset = uploadPreset else {
            completion(.failure(UploadError.missingConfiguration))
            return
        }
        
        guard let imageData = resizedImage(image, maxDimension: 1200).jpegData(compressionQuality: 0.72) else {
            completion(.failure(UploadError.invalidImageData))
            return
        }
        
        let urlString = "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"
        guard let url = URL(string: urlString) else {
            completion(.failure(UploadError.invalidResponse))
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(imageData: imageData, uploadPreset: uploadPreset, boundary: boundary)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                completion(.failure(UploadError.invalidResponse))
                return
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Cloudinary upload failed."
                completion(.failure(UploadError.uploadFailed(message)))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let secureURL = json?["secure_url"] as? String, !secureURL.isEmpty {
                    completion(.success(secureURL))
                } else if let url = json?["url"] as? String, !url.isEmpty {
                    completion(.success(url))
                } else {
                    completion(.failure(UploadError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Private Configuration
    
    private static var cloudName: String? {
        configuredValue(for: "CloudinaryCloudName")
    }
    
    private static var uploadPreset: String? {
        configuredValue(for: "CloudinaryUploadPreset")
    }
    
    private static func configuredValue(for key: String) -> String? {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty || trimmedValue.hasPrefix("YOUR_") ? nil : trimmedValue
    }
    
    // MARK: - Request Building
    
    private static func multipartBody(imageData: Data, uploadPreset: String, boundary: String) -> Data {
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n")
        body.appendString("\(uploadPreset)\r\n")
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"receipt.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        return body
    }
    
    // MARK: - Image Processing
    
    private static func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > maxDimension else { return image }
        
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

private extension Data {
    // MARK: - Multipart Helpers
    
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
