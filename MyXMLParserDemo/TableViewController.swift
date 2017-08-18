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
    var dateDate: Date?
    var title    = String()
    var date     = String()
    var imageUrl = String()
    var link     = String()
    var descriptionFeed = String()
}

class TableViewController: UITableViewController {
    
    var feedsCoreData = [FeedCoreData]()
    var feedsCoreDataSort = [FeedCoreData]()
    
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
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequestFirst: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
        
        do {
            feedsCoreData = try context.fetch(fetchRequestFirst)
        } catch {
            print(error.localizedDescription)
        }
        
        
//        let dgroup: DispatchGroup = DispatchGroup()
//        
//        dgroup.enter()
        guard let url = self.url else {return}
        guard let parser = XMLParser(contentsOf: url) else {return}
        parser.delegate = self
        
        let result = parser.parse()
        
        if result{
            print("Success")
        } else {
            print("Failure")
        }
      //  dgroup.leave()
        
                   let fetchRequestSecond: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
            
            do {
                self.feedsCoreData = try context.fetch(fetchRequestSecond)
            } catch {
                print(error.localizedDescription)
            }
        }
      
    func saveAllFeeds() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        
        let backgroudContext =  NSManagedObjectContext(concurrencyType:
            .privateQueueConcurrencyType)
        
        backgroudContext.parent = context
        
        
        if feedsCoreData.contains(where: { $0.title  == feedTitle && $0.date == feedPubDate})
        {
            return
        }
        
       backgroudContext.perform {
                   let taskObject = FeedCoreData(context: backgroudContext)
            
            taskObject.title = self.feedTitle
            taskObject.date = self.feedPubDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss +zzzz"
            taskObject.dateDate = dateFormatter.date(from: self.feedPubDate) as NSDate?
            
            taskObject.descriptionFeed = self.feedDescription
            taskObject.imageUrl = self.feedImageUrl
            
            
            guard let urlString = taskObject.imageUrl else{return}
            if let imageUrl = URL(string: urlString){
            let data = try? Data(contentsOf: imageUrl)
                taskObject.imageNSData = data as NSData?
            }
            else{ return }
        
            
            do {
                if backgroudContext.hasChanges{print("Yes")}
                
                try backgroudContext.save()
                context.performAndWait {
                    do {
                        if context.hasChanges{print("Yes yes")}
                        try  context.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
            }
            catch {
                fatalError("Failure to save context: \(error)")
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
        if feeds.count == 0 {
            return  feedsCoreData.count
        }
        else{
            return feeds.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
    
        
        let fetchRequestSecond: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
        
                do {
                    self.feedsCoreData = try context.fetch(fetchRequestSecond)
                } catch {
                    print(error.localizedDescription)
                }
        
        let feed = feedsCoreData[indexPath.row]
        
        cell.titleLabel.text = feed.title
        cell.pubDateLabel.text = feed.date
        
          let queue = DispatchQueue.global(qos: .utility)
            queue.async{
            let imageFeed = UIImage(data: feed.imageNSData! as Data)
            
            if let image = self.cache.object(forKey: indexPath.row as AnyObject) as? UIImage {
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
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detail"{
            if let indexPath = tableView.indexPathForSelectedRow{
                let dvc = segue.destination as! ViewController
                
                
                dvc.detailFeed.caseBool = false
                dvc.title = feedsCoreData[indexPath.row].title
                dvc.detailFeed.date = self.feedsCoreData[indexPath.row].date
                dvc.detailFeed.title = self.feedsCoreData[indexPath.row].title
                dvc.detailFeed.descriptionFeed = self.feedsCoreData[indexPath.row].descriptionFeed
                dvc.detailFeed.imageNSData = self.feedsCoreData[indexPath.row].imageNSData
            
            
            
            }
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
            
            
            
            
            
            saveAllFeeds()
            insideItem = false
        }
    }
}






















