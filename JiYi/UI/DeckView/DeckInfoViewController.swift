//
//  DeckInfoViewController.swift
//  JiYi
//
//  Created by Nohan Budry on 03.06.16.
//  Copyright © 2016 Nodev. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol DeckInfoTableViewControllerDelegate {
    
    func deckInfoUpdateDeckList(indexPath: NSIndexPath)
}

class DeckInfoTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, DeckEditTableViewControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController!
    
    var delegate: DeckInfoTableViewControllerDelegate!
    var deck: Deck!
    var indexPath: NSIndexPath!
    
    override func viewDidLoad() {
        
        guard let deck = self.deck, _ = indexPath else {
            
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        instantiateFetchedResultdController()
        
        title = deck.title
        deck.instaciateCardsPronunciations()
    }
    
    func instantiateFetchedResultdController() {
        
        let fetchRequest = NSFetchRequest(entityName: "Card")
        let predicate = NSPredicate(format: "decks.title CONTAINS %@", deck.title)
        let sortDescriptor = NSSortDescriptor(key: "traduction", ascending: true)
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let context = CoreDataManager.managedObjectContext()
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            
            try fetchedResultsController.performFetch()
            
        } catch {
            
            fatalError("Failed to initialize fetched result controller: \(error)")
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        
        if let card = fetchedResultsController.objectAtIndexPath(indexPath) as? Card {
            
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
            
            case "DeckEditSegue":
                
                let navigationController = segue.destinationViewController as! UINavigationController
                let deckEditView = navigationController.topViewController as! DeckEditTableViewController
                
                deckEditView.delegate = self
                deckEditView.deck = deck!
            
            default:
                break
            }
        }
    }
}

//MARK: tableView funcs
extension DeckInfoTableViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sections = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]!
        
        return sections[section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("CardCell")!
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let card = deck!.cards.allObjects[indexPath.row] as! Card
        if card.hasPronunciation() {
            
            guard let sound = card.pronunciations.first else {
                
                return
            }
            
            sound.stop()
            sound.currentTime = 0
            sound.play()
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

//MARK: Deck Edit Delegate
extension DeckInfoTableViewController {
    
    func deckEditSaveDeck(deck: Deck?, title: String, cards: NSSet) -> Bool {
        
        if let theDeck = deck {
        
            theDeck.title = title
            theDeck.cards = cards
            
            if CoreDataManager.saveManagedObjectContext() {
                
                self.title = title
                tableView.reloadData()
                
                delegate.deckInfoUpdateDeckList(indexPath!)
                
                return true
            }
        }
        
        return false
    }
    
    func deckEditExit(controller: DeckEditTableViewController, animated: Bool) {
        
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}













