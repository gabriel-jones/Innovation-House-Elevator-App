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
    
    @IBOutlet weak var offlineText: UILabel!
    @IBOutlet weak var offlineImage: UIImageView!
    
    @IBOutlet weak var loadingStory: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        calibrateTime()
        updateTime()

        loadNews()
        
        refreshUpdateTimer()
    }
    
    var refreshTimer: Timer?
    var storyRefreshMins: Double = 60
    
    func setupViews() {
        
        let gradient = CAGradientLayer()
        gradient.frame = backgroundImage.frame
        gradient.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.6)
        gradient.endPoint = CGPoint(x: 0, y: 1.0)
        backgroundImage.layer.mask = gradient
        
        bloombergButton.layer.cornerRadius = bloombergButton.frame.height / 2
        bloombergButton.addTarget(self, action: #selector(watchBloomberg(_:)), for: .touchUpInside)
        bloombergButton.layer.shadowColor = bloombergButton.backgroundColor?.cgColor
        bloombergButton.layer.shadowOffset = CGSize(width: 1, height: 3)
        bloombergButton.layer.shadowOpacity = 0.5
        bloombergButton.layer.shadowRadius = 5
        bloombergButton.layer.masksToBounds = false
        
        storyImage.layer.cornerRadius = 10
        storyImage.layer.masksToBounds = true
        
    }
    
    func refreshUpdateTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(timeInterval: 60.0 * storyRefreshMins, target: self, selector: #selector(loadNews), userInfo: nil, repeats: true)
    }
    
    @objc func loadNews() {
        self.storyTitle.text?.removeAll()
        self.storyDate.text?.removeAll()
        self.storyPortion.text?.removeAll()
        self.storyImage.image = nil
        self.offlineImage.isHidden = true
        self.offlineText.isHidden = true
        
        loadingStory.startAnimating()
        Model.shared.getMostRecentNews { story, error in
            DispatchQueue.main.async {
                self.loadingStory.stopAnimating()
                guard let story = story, !error else {
                    self.offlineImage.isHidden = false
                    self.offlineText.isHidden = false
                    self.storyRefreshMins = 1
                    self.refreshUpdateTimer()
                    return
                }
                self.storyRefreshMins = 60
                self.refreshUpdateTimer()
                
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

