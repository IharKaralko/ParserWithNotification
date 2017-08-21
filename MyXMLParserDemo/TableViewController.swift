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

class TableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<FeedCoreData>?
    
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        title = "SPORT NEWS"
        let fetchRequest = FeedCoreData.fetchRequestExecute()
        
        let sortDateDate = NSSortDescriptor(key: "dateDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDateDate]
        
        
        
        guard let url = self.url else {return}
        guard let parser = XMLParser(contentsOf: url) else {return}
        parser.delegate = self
        
        let result = parser.parse()
        
        if result{
            print("Success")
        } else {
            print("Failure")
        }
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        
        saveInBackground(feeds: feeds)
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
    }
    
    
    // MARK: - FetchResultController
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        case .update:
              tableView.reloadData()
        }
    }
    
    func saveInBackground(feeds: [Feed]) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let mainContext = appDelegate.persistentContainer.viewContext
        
        appDelegate.persistentContainer.performBackgroundTask { context in
            
            feeds.forEach({ feed in
                
                let corefeed      = FeedCoreData(context: mainContext)
                corefeed.title    = feed.title
                corefeed.date     = feed.date
                corefeed.dateDate = feed.dateDate as NSDate?
                corefeed.descriptionFeed    = feed.descriptionFeed
                corefeed.imageUrl = feed.imageUrl
                
                guard let url = URL(string: feed.imageUrl) else { return }
                guard let imageData = try? Data(contentsOf: url) else { return }
                
                corefeed.imageNSData = imageData as NSData
                appDelegate.saveContext()
            })
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController?.sections?[section] else {
            return 0
        }
       // print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        configure(cell: cell, for: indexPath)
        return cell
    }
    
    func configure(cell: CustomTableViewCell, for indexPath: IndexPath) {
        
        if let feed = fetchedResultsController?.object(at: indexPath) {
            
            cell.fillCell(title: feed.title!, date: feed.date!, imageUrl: feed.imageUrl!, imageData: feed.imageNSData as Data?)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detail"{
            if let indexPath = tableView.indexPathForSelectedRow{
                
                let dvc = segue.destination as! ViewController
                let feed = fetchedResultsController?.object(at: indexPath)
                
                dvc.title = feed?.title
                dvc.detailFeed.date = feed?.date
                dvc.detailFeed.title = feed?.title
                dvc.detailFeed.descriptionFeed = feed?.descriptionFeed
                dvc.detailFeed.imageNSData = feed?.imageNSData
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






















