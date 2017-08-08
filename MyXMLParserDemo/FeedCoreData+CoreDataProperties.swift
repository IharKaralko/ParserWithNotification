//
//  FeedCoreData+CoreDataProperties.swift
//  MyXMLParserDemo
//
//  Created by Ihar Karalko on 7/19/17.
//  Copyright © 2017 Ihar Karalko. All rights reserved.
//

import Foundation
import CoreData


extension FeedCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedCoreData> {
        return NSFetchRequest<FeedCoreData>(entityName: "FeedCoreData")
    }

    @NSManaged public var title: String?
    @NSManaged public var date: String?
    @NSManaged public var descriptionFeed: String?
    @NSManaged public var imageNSData: NSData?

}
