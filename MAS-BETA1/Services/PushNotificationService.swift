//
//  PushNotificationService.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 03/09/2024.
//

import Foundation
import Firebase
import FirebaseMessaging

class PushNotificationService {
    
    static let instance = PushNotificationService()
    let ref = Database.database().reference()
    var FCMs: Dictionary<String, String>?
    
    

    
    
    
    
    func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //Cloud Messaging Server Key
        request.setValue("key=AAAAny7AyXY:APA91bHJQoqnM--RVUeHzXQh3bybdehwiHoHrjVNVaqmoVidKBFLy_JK3kNg4zWd6Dvi7ZhTzfJMda-A54Z24sSdN7DLp9CHij0WJLwV-ke22RJWE7prpwc3NVNhci6IcnRlWPQ0C2Uw", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    func sendPushNotificationViaMAC(to MACs: [String], title: String, body: String) {
        if FCMs == nil {
            pullEndUserFCMs { (success) in
                if success {
                    self.sendPushNotificationViaFCM(MACs: MACs, title: title, message: body)
                }
            }
        } else {
            sendPushNotificationViaFCM(MACs: MACs, title: title, message: body)
        }
    }
    
    func sendPushNotificationViaFCM(MACs: [String], title: String, message: String) {
        for mac in MACs {
            let fcm = FCMs?[mac] ?? ""
            if mac != UIDevice.current.identifierForVendor!.uuidString {
                sendPushNotification(to: fcm, title: title, body: message)
            }
        }
    }
    func announcetoDashboard(title: String, body: String) {
        ref.child("FCMs").child("dashboard").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: String] else { return }
            for mac in value.values {
                self.sendPushNotification(to: mac , title: title, body: body)
            }
        }
    }
    
    func pullEndUserFCMs(completion: @escaping CompletionHandler) {
        ref.child("FCMs").child("end-user").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: String] else { return }
            self.FCMs = value
            completion(true)
        }
    }
}
