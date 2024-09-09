//
//  GameVC.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 08/09/2024.
//

import UIKit

class GameVC: UIViewController, UITableViewDataSource, UITableViewDelegate {


    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var pointsField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var actionBtn: BorderButton!
    
    let patrols = CommunityService.instance.patrols
    let meeting = CommunityService.instance.openMeeting
    var scores: [String: Int] = [:]
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupView()
        onSliderSlide()
        setupInitialSliderValues()
        NotificationCenter.default.addObserver(self, selector: #selector(onSliderSlide), name: NOTIF_SLIDER_SLIDE, object: nil)
    }
    
    func setupView() {
        tableView.isHidden = meeting.gameOpenTime == ""
        titleField.isEnabled = meeting.gameOpenTime == ""
        pointsField.isEnabled = meeting.gameOpenTime == ""
        titleField.text = meeting.gameTitle
        pointsField.text = "\(meeting.gamePoints ?? 0)"
        if meeting.gameOpenTime == "" {
            actionBtn.setTitle("Start Game", for: .normal)
        } else {
            actionBtn.setTitle("End Game", for: .normal)
        }
    }
    func setupInitialSliderValues() {
        for i in 0..<patrols.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? GameScoreCell {
                cell.slider.value = 0 // Set initial slider value to 0
                cell.calculatePoints() // Calculate initial points based on the initial slider values
            }
        }
        CommunityService.instance.sliderScores = 0 // Reset the total slider scores
    }
    @objc func onSliderSlide() {
        var score = 0

        for i in 0..<patrols.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? GameScoreCell {
                let sliderValue = cell.slider.value * 100
                score += Int(sliderValue)

                cell.calculatePoints()
            }
        }

        CommunityService.instance.sliderScores = score
    }


    

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patrols.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "GameScoreCell") as? GameScoreCell {
            cell.setupCell(patrol: patrols[indexPath.row])
            return cell
        }
        return GameScoreCell()
    }
    
    @IBAction func onClick(_ sender: Any) {
        if meeting.gameOpenTime == "" {
            CommunityService.instance.startGame(title: titleField.text!, points: Int(pointsField.text!)!) { Success in
                self.dismiss(animated: true)
            }
        } else {
            CommunityService.instance.endGame(winnerID: queryWinner(), pointDistribution: exportScores())
            self.dismiss(animated: true)
        }
    }
    
    func queryWinner() -> String{
        var cells = [GameScoreCell]()
        for i in 0..<patrols.count {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! GameScoreCell
            cells.append(cell)
        }
        cells = cells.sorted {
            $0.slider.value > $1.slider.value
        }
        return cells[0].titleLbl.text!
    }
    
    func exportScores() -> [String:Int] {
        var table: [String: Int] = [:]
        for i in 0..<patrols.count {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! GameScoreCell
            table[cell.titleLbl.text!] = Int(cell.pointsLbl.text!)!
        }
        return table
    }

}
