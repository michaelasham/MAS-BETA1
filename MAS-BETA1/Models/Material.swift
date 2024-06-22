//
//  Material.swift
//  MAS-BETA
//
//  Created by Michael Asham on 18/06/2024.
//

import Foundation


struct Material {
    public private(set) var id: String!
    public private(set) var name: String!
    public private(set) var desc: String!
    public private(set) var type: String!
    public private(set) var available: Bool!
    public private(set) var likes: [String]!
    public private(set) var dislikes: [String]!
}
