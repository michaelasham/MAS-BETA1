//
//  CategoryVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit

class CategoryVC: UIViewController, UITableViewDelegate, UITableViewDataSource {


    @IBOutlet weak var tableView: UITableView!
    
    
    var materials = MaterialService.instance.filteredMaterials
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(updateMaterials), name: NOTIF_MATERIAL_UPDATE, object: nil)

    }
    @objc func updateMaterials() {
        MaterialService.instance.filterMaterials()
        materials = MaterialService.instance.filteredMaterials
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return materials.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MaterialCell") as? MaterialCell {
            cell.setupCell(material: materials[indexPath.row])
            return cell
        }
        return MaterialCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MaterialService.instance.selectedMaterial = materials[indexPath.row]
        performSegue(withIdentifier: "toMaterialVC", sender: self)
    }
}
