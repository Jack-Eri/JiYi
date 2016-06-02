//
//  CoreDataManager.swift
//  JiYi
//
//  Created by Nohan Budry on 02.06.16.
//  Copyright © 2016 Nodev. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    
    class func managedObjectContext() -> NSManagedObjectContext {
        
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    class func saveManagedObjectContext() -> Bool {
        
        do {
            
            try managedObjectContext().save()
            return true
        
        } catch {
            
            print(error)
            return false
        }
    }
    
    class func insertManagedObject(className: NSString, managedObjectContext: NSManagedObjectContext) -> NSManagedObject {
        
        return NSEntityDescription.insertNewObjectForEntityForName(className as String, inManagedObjectContext: managedObjectContext)
    }
    
    class func fetchEntities(className: NSString, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [NSManagedObject] {
        
        let fetchRequest = NSFetchRequest()
        
        fetchRequest.entity = NSEntityDescription.entityForName(className as String, inManagedObjectContext: managedObjectContext)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            
            return try managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
            
        } catch {
            
            print(error)
            return []
        }
        
    }
}

//MARK: Card entity funcs
extension CoreDataManager {
    
    class func insertCard(sign: String, traduction: String, createdbyUser: Bool, genres: NSSet?) -> Card? {
        
        let context = managedObjectContext()
        let card = insertManagedObject("Card", managedObjectContext: context) as! Card
        
        card.identifier = NSDate()
        card.sign = sign
        card.traduction = traduction
        card.createdByUser = createdbyUser
        card.genres = genres != nil ? genres! : NSSet()
        
        return saveManagedObjectContext() ? card : nil
    }
}

//MARK: Genre entity funcs
extension CoreDataManager {
    
    class func insertGenre(title: String, createdbyUser: Bool, cards: NSSet?) -> Genre? {
        
        let context = managedObjectContext()
        let genre = insertManagedObject("Genre", managedObjectContext: context) as! Genre
        
        genre.identifier = NSDate()
        genre.title = title
        genre.createdByUser = createdbyUser
        genre.cards = cards != nil ? cards! : NSSet()
        
        return saveManagedObjectContext() ? genre : nil
    }
}

//MARK: default values manager
extension CoreDataManager {
    
    class func insertDefaultValues() -> Bool {
        
        let path = NSBundle.mainBundle().pathForResource("Cards", ofType: "plist")
        let dict = NSArray(contentsOfFile: path!) as! [AnyObject]
        
        for cardDict in dict {
            
            insertCardWithDefaultValues(cardDict as! [String:AnyObject])
        }
        
        return saveManagedObjectContext()
    }
    
    class func insertCardWithDefaultValues(dict: [String:AnyObject]) {
        
        let sign = dict["sign"] as! String
        let traduction = dict["traduction"] as! String
        let genres = dict["genres"] as! [String]
        
        if let card = insertCard(sign, traduction: traduction, createdbyUser: false, genres: nil) {
            
            for genre in genres {
                
                //add genre of the card and insert if needed
                card.addToGenre(genre, insertIfNeeded: true, createdByUser: false)
            }
        }
    }
}


















