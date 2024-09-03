//
//  CategoriesVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit

class CategoriesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MaterialService.instance.types.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") as? CategoryCell {
            let type = MaterialService.instance.types[indexPath.row]
            cell.setupCell(title: type, count: MaterialService.instance.countFilteredMaterials(type: type))
            return cell
        }
        return CategoryCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MaterialService.instance.selectedType = MaterialService.instance.types[indexPath.row]
        MaterialService.instance.filterMaterials()
        performSegue(withIdentifier: "toCategoryVC", sender: self)
    }

}
