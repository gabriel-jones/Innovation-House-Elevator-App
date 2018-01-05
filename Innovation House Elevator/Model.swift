//
//  Model.swift
//  Innovation House Elevator
//
//  Created by Gabriel Jones on 1/2/18.
//  Copyright © 2018 Fireminds Ltd. All rights reserved.
//

import Foundation
import SwiftyJSON
import Kanna

class Request {
    static var shared = Request()
    
    func get(_ urlString: String, callback: @escaping (JSON?, Error?) -> ()) {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                callback(nil, error)
                return
            }
            
            if let data = data {
                callback(JSON(data), nil)
                return
            }
            
            callback(nil, nil)
            
        }.resume()
    }
    
    func dataTask(_ urlString: String, callback: @escaping (Data?, Error?) -> ()) {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, response, error in
            callback(data, error)
        }.resume()
    }
}

extension String {
    func removeWhitespace() -> String {
        return self
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

struct Floor {
    var name: String
    var items: [String]
}

struct Story {
    var id: Int
    var title: String
    var author: String
    var views: Int
    var date: String
    var body: NSAttributedString
    var image: UIImage?
}

struct WeatherInfo {
    var image: UIImage
    var description: String
}

extension String{
    func convertHTML() -> NSAttributedString? {
        do {
            let attrStr = try NSAttributedString(data: self.data(using: .utf8)!, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            return attrStr
        }
        catch {
            print("error creating attributed string")
        }
        return nil
    }
}

class Model {
    static var shared = Model()
    
    func getStory(id: Int, callback: @escaping (Story?, Bool) -> ()) {
        Request.shared.dataTask("https://www.fireminds.com/news/item/\(id)") { data, error in
            guard let data = data, error == nil else {
                callback(nil, true)
                return
            }
            
            do {
                let html = try HTML(html: data, encoding: .utf8)
                let date = html.at_xpath("//span[@class='itemDateCreated']")!.content!.removeWhitespace()
                let author = html.at_xpath("//span[@class='author-name']")!.content!.removeWhitespace()
                let views = html.at_xpath("//span[@class='itemHits']")!.content!.trimmingCharacters(in: .whitespacesAndNewlines)
                let title = html.title!.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces)
                let body = html.at_xpath("//div[@class='itemFullText']")!.innerHTML!.convertHTML()!
                let imageSRC = "https://www.fireminds.com" + html.at_xpath("//div[@class='itemBody']//img/@src")!.content!
                let image = UIImage(data: try! Data(contentsOf: URL(string: imageSRC)!))
                
                callback(Story(id: id, title: title, author: author, views: Int(views)!, date: date, body: body, image: image), false)
                return
            } catch {
                print("Could not parse HTML.")
            }
            
            callback(nil, true)
        }
    }
    
    func getMostRecentNews(_ callback: @escaping (Story?, Bool) -> ()) {
        Request.shared.dataTask("https://www.fireminds.com/news") { data, error in
            guard let data = data, error == nil else {
                callback(nil, true)
                return
            }
            
            do {
                let html = try HTML(html: data, encoding: .utf8)
                if let storyNode = html.at_xpath("//div[@id='itemListPrimary']/div//a[1]/@href") {
                    if let id = storyNode.content?.components(separatedBy: "/")[3].components(separatedBy: "-")[0] {
                        self.getStory(id: Int(id)!, callback: callback)
                        return
                    }
                }
            } catch {
                print("Could not parse HTML.")
            }
            
            callback(nil, true)
        }
    }
    /*
    private let weatherKey = "321b025d9fdd2c1f9b91d2280f012c27"
    func getWeather(_ callback: @escaping (WeatherInfo) -> ()) {
        Request.shared.get("http://api.openweathermap.org/data/2.5/weather?id=3573345&APPID=\(weatherKey)") { json, error in
            guard let json = json, error == nil else {
                print(error?.localizedDescription as Any)
                return
            }
            
            guard json["cod"].intValue < 400 else {
                print("error!")
                return
            }
            
            
            let wID = json["weather"][0]["id"].intValue
            let isNight = json["weaather"][0]["icon"].stringValue.hasSuffix("n")
            
            var image: UIImage!
            switch wID {
            case 200...232:
                image = #imageLiteral(resourceName: "storm")
            case 300...321:
                image = #imageLiteral(resourceName: "rain")
            case 500...531:
                image = #imageLiteral(resourceName: "rain")
            case 801:
                image = isNight ? #imageLiteral(resourceName: "overcast-night") : #imageLiteral(resourceName: "overcast")
            case 802...804:
                image = #imageLiteral(resourceName: "cloudy")
            case 900...906:
                image = #imageLiteral(resourceName: "extreme")
            case 951...962:
                image = #imageLiteral(resourceName: "wind")
            default:
                image = isNight ? #imageLiteral(resourceName: "clear-night") : #imageLiteral(resourceName: "clear")
            }
            
            let main = json["weather"][0]["main"].stringValue
            let w = WeatherInfo(image: image, description: main)
            callback(w)
        }
    }*/
}
