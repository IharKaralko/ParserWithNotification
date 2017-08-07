//
//  TableViewController.swift
//  MyXMLParserDemo
//
//  Created by Ihar Karalko on 7/4/17.
//  Copyright © 2017 Ihar Karalko. All rights reserved.
//

import UIKit
import CoreData


class Feed {
    
    var title    = String()
    var date     = String()
    var imageUrl = String()
    var link     = String()
    var descriptionFeed = String()
}

class TableViewController: UITableViewController {
    
    var feedsCoreData = [FeedCoreData]()
    
    var url = URL(string: "https://news.tut.by/rss/sport.rss")
    var feeds = [Feed]()
    var eName = String()
    var feedTitle = String()
    var feedPubDate = String()
    var feedImageUrl = String()
    var feedLink = String()
    var feedDescription = String()
    
    var cache = NSCache<AnyObject, AnyObject>()
    
    var insideItem = false
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SPORT NEWS"
        guard let url = url else {return}
        guard let parser = XMLParser(contentsOf: url) else {return}
        parser.delegate = self
        
        let result = parser.parse()
        if result{
            print("Success")
        } else {
            print("Failure")
        }
        
        self.saveAllFeedsCoreData()
    }
    
    func saveAllFeedsCoreData() {
        var i = 0
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
        
        do {
            feedsCoreData = try context.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
        
//                                for weed in feedsCoreData{
//                                    context.delete(weed)
//                                    do {
//                                        try context.save()
//                                        //foods.append(taskObject)
//                                        print("delete! Good Igor!")
//        
//                                    } catch {
//                                        print(error.localizedDescription)
//                                    }
//                                }
//        
        
//        guard feeds.count != 0 else{
//            print("Offline!")
//            return
//        }
        
        //feeds = [Feed]()
        
        for feed in feeds {
            
            let entity = NSEntityDescription.entity(forEntityName: "FeedCoreData", in: context)
            let taskObject = NSManagedObject(entity: entity!, insertInto: context) as! FeedCoreData
            
            
            if feedsCoreData.contains(where: { $0.title  == feed.title }) {
                //print("yes")
                continue
            }
            taskObject.title = feed.title
            taskObject.date = feed.date
            taskObject.descriptionFeed = feed.descriptionFeed
            i = i + 1
            
            let urlString = feed.imageUrl
            if let imageUrl = URL(string: urlString){
                if let data = try? Data(contentsOf: imageUrl){
                    
                   // let ddd = data as Data?
                    taskObject.imageUrl = data as NSData?
                }
            }
            
            
            do {
                try context.save()
                
                self.feedsCoreData.append(taskObject)
                //self.feedsCoreData.insert(taskObject, at: i)
                print("Saved! Good Job!")
                
            } catch {
                print(error.localizedDescription)
            }
            
            
        }
        
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return  feedsCoreData.count
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        
        let feed = feedsCoreData[indexPath.row]
        
        cell.titleLabel.text = feed.title
        cell.pubDateLabel.text = feed.date
        
        let imageFeed = UIImage(data: feed.imageUrl! as Data)
        
        if let image = cache.object(forKey: indexPath.row as AnyObject) as? UIImage {
            // если объект есть, то подставляем в изображение
            cell.thumbnailImageView?.image = image
            
            cell.thumbnailImageView.layer.cornerRadius = 52.5
            cell.thumbnailImageView.clipsToBounds = true
        } else {
            
            DispatchQueue.main.async(execute: {
                 //проверка видна ли строка
                let updateCell = tableView.cellForRow(at: indexPath) as? CustomTableViewCell
                
                updateCell?.thumbnailImageView.image = imageFeed
                
                updateCell?.thumbnailImageView.layer.cornerRadius = 52.5
                updateCell?.thumbnailImageView.clipsToBounds = true
                
                // кешируем изображение
                self.cache.setObject(imageFeed!, forKey: indexPath.row as AnyObject)
                
            })
        }
        
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detail"{
            if let indexPath = tableView.indexPathForSelectedRow{
                
                let dvc = segue.destination as! ViewController
                dvc.title = feedsCoreData[indexPath.row].title
                dvc.detailFeed.date = self.feedsCoreData[indexPath.row].date
                dvc.detailFeed.title = self.feedsCoreData[indexPath.row].title
                dvc.detailFeed.descriptionFeed = self.feedsCoreData[indexPath.row].descriptionFeed
                 dvc.detailFeed.imageNSData = self.feedsCoreData[indexPath.row].imageUrl            }
        }
    }
}

// MARK: - XMLParser delegate
extension TableViewController: XMLParserDelegate{
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        
        if elementName == "item"{
            
            insideItem = true
            feedTitle = String()
            feedPubDate = String()
            feedImageUrl = String()
            feedLink = String()
            feedDescription = String()
            
        }
        if insideItem {
            if elementName == "media:content"{
                if let imageUrl = attributeDict["url"]{
                    feedImageUrl = imageUrl
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if !data.isEmpty{
            
            if eName == "title"{
                feedTitle += data
            } else if eName == "pubDate"{
                feedPubDate += data
            }
            else if eName == "link"{
                feedLink += data
            }
            else if eName == "description"{
                feedDescription += data
            }
            
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "item"{
            let feed = Feed()
            feed.date = feedPubDate
            feed.title = feedTitle
            feed.imageUrl = feedImageUrl
            feed.link = feedLink
            feed.descriptionFeed = feedDescription
            
            feeds.append(feed)
            insideItem = false
        }
    }
}






















