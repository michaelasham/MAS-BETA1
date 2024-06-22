//
//  AdminService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//


import Foundation
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

class AdminService {
    
    static let instance = AdminService()
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var websiteAdTitle = ""
    var websiteAdLink = ""
    
    
    func pullWebsiteAdDetails(completion: @escaping CompletionHandler) {
        ref.child("settings").getData { error, snapshot in
            guard let value = snapshot?.value as? NSDictionary else {
                completion(false)
                return }
            if let title = value.value(forKey: "websiteAdTitle") as? String {
                self.websiteAdTitle = title
            }
            if let link = value.value(forKey: "websiteAdLink") as? String {
                self.websiteAdLink = link
            }
            completion(true)
        }
    }
    func deleteImageData(id: String, ext: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(ext)")

        // Remove the image file from the documents directory
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Image file deleted successfully.")
        } catch {
            print("Error deleting image file: \(error)")
        }

        // Remove the saved date from UserDefaults
        UserDefaults.standard.removeObject(forKey: id)
        print("Saved date removed from UserDefaults.")
    }
    
    func updateImage(filename: String, ext: String, folderName: String, image: UIImage, completion: @escaping CompletionHandler) {
        let formatter : DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy hh:mm:ss"
        let dateStr : String = formatter.string(from: NSDate.init(timeIntervalSinceNow: 0) as Date)
                
        let imageRef = storageRef.child("\(folderName)/\(filename).\(ext)")
        imageRef.delete { error in
            let jpegmetadata = StorageMetadata()
            jpegmetadata.contentType = "image/\(ext)"
            if ext == "png" {
                imageRef.putData(image.pngData()!, metadata: jpegmetadata)

            } else {
                imageRef.putData(image.jpegData(compressionQuality: 0.25)!, metadata: jpegmetadata)

            }
            self.ref.child(folderName).child(filename).updateChildValues(["lastUpdated": dateStr])
            completion(true)
        }
    }

    func saveImage(id: String, image: Data, ext: String) {
//        deleteImageData(id: id, ext: ext)
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(ext)")

        // Get the current date and time
        let currentDate = Date()

        // Save the image data to the file
        do {
            try image.write(to: fileURL)

            // Save the date and time when the image was saved
            UserDefaults.standard.set(currentDate, forKey: id)
            print("Image saved successfully at: \(fileURL.absoluteString)")
        } catch {
            print("Error saving image: \(error)")
        }
    }
    
    func checkImageValidity(id: String, lastUpdated: String, ext: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(ext)")

        // Load the date and time when the image was saved
        if let savedDate = UserDefaults.standard.value(forKey: "\(id)") as? Date {
            print("Image was saved on: \(savedDate)")

            // Convert the lastUpdated string to a Date object
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss" // Adjust the format as needed
            if let lastUpdatedDate = dateFormatter.date(from: lastUpdated) {
                // Compare the dates
                if savedDate < lastUpdatedDate {
                    print("The image was updated after it was saved.")
                    return false
                } else if savedDate > lastUpdatedDate {
                    print("The image was saved after it was last updated.")
                    return true
                } else {
                    print("The image was saved and last updated at the same time.")
                    return false
                }
            } else {
                print("Error converting lastUpdated to Date.")
            }
        } else {
            print("No saved date found.")
        }
        return false
    }

    func findImage(id: String, ext: String) -> UIImage {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(ext)")

        // Load the date and time when the image was saved
        if let savedDate = UserDefaults.standard.value(forKey: "\(id)") as? Date {
            print("Image was saved on: \(savedDate)")
        }

        if let savedImage = UIImage(contentsOfFile: fileURL.path) {
            // Use the savedImage
            return savedImage
        } else {
            print("Error loading image from file")
            return UIImage()
        }
    }
    func findVideo(id: String, ext: String) -> AVPlayerItem? {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("\(id).\(ext)")

        // Load the date and time when the video was saved (optional)
        if let savedDate = UserDefaults.standard.value(forKey: "\(id)") as? Date {
            print("Video was saved on: \(savedDate)")
        }

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Video file does not exist at path: \(fileURL.path)")
            return nil
        }

        // Create AVPlayerItem from file URL
        let videoURL = URL(fileURLWithPath: fileURL.path)
        let playerItem = AVPlayerItem(url: videoURL)
        
        return playerItem
    }
}
