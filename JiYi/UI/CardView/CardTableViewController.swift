//
//  CardTableViewController.swift
//  JiYi
//
//  Created by Nohan Budry on 02.06.16.
//  Copyright © 2016 Nodev. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CardTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchedResultController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        
        instantiateFetchedResultController()
    }
    
    func instantiateFetchedResultController() {
        
        let fetchRequest = NSFetchRequest(entityName: "Card")
        let sorter = NSSortDescriptor(key: "traduction", ascending: true)
        fetchRequest.sortDescriptors = [sorter]
        
        let context = CoreDataManager.managedObjectContext()
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        
        do {
            
            try fetchedResultController.performFetch()
        
        } catch {
            
            fatalError("Failed to initialize fetched result controller: \(error)")
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        
        if let card = fetchedResultController.objectAtIndexPath(indexPath) as? Card {
        
            let signLabel = cell.viewWithTag(1000) as! UILabel
            let traductionLabel = cell.viewWithTag(1001) as! UILabel
            let pronunciationlabel = cell.viewWithTag(1002) as! UILabel
            
            signLabel.text = card.sign
            traductionLabel.text = card.traduction
            pronunciationlabel.hidden = !card.hasPronunciation()
            
            if !pronunciationlabel.hidden {
                
                card.instanciatePronunciations(nil)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            //perform an action like giving the delegate when switching the view
            switch identifier {
                
            default:
                break
            }
        }
    }
 }

//MARK: tableView funcs
extension CardTableViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return fetchedResultController.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sections = fetchedResultController.sections as [NSFetchedResultsSectionInfo]!
        
        return sections[section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("CardCell")!
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let card = fetchedResultController.objectAtIndexPath(indexPath) as? Card {
            
            if let sound = card.pronunciations.first {
                
                sound.play()
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}












