//
//  FeedCoreData+CoreDataProperties.swift
//  MyXMLParserDemo
//
//  Created by Ihar Karalko on 8/16/17.
//  Copyright © 2017 Ihar Karalko. All rights reserved.
//

import Foundation
import CoreData


extension FeedCoreData {

    @nonobjc public class func fetchRequestExecute() -> NSFetchRequest<FeedCoreData> {
        return NSFetchRequest<FeedCoreData>(entityName: "FeedCoreData")
    }

    @NSManaged public var date: String?
    @NSManaged public var dateDate: NSDate?
    @NSManaged public var descriptionFeed: String?
    @NSManaged public var imageNSData: NSData?
    @NSManaged public var title: String?
    @NSManaged public var imageUrl: String?

}
