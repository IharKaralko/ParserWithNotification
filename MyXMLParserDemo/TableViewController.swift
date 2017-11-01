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
    var descriptionFeed = String()
}

class TableViewController: UITableViewController {
    
    var feedsCoreData = [FeedCoreData]()
    
    let url = URL(string: "https://news.tut.by/rss/sport.rss")
    var feeds = [Feed]()
    var eName = String()
    var feedTitle = String()
    var feedPubDate = String()
    var feedImageUrl = String()
    var feedLink = String()
    var feedDescription = String()
    
    
    
    var insideItem = false
    
      
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        title = "SPORT NEWS"
        
        let fetchRequestFirst: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
        let sortDateDate = NSSortDescriptor(key: "dateDate", ascending: false)
        fetchRequestFirst.sortDescriptors = [sortDateDate]
        
        do {
            feedsCoreData = try context.fetch(fetchRequestFirst)
        } catch {
            print(error.localizedDescription)
        }
        
        saveInBackground()
        
        // Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.managedObjectContextDidSave),
                                       name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
    }
    
    // MARK: - Notification Handling
    
    func managedObjectContextDidSave(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            //print("--- Save Contect ---")
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequestSecond: NSFetchRequest<FeedCoreData> = FeedCoreData.fetchRequest()
            
            let sortDateDate = NSSortDescriptor(key: "dateDate", ascending: false)
            fetchRequestSecond.sortDescriptors = [sortDateDate]
            do {
                feedsCoreData = try context.fetch(fetchRequestSecond)
            } catch {
                print(error.localizedDescription)
            }
            tableView.reloadData()
        }
        
    }
    func saveInBackground() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let mainContext = appDelegate.persistentContainer.viewContext
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = mainContext
        
        privateMOC.perform {
            
            guard let url = self.url else {return}
            guard let parser = XMLParser(contentsOf: url) else {return}
            parser.delegate = self
            
            let result = parser.parse()
            
            if result{
                print("Success")
            } else {
                print("Failure")
            }
            
            
            self.feeds.forEach({ feed in
                
                if self.feedsCoreData.contains(where: { $0.title  == feed.title }) {
                    //print("yes")
                    return
                }
                else {
                    
                    
                    let corefeed      = FeedCoreData(context: privateMOC)
                    corefeed.title    = feed.title
                    corefeed.date     = feed.date
                    corefeed.dateDate = feed.dateDate as NSDate?
                    corefeed.descriptionFeed    = feed.descriptionFeed
                    corefeed.imageUrl = feed.imageUrl
                    
                    guard let url = URL(string: feed.imageUrl) else { return }
                    guard let imageData = try? Data(contentsOf: url) else { return }
                    
                    corefeed.imageNSData = imageData as NSData
                    
                    do {
                        try privateMOC.save()
                        mainContext.performAndWait {
                            do {
                                try mainContext.save()
                            } catch {
                                fatalError("Failure to save context: \(error)")
                            }
                        }
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
            })
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
             return  feedsCoreData.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        
        let feed = feedsCoreData[indexPath.row]
        
        cell.titleLabel.text = feed.title
        cell.pubDateLabel.text = feed.date
        
        
        let imageFeed = UIImage(data: feed.imageNSData! as Data)
        
        
        // если объект есть, то подставляем в изображение
        cell.thumbnailImageView?.image = imageFeed
        
        cell.thumbnailImageView.layer.cornerRadius = 52.5
        cell.thumbnailImageView.clipsToBounds = true
        
        
        return cell
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detail"{
            if let indexPath = tableView.indexPathForSelectedRow{
                
                
                let dvc = segue.destination as! ViewController
                let feed = feedsCoreData[indexPath.row]
                
                dvc.title = feed.title
                dvc.detailFeed.date = feed.date
                dvc.detailFeed.title = feed.title
                dvc.detailFeed.descriptionFeed = feed.descriptionFeed
                dvc.detailFeed.imageNSData = feed.imageNSData
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
        
        let feed = Feed()
        
        if elementName == "item"{
            
            feed.title = feedTitle
            feed.date =  feedPubDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss +zzzz"
            feed.dateDate = dateFormatter.date(from: self.feedPubDate)
            
            feed.descriptionFeed = feedDescription
            feed.imageUrl = feedImageUrl
            
            
            feeds.append(feed)
            insideItem = false
        }
    }
}






















