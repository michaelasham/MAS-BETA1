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
    var newUsers = [NewUser]()
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
                let score = subvalue.value(forKey: "score") as? Int ?? 0
                
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
                                 score: score,
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
    
    
    func addNewUser(user: User, completion: @escaping CompletionHandler) {
        let dateFormatter : DateFormatter = DateFormatter()
        //  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        ref.child("newUsers").childByAutoId().updateChildValues([
            "name": user.name,
            "mobile": user.phone,
            "dateOfBirth": user.dateOfBirth,
            "gender": user.gender,
            "referrer": UserDataService.instance.user.id,
            "timestamp": dateString,
            "group": CommunityService.instance.selectedGroup.id
        ])  { error, ref in
            completion(true)
        }
    }
    func pullNewUsers(completion: @escaping CompletionHandler) {
        ref.child("newUsers").getData { error, snapshot in
            self.newUsers.removeAll()
            guard let value = snapshot?.value as? NSDictionary else {
                completion(false)
                print("error pullUserData \(error?.localizedDescription)")
                return
            }
            for id in value.allKeys {
                guard let subvalue = value.value(forKey: id as! String) as? NSDictionary else {
                    completion(false)
                    print("error pullUserData \(error?.localizedDescription)")
                    return
                }
                let name = subvalue.value(forKey: "name") as! String
                let phone = subvalue.value(forKey: "mobile") as! String
                let dateOfBirth = subvalue.value(forKey: "dateOfBirth") as! String
                let gender = subvalue.value(forKey: "gender") as! String
                let referrer = subvalue.value(forKey: "referrer") as! String
                let timestamp = subvalue.value(forKey: "timestamp") as! String
                let group = subvalue.value(forKey: "group") as! String
                let newUser = NewUser(name: name,
                                      dateOfBirth: dateOfBirth,
                                      phone: phone,
                                      gender: gender,
                                      group: group,
                                      referrer: referrer,
                                      timestamp: timestamp)
                self.newUsers.append(newUser)
            }
            completion(true)
        }
    }
    
    func spoofUser(newUser: NewUser) -> User {
        let user = User(id: "",
                        score: 0,
                        name: newUser.name,
                        dateOfBirth: newUser.dateOfBirth,
                        phone: newUser.phone,
                         dash: 10000,
                        gender: newUser.gender,
                         comments: [Comment](),
                        createdAt: newUser.timestamp)
        return user
    }
    
    func updateUserData(user: User, completion: @escaping CompletionHandler) {
        ref.child("users").child(user.id).updateChildValues([
            "name": user.name,
            "mobile": user.phone,
            "dateOfBirth": user.dateOfBirth,
            "gender": user.gender,
            "lastUpdated": user.lastUpdated
        ])  { error, ref in
            completion(true)
        }
    }
}
