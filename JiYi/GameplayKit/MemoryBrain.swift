//
//  MemoryBrain.swift
//  JiYi
//
//  Created by Nohan Budry on 08.06.16.
//  Copyright © 2016 Nodev. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import CoreData

class MemoryBrain {
	
	let possibleCards: [Card]
	let nbOfPairs: Int
	let scene: SKScene
	var gameArray: [CardEntity]!
	
	//layers
	let gameBoardLayer: SKNode
	let menuLayer: SKSpriteNode
	
	//managers
	let entityManager: EntityManager
	var stateMachine: GKStateMachine!
	
	//constants
	let defaultCardSize: CGFloat = 100
	let defaultSpacement: CGFloat = 15
	
	init(cards: [Card], nbOfPairs: Int, inScene: SKScene) {
		
		self.possibleCards = cards
		self.nbOfPairs = nbOfPairs
		self.scene = inScene
		
		entityManager = EntityManager(scene: inScene)
		
		//layers setup
		
		menuLayer = scene.childNodeWithName("TopBar") as! SKSpriteNode
		
		gameBoardLayer = SKNode()
		scene.addChild(gameBoardLayer)
		
		//createStateMachine
		stateMachine = GKStateMachine(
			states: [
				GamePreparationState(withMemoryBrain: self),
				CardsSelectionState(withMemoryBrain: self),
				CardsCheckingState(withMemoryBrain: self),
				GameOverState(withMemoryBrain: self)
			]
		)
		
		stateMachine.enterState(GamePreparationState)
	}
	
	func setupGame() {
		
		//Setup needed values
		let gameBoradSize = CGSizeMake(scene.size.width, scene.size.height - menuLayer.size.height)
		
		let cardsPerLine = getCardsPerLine(nbOfPairs)
		let cardScale = getBetterCardScale(
			boardSize: gameBoradSize,
			space: defaultSpacement,
			nbsOfCards: (cardsPerLine[0], CGFloat(cardsPerLine.count)),
			cardSize: defaultCardSize
		)
		
		//place gameBoard
		let cardSize = defaultCardSize * cardScale
		let totalCardSize = CGSizeMake(
			cardsPerLine[0] * (cardSize + defaultSpacement) + defaultSpacement,
			CGFloat(cardsPerLine.count) * (cardSize + defaultSpacement) + defaultSpacement
		)
		
		gameBoardLayer.position = CGPointMake(
			(gameBoradSize.width - totalCardSize.width) / 2 + cardSize / 2 + defaultSpacement,
			(gameBoradSize.height - totalCardSize.height) / 2 + cardSize / 2 + defaultSpacement
		)
		
		//MARK: - Card Array Setup
		
		//create a shuffuled array of possible signs
		let randomSource = GKRandomSource()
		var shuffuledPossibleSigns = randomSource.arrayByShufflingObjectsInArray(possibleCards) as! [Card]
		
		//get used signs
		var keepedSigns = [Card]()
		for _ in 0 ..< nbOfPairs {
			
			keepedSigns.append(shuffuledPossibleSigns.removeFirst())
		}
		
		//double the array to have each signe twice and shuffle the array
		keepedSigns.appendContentsOf(keepedSigns)
		let cards = randomSource.arrayByShufflingObjectsInArray(keepedSigns) as! [Card]
		self.gameArray = []
		
		//createEntities
		var index = 0
		for card in cards {
			
			let cardEntity = CardEntity(
				card: card,
				spacement: defaultSpacement,
				cardSize: defaultCardSize * cardScale,
				cardsPerLine: cardsPerLine,
				index: index,
				nbOfCards: cards.count
			)
			self.gameArray.append(cardEntity)
			entityManager.add(cardEntity, allreadyInScene: false, inLayer: gameBoardLayer)
			
			index += 1
		}
	}
}

//MARK: - UI
extension MemoryBrain {
	
	func getCardScale(length: CGFloat, space: CGFloat, nbOfCards: CGFloat, cardSize: CGFloat) -> CGFloat {
		
		//get the good scale to fit the length
		return (length - (nbOfCards + 1) * space) / nbOfCards / cardSize
	}
	
	func getBetterCardScale(boardSize size: CGSize, space: CGFloat, nbsOfCards: (x: CGFloat, y: CGFloat), cardSize: CGFloat) -> CGFloat {
		
		let xRatio = getCardScale(size.width, space: space, nbOfCards: nbsOfCards.x, cardSize: cardSize)
		let yRatio = getCardScale(size.height, space: space, nbOfCards: nbsOfCards.y, cardSize: cardSize)
		
		//get the best scale that fit the screen
		return xRatio < yRatio ? xRatio : yRatio
	}
	
	func getCardsPerLine(nbOfPairs: Int) -> [CGFloat] {
		
		if nbOfPairs >= 7 {
			
			//calculate card count for each lines
			let isEven = nbOfPairs % 2 == 0
			var lines = [CGFloat]()
			
			/*
			for line 0 and 1
			card count
			-> nbOfPairs / 2, if nbOfPairs is even
			-> (nbOfPairs + 1) / 2, if nbOfPairs is odd
			*/
			for _ in 0 ..< 2 {
				
				lines.append(isEven ? CGFloat(nbOfPairs) / 2 : CGFloat(nbOfPairs + 1) / 2)
			}
			
			/*
			for line 2 and 3
			card count
			-> nbOfPairs / 2, if nbOfPairs is even
			-> (nbOfPairs - 1) / 2, if nbOfPairs is odd
			*/
			for _ in 0 ..< 2 {
				
				lines.append(isEven ? CGFloat(nbOfPairs) / 2 : CGFloat(nbOfPairs - 1) / 2)
			}
			
			return lines
		}
		
		//for values less than 7 -> the algorythm can't be used
		switch nbOfPairs {
			
		case 6:
			return [4, 4, 4]
			
		case 5:
			return [4, 3, 3]
			
		case 4, 3, 2:
			return [CGFloat(nbOfPairs), CGFloat(nbOfPairs)]
			
		default: // if less than 2 pairs, can't play
			return []
		}
	}
}

//MARK: - Game Funcs
extension MemoryBrain {
	
	func cardEntityClicked(gameArrayIndex index: Int) {

		let entity = gameArray[index]
		
		if let state = stateMachine.currentState as? CardsSelectionState {
			
			state.selectCard(entity)
		}
	}
	
	func showCheckResult(cards: [CardEntity], equals: Bool) {
		
		let waitAction = SKAction.waitForDuration(equals ? 0.5 : 2.0)
		gameBoardLayer.runAction(waitAction) {
			
			for card in cards {
				
				if equals {
					
					card.found()
					
				} else {
					
					card.switchTo(faceUp: false)
				}
			}
			
			if !self.isGameFinished() {
				
				self.stateMachine.enterState(CardsSelectionState)
				
			} else {
				
				self.stateMachine.enterState(GameOverState)
			}
		}
	}
	
	func isGameFinished() -> Bool {
		
		for card in gameArray {
			
			if !(card.stateMachine.currentState is FoundState) {
				
				return false
			}
		}
		
		return true
	}
	
	func showEndText(node: SKNode) {
		
		node.alpha = 0
		
		scene.addChild(node)
		
		let fadeIn = SKAction.fadeInWithDuration(0.25)
		let wait = SKAction.waitForDuration(5.0)
		let fadeOut = SKAction.fadeOutWithDuration(0.25)
		
		node.runAction(SKAction.sequence([fadeIn, wait, fadeOut])) {
			
			node.removeFromParent()
		}
	}
}



































