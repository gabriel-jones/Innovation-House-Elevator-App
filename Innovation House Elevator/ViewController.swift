//
//  ViewController.swift
//  Innovation House Elevator
//
//  Created by Gabriel Jones on 1/2/18.
//  Copyright © 2018 Fireminds Ltd. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var bloombergButton: LoadingButton!
    @IBOutlet weak var buildingLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var storyImage: UIImageView!
    @IBOutlet weak var storyTitle: UILabel!
    @IBOutlet weak var storyDate: UILabel!
    @IBOutlet weak var storyPortion: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradient = CAGradientLayer()
        gradient.frame = backgroundImage.frame
        gradient.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.6)
        gradient.endPoint = CGPoint(x: 0, y: 1.0)
        backgroundImage.layer.mask = gradient
        
        bloombergButton.layer.cornerRadius = bloombergButton.frame.height / 2
        bloombergButton.addTarget(self, action: #selector(watchBloomberg(_:)), for: .touchUpInside)
        
        calibrateTime()
        updateTime()

        loadNews()
        
        storyImage.layer.cornerRadius = 10
        storyImage.layer.masksToBounds = true
    }
    
    func loadNews() {
        Model.shared.getMostRecentNews { story, error in
            DispatchQueue.main.async {
                guard let story = story, !error else {
                    return
                }
                
                self.storyTitle.text = story.title
                self.storyDate.text = story.date
                self.storyPortion.text = String(story.body.string.prefix(137)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
                self.storyImage.image = story.image
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory warning!")
    }

    
    @objc func watchBloomberg(_ sender: LoadingButton) {
        sender.showLoading()
        let player = AVPlayer(url: URL(string: "https://liveproduseast.global.ssl.fastly.net/btv/desktop/us_live.m3u8")!)
        //https://live-bloomberg-us-east.global.ssl.fastly.net/btv/desktop/live.m3u8
        //https://liveproduseast.global.ssl.fastly.net/btv/desktop/us_live.m3u8
        let vc = AVPlayerViewController()
        vc.player = player
        self.present(vc, animated: true) {
            sender.hideLoading()
        }
        player.play()
    }
    
    func calibrateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        let str = formatter.string(from: Date())
        lastTime = Int(str)!
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkTime), userInfo: nil, repeats: true)
    }
    
    var calibrationTimer: Timer?
    
    func startUpdatingTime() {
        calibrationTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        updateTime()
    }
    
    var lastTime = 0
    
    @objc func checkTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        let str = formatter.string(from: Date())
        
        if Int(str)! != lastTime {
            calibrationTimer?.invalidate()
            startUpdatingTime()
        }
    }
    
    @objc func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        timeLabel.text = formatter.string(from: Date())
    }
    
    let floors = [
        Floor(name: "Penthouse", items: ["RFIB Bermuda Ltd."]),
        Floor(name: "3rd Floor", items: ["Freisenbruch Meyer", "Igility Holdings", "IMG International Ltd.", "Independent Brokers Ltd.", "Wilson Allen - Architecture & Interior Design"]),
        Floor(name: "2nd Floor", items: ["Fireminds Ltd.", "Treefrog Consulting", "Premier Tickets Limited"]),
        Floor(name: "1st Floor", items: []),
        Floor(name: "Ground Floor", items: ["Reid Street"]),
        Floor(name: "Basement", items: ["B.N. Henagulph & Associates Ltd.", "Nathi's Tuina Massage Fusion"])
    ]

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return floors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "floorCell", for: indexPath) as! FloorTableViewCell
        cell.nameLabel.text = floors[indexPath.row].name
        cell.itemsLabel.text = floors[indexPath.row].items.joined(separator: "\n")
        return cell
    }
}

