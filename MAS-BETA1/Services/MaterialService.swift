//
//  MaterialService.swift
//  MAS-BETA
//
//  Created by Michael Asham on 18/06/2024.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class MaterialService {
    
    static let instance = MaterialService()
    let ref = Database.database().reference()
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var materials = [Material]()
    var selectedMaterial = Material()
    let types = ["نيران", "صيحات", "بروتوكول", "شفرات", "صلوات", "خيام" ,"ربطات"]
    var selectedType = ""
    var filteredMaterials = [Material]()

    
    func pullMaterials(completion: @escaping CompletionHandler) {
        self.materials.removeAll()
        ref.child("materials").getData { error, snapshot in
            guard let value = snapshot?.value as? NSDictionary else { return }
            for id in value.allKeys {
                let subvalue = value.value(forKey: id as! String) as? NSDictionary
                var likes = [String]()
                var dislikes = [String]()
                if let likesDict = subvalue!.value(forKey: "likes") as? NSDictionary {
                    for key in likesDict.allKeys {
                        if likesDict.value(forKey: key as! String) as! String == "like" {
                            likes.append(key as! String)
                        } else {
                            //dislike
                            dislikes.append(key as! String)
                        }
                    }
                }
                guard let material = Material(id: id as! String, name: subvalue!.value(forKey: "name") as? String, desc: subvalue!.value(forKey: "desc") as? String, type: subvalue!.value(forKey: "type") as? String, available: subvalue!.value(forKey: "available") as? Bool, likes: likes, dislikes: dislikes) as? Material else { return }
                if (subvalue!.value(forKey: "available") as? Bool)! {
                    self.materials.append(material)
                }
            }
            self.materials.sort { $0.type > $1.type }
            NotificationCenter.default.post(name: NOTIF_MATERIAL_UPDATE, object: nil)
            completion(true)
        }
    }
    
    func queryMaterial(id: String) -> Material {
        for material in materials {
            if material.id == id {
                return material
            }
        }
        return Material()
    }
    
    func filterMaterials() {
        filteredMaterials = materials.filter { $0.type == selectedType }
    }
    
    func countFilteredMaterials(type: String) -> Int {
        filteredMaterials = materials.filter { $0.type == type }
        return filteredMaterials.count
    }
    
    func likeActivity(like: String) {
        if like == "" {
            ref.child("materials").child(selectedMaterial.id!).child("likes").child(UserDataService.instance.user.id!).removeValue()
        } else {
            print("likeActivity \(like)")
            print("user \(UserDataService.instance.user.id)")
            ref.child("materials").child(selectedMaterial.id!).child("likes").updateChildValues([
                UserDataService.instance.user.id! : like
            ]) { error, ref in
                if let error = error {
                    print(error)
                }
            }
        }
    }
}
