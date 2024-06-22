//
//  UserDataService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
    
class UserDataService {

    static let instance = UserDataService()
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var user = User()
//    struct User {
//        public private(set) var id: String!
//        public private(set) var name: String!
//        public private(set) var dateOfBirth: String!
//        public private(set) var phone: String!
//        public private(set) var dash: Int!
//        public private(set) var gender: String!
//
//        public private(set) var comments: [Comment]?
//
//        public private(set) var createdAt: String!
//        public private(set) var lastUpdated: String!
//    }
    func pullUserData(completion: @escaping CompletionHandler) {
        print("isLoggedIn: \(AuthService.instance.isLoggedIn), UserID: \(AuthService.instance.userID)")
        if AuthService.instance.isLoggedIn && AuthService.instance.userID != "" {
            ref.child("users").child(AuthService.instance.userID).getData { error, snapshot in
                guard let value = snapshot?.value as? NSDictionary else {
                    completion(false)
                    print("error pullUserData \(error?.localizedDescription)")
                    return
                }
                var comments = [Comment]()
                let subvalue = value
                let name = subvalue.value(forKey: "name") as? String ?? ""
                let phone = subvalue.value(forKey: "mobile") as? String ?? ""
                let email = subvalue.value(forKey: "email") as? String ?? ""
                let createdAt = subvalue.value(forKey: "createdAt") as? String ?? ""
                let gender = subvalue.value(forKey: "gender") as? String ?? ""
                let dateOfBirth = subvalue.value(forKey: "dateOfBirth") as? String ?? ""
                let dash = subvalue.value(forKey: "dash") as? Int ?? 0
                
                let commentsDict = subvalue.value(forKey: "comments") as? NSDictionary ?? NSDictionary()
                for commentID in commentsDict.allKeys {
                    guard let subsubvalue = commentsDict.value(forKey: commentID as! String) as? NSDictionary else { return }
                    let newComment = Comment(id: commentID as! String,
                                             sender: subsubvalue.value(forKey: "sender") as! String,
                                             message: subsubvalue.value(forKey: "message") as! String,
                                             timestamp: subsubvalue.value(forKey: "timestamp") as! String)
                    comments.append(newComment)
                }
                self.user = User(id: AuthService.instance.userID,
                                 name: name,
                                 dateOfBirth: dateOfBirth,
                                 phone: phone,
                                 dash: dash,
                                 gender: gender,
                                 comments: comments,
                                 createdAt: createdAt)
                completion(true)
            }
        } else {
            completion(false)
        }
    }
    
    func updateMacAndTime() {
        let dateFormatter : DateFormatter = DateFormatter()
        //  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        ref.child("users").child(user.id).updateChildValues(["lastLogin": dateString, "MAC": UIDevice.current.identifierForVendor!.uuidString])
    }
    
    func addUserName(name: String, completion: @escaping CompletionHandler) {
        if AuthService.instance.isLoggedIn {
            ref.child("users").child(AuthService.instance.userID).updateChildValues(["name": name])
            pullUserData { Success in
                completion(true)
            }
        } else {
            completion(false)
        }
    }
}
