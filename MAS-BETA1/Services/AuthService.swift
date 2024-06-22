//
//  AuthService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation
import Firebase
import FirebaseAuth

class AuthService {
    
    static let instance = AuthService()
    let defaults = UserDefaults.standard
    let ref = Database.database().reference()

    var claimedPhoneNumber: String?
    var pulledName = ""
    var pulledAddress = ""
    
    var appVersion: Float = 0.0
    var minVersion: Float = 0.0
    var latestVersion: Float = 0.0
    
    var isLoggedIn: Bool {
        get{
            return defaults.bool(forKey: LOGGED_IN_KEY)
        }
        set {
            defaults.set(newValue, forKey: LOGGED_IN_KEY)
        }
    }
    
    var phoneNumber: String {
        get{
            return defaults.value(forKeyPath: EMAIL_KEY) as! String
        }
        set{
            defaults.set(newValue, forKey: EMAIL_KEY)
        }
    }
    var userID: String {
        get{
            return defaults.value(forKeyPath: ID_KEY) as? String ?? ""
        }
        set{
            defaults.set(newValue, forKey: ID_KEY)
        }
    }
    var authVerificationID: String {
        get{
            return defaults.string(forKey: VERCODE)!
        }
        set{
            defaults.set(newValue, forKey: VERCODE)
        }
    }
    
    func verifyPhoneNumber(phoneNumber: String, completion: @escaping CompletionHandler) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
              if let error = error {
              print(error.localizedDescription)
              return
              } else {
                self.authVerificationID = verificationID!
                self.claimedPhoneNumber = phoneNumber
                completion(true)
            }
        }
    }
    
    func submitVerificationCode(verificationCode: String, completion: @escaping CompletionHandler) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: authVerificationID, verificationCode: verificationCode)
        print("submitting")
        Auth.auth().signIn(with: credential) { (authResult, error) in
            print("authResult: \(authResult)")
            print("submitted")
            if let error = error {
                print("error: \(error.localizedDescription)")
                completion(false)
                return
            } else {
                print("noerror")
                self.phoneNumber = self.claimedPhoneNumber!
                self.isLoggedIn = true
                let dateFormatter : DateFormatter = DateFormatter()
                //  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
                let date = Date()
                let dateString = dateFormatter.string(from: date)
                // find user
                print(self.phoneNumber)
                self.queryID { Success in
                    if Success {
                        print("founduser")
                        //pull user data
                        UserDataService.instance.pullUserData { (success) in
                            if success {
                                completion(true)
                            }
                        }
                    } else {
                        //create user
                        print("didnt find user")
                        self.createUser { Success in
                            print("created user: \(self.userID)")
                            completion(true)
                        }
                    }

                }
            }
        }
    }
    
    
    func validateAppVersion(completion: @escaping CompletionHandler) {
        ref.child("version").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? NSDictionary else { return }
            guard let minVersion = value.value(forKey: "minVersion") as? Double else { return }
            guard let latestVersion = value.value(forKey: "latestVersion") as? Double else { return }
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            print("appVersionFloat:")
            print(Float(appVersion) ?? 0)
            let appVersionFloat = Float(appVersion) ?? 0
            let minVersionFloat = Float(minVersion.description) ?? 0.0
            let latestVersionFloat = Float(latestVersion.description)
            self.appVersion = appVersionFloat
            self.minVersion = minVersionFloat ?? 0.0
            self.latestVersion = latestVersionFloat ?? 0.0
            print("minVersion: \(minVersionFloat)")

            if appVersionFloat == latestVersionFloat {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    func queryID(completion: @escaping CompletionHandler) {
        ref.child("users").getData { error, snapshot in
            var found = false
            guard let value = snapshot?.value as? NSDictionary else {
                completion(false)
                return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary
                let phone = subvalue?.value(forKey: "mobile") as! String
                if phone == self.phoneNumber {
                    self.userID = id as! String
                    found = true
                    completion(true)
                    break
                }
            }
            if found == false {
                completion(false)
            }
        }
    }
    func createUser(completion: @escaping CompletionHandler) {
        guard let key = ref.child("users").childByAutoId().key else {
            completion(false)
            return
        }
        let dateFormatter : DateFormatter = DateFormatter()
        //  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        self.userID = key
        ref.child("users").child(key).updateChildValues([
            "mobile": self.phoneNumber,
            "createdAt": dateString,
        ])
        completion(true)
    }
}
