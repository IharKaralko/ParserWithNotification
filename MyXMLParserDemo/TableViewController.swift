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
        guard let url = url else {return}
        guard let parser = XMLParser(contentsOf: url) else {return}
        parser.delegate = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        
        
        let fetchRequestFirst: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
        
        do {
            feedsCoreData = try context.fetch(fetchRequestFirst)
        } catch {
            print(error.localizedDescription)
        }
        
//        let queue = DispatchQueue.global(qos: .utility)
//        queue.async{
        let result = parser.parse()
        
        
        if result{
            print("Success")
        } else {
            print("Failure")
        }
   // }
    
        let fetchRequestSecond: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
        
        do {
            feedsCoreData = try context.fetch(fetchRequestSecond)
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
            
            
            let urlString = taskObject.imageUrl
            let imageUrl = URL(string: urlString!)
            let data = try? Data(contentsOf: imageUrl!)
            taskObject.imageNSData = data as NSData?
            
            do {
                if backgroudContext.hasChanges{print("Yes")}
                
                try backgroudContext.save()
                context.performAndWait {
                    do {
                        if context.hasChanges{print("No")}
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
        
        
    
        
        //
//            backgroudContext.perform {
//
//                let taskObject = FeedCoreData(context: backgroudContext)
//                
//                taskObject.title = feed.title
//                taskObject.date = feed.date
//                taskObject.descriptionFeed = feed.descriptionFeed
//                taskObject.dateDate = feed.dateDate as NSDate?
//                
//                let urlString = feed.imageUrl
//                let imageUrl = URL(string: urlString)
//                let data = try? Data(contentsOf: imageUrl!)
//                taskObject.imageNSData = data as NSData?
//                do {
//                    try backgroudContext.save()
//                    
//                } catch {
//                    fatalError("Failure to save context: \(error)")
//                }
    
//                // Add Observer
//                let notificationCenter = NotificationCenter.default
//                notificationCenter.addObserver(self, selector: #selector(self.managedObjectContextDidSave),
//                                               name: NSNotification.Name.NSManagedObjectContextDidSave, object: backgroudContext)
                
//                                // Add Observer
//                                let notificationCenter = NotificationCenter.default
//                                notificationCenter.addObserver(self, selector: #selector(self.managedObjectContextDidSave),
//                                                               name: NSNotification.Name.NSManagedObjectContextDidSave, object: backgroudContext)
//            }
//            
//        }
//        
//        
  }
    
    // MARK: - Notification Handling
    
//    func managedObjectContextDidSave(_ notification: Notification) {
//        
    //    guard let userInfo = notification.userInfo else { return }
//        
//        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
//            print("--- Save Contect ---")
//            //  print(inserts)
//            print("+++++++++++++++")
//        }
    
    //    mergeChangesFromContextDidSaveNotification(_:)
//       
//        func managedObjectContextDidSave(notification: Notification) {
//          
//            let appDelegate = UIApplication.shared.delegate as! AppDelegate
//           let context = appDelegate.persistentContainer.viewContext
//           
//            DispatchQueue.main.async(execute: { () -> Void in
//              context.mergeChanges(fromContextDidSave: notification)
//               // print("Yess")
//            })
//        }
    
 
    
    
    
    
    
    
    
    
    
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
        
        
  // feeds = [Feed]()
    //    if feeds.count == 0 {
            
            feedsCoreDataSort = feedsCoreData//.sorted{ ($0.dateDate as Date?)! > ($1.dateDate as Date?)! }
            
            let feed = feedsCoreDataSort[indexPath.row]
            
            cell.titleLabel.text = feed.title
            cell.pubDateLabel.text = feed.date
            
            let queue = DispatchQueue.global(qos: .utility)
            queue.async{
            let imageFeed = UIImage(data: feed.imageNSData! as Data)
            
            if let image = self.cache.object(forKey: indexPath.row as AnyObject) as? UIImage {
                // если объект есть, то подставляем в изображение
               // print("Yes")
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
      //  }
//       // else {
//            let feed = feeds[indexPath.row]
//
//            cell.titleLabel.text = feed.title
//            cell.pubDateLabel.text = feed.date
//            
//            let urlString = feed.imageUrl
//            let imageUrl = URL(string: urlString)
//            
//            URLSession.shared.downloadTask(with: imageUrl!, completionHandler: { (url, response, error) in
//                   
//            let data = try? Data(contentsOf: imageUrl!)
//            
//            
//                DispatchQueue.main.async(execute: {
//                let imageFeed = UIImage(data: data! as Data)
//            
//                    if let image = self.cache.object(forKey: indexPath.row as AnyObject) as? UIImage {
//                       // print("oooo")
//                      
//                        
//                        cell.thumbnailImageView?.image = image
//            
//                        cell.thumbnailImageView.layer.cornerRadius = 52.5
//                        cell.thumbnailImageView.clipsToBounds = true
//                    } else {
//            
//                        let updateCell = tableView.cellForRow(at: indexPath) as? CustomTableViewCell
//                
//                updateCell?.thumbnailImageView.image = imageFeed
//                
//                updateCell?.thumbnailImageView.layer.cornerRadius = 52.5
//                updateCell?.thumbnailImageView.clipsToBounds = true
//                
//                        
//                             self.cache.setObject(imageFeed!, forKey: indexPath.row as AnyObject)
//                    }
//            })
//           // }
//                 }).resume()
//                    
//            return cell
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detail"{
            if let indexPath = tableView.indexPathForSelectedRow{
                let dvc = segue.destination as! ViewController
                
                if feeds.count == 0 {
                    dvc.detailFeed.caseBool = false
                    dvc.title = feedsCoreDataSort[indexPath.row].title
                    dvc.detailFeed.date = self.feedsCoreDataSort[indexPath.row].date
                    dvc.detailFeed.title = self.feedsCoreDataSort[indexPath.row].title
                    dvc.detailFeed.descriptionFeed = self.feedsCoreDataSort[indexPath.row].descriptionFeed
                    dvc.detailFeed.imageNSData = self.feedsCoreDataSort[indexPath.row].imageNSData
                }
                else{
                    dvc.detailFeed.caseBool = true
                    dvc.title = feeds[indexPath.row].title
                    dvc.detailFeed.date = self.feeds[indexPath.row].date
                    dvc.detailFeed.title = self.feeds[indexPath.row].title
                    dvc.detailFeed.descriptionFeed = self.feeds[indexPath.row].descriptionFeed
                    dvc.detailFeed.link = self.feeds[indexPath.row].imageUrl
                }
                
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
         //   let feed = FeedCoreData()
           
            
            saveAllFeeds()
            //            feed.date =  feedPubDate
//            
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss +zzzz"
//            feed.dateDate = dateFormatter.date(from: feedPubDate)
//            feed.title = feedTitle
//            feed.imageUrl = feedImageUrl
//            feed.link = feedLink
//            feed.descriptionFeed = feedDescription
//            
//            feeds.append(feed)
            insideItem = false
        }
    }
}






















