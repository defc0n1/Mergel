//
//  HexPiece.swift
//  HexMatch
//
//  Created by Josh McKee on 1/14/16.
//  Copyright © 2016 Josh McKee. All rights reserved.
//

import SpriteKit

class HexPiece : NSObject, NSCoding {
    
    // Controls whether or not the player can take the piece from the board
    var isCollectible = false
    
    // order in which piece was added to board
    var added = 0

    // HexCell that this piece is currently placed in, if any
    var _hexCell: HexCell?
    var hexCell: HexCell? {
        get {
            return self._hexCell
        }
        set {
            self._hexCell = newValue
            if (self._hexCell != nil) {
                if (self._hexCell != newValue) {
                    self._hexCell!.hexPiece = nil
                }
                
                self.added = HexMapHelper.instance.addedCounter++
            }
        }
    }
    
    // Sprite which represents this piece, if any
    var sprite: SKSpriteNode?
    
    // Caption which will be displayed when this piece is selected for placement
    var caption: String = ""
    
    // How many turns we have left to skip, and how many we should skip after being placed.
    var skipTurnCounter = 1
    var skipTurnsOnPlace = 1
    
    // Did we take a turn on the last pass?
    var didTakeTurn = false
    
    // Value tracking
    var originalValue = 0
    var _value = -1
    var value: Int {
        get {
            if (self._value == -1) {
                return 0;
            } else {
                return self._value
            }
        }
        set {
            if (self._value == -1) {
                self.originalValue = newValue
            }
            self._value = newValue
        }
    }
    
    override init() {
        super.init()
    }
    
    /**
        Decode for NSCoder
    */
    required init(coder decoder: NSCoder) {
        super.init()
    
        self.originalValue = (decoder.decodeObjectForKey("originalValue") as? Int)!
        self.value = (decoder.decodeObjectForKey("value") as? Int)!
        
        let hexCell = decoder.decodeObjectForKey("hexCell")
        if (hexCell != nil) {
            self._hexCell = (hexCell as? HexCell)!
        }
        
        let isCollectible = decoder.decodeObjectForKey("isCollectible")
        if (isCollectible != nil) {
            self.isCollectible = (isCollectible as? Bool)!
        }
        
        let caption = decoder.decodeObjectForKey("caption")
        if (caption != nil) {
            self.caption = (caption as? String)!
        }
        
        self.skipTurnCounter = (decoder.decodeObjectForKey("skipTurnCounter") as? Int)!
        self.skipTurnsOnPlace = (decoder.decodeObjectForKey("skipTurnsOnPlace") as? Int)!
    }
    
    /**
        Encode for NSCoder
    */
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.originalValue, forKey: "originalValue")
        coder.encodeObject(self.value, forKey: "value")
        
        coder.encodeObject(self._hexCell, forKey: "hexCell")
        
        coder.encodeObject(self.caption, forKey: "caption")
        
        coder.encodeObject(self.isCollectible, forKey: "isCollectible")
        
        coder.encodeObject(self.skipTurnCounter, forKey: "skipTurnCounter")
        coder.encodeObject(self.skipTurnsOnPlace, forKey: "skipTurnsOnPlace")
    }
    
    /**
        Returns the minimum value that this piece can merge with
    */
    func getMinMergeValue() -> Int {
        return self.value
    }
    
    /**
        Returns the maximum value that this piece can merge with
    */
    func getMaxMergeValue() -> Int {
        return self.value
    }
    
    /*
        Returns string used to identify this piece for statistics purposes
    */
    func getStatsKey() -> String {
        return "piece_value_\(self.value)"
    }
    
    /**
        Returns true if this piece can merge with hexPiece
    */
    func canMergeWithPiece(hexPiece: HexPiece) -> Bool {
        var result = false
        
        if (self.value == hexPiece.value && self.value < HexMapHelper.instance.maxPieceValue) {
            result = true
        }
        
        return result
    }
    
    /**
        Returns true if this piece can be placed on the gameboard without a merge
    */
    func canPlaceWithoutMerge() -> Bool {
        return true
    }
    
    /**
        Increase the value of this piece as though it had been merged, for merge testing purposes
    */
    func updateValueForMergeTest() {
        self.value++
    }
    
    /**
        Decrement the value of this piece after merge testing has finished
    */
    func rollbackValueForMergeTest() {
        self.value--
    }
    
    /**
        Called after piece has been placed on a hexmap and was merged with other piece(s)
    */
    func wasPlacedWithMerge(mergeValue: Int = -1) -> HexPiece {
        // Update to the next value in sequence, or cap at maxPieceValue
        self.value = mergeValue + 1
        
        if (self.value > HexMapHelper.instance.maxPieceValue) {
            self.value = HexMapHelper.instance.maxPieceValue
        }
    
        self.sprite!.texture = HexMapHelper.instance.hexPieceTextures[self.value]
        self.skipTurnCounter = self.skipTurnsOnPlace
        
        self.playMergeSound()
        
        // Clear caption, if any
        self.caption = ""
        
        return self
    }
    
    /**
        Called when piece was placed on a hexmap without merging with any other piece(s)
    */
    func wasPlacedWithoutMerge() {
        self.skipTurnCounter = self.skipTurnsOnPlace
        
        // Clear caption, if any
        self.caption = ""
        
        self.playPlacementSound()
    }
    
    /**
        - Returns: Calculated point value based on the piece's value
    */
    func getPointValue() -> Int {
        var points = 10
        
        switch (self.value) {
            case 0: // Triangle
            break
            case 1: // Rhombus
                points = 100
            break
            case 2: // Square
                points = 500
            break
            case 3: // Pentagon
                points = 1000
            break
            case 4: // Hexagon
                points = 10000
            break
            case 5: // Star
                points = 25000
            break
            case 6: // Gold Star
                points = 50000
            break
            default:
            break
        }
        
        return points
    }
    
    /**
        - Returns: Description of this piece, suitable for display to player
    */
    func getPieceDescription() -> String {
        var description = "Unknown"
        
        switch (self.value) {
            case 0: // Triangle
                description = "Triangle"
            break
            case 1: // Square
                description = "Square"
            break
            case 2: // Pentagon
                description = "Pentagon"
            break
            case 3: // Hexagon
                description = "Hexagon"
            break
            case 4: // Star
                description = "Star"
            break
            case 5: // Gold Star
                description = "Gold Star"
            break
            default:
            break
        }
        
        return description
    }
    
    /**
        Creates a sprite to represent the hex piece
    
        - Returns: Instance of SKSpriteNode
    */
    func createSprite() -> SKSpriteNode {
        let node = SKSpriteNode(texture: HexMapHelper.instance.hexPieceTextures[self.value])
    
        node.name = "hexPiece"        
    
        return node
    }
    
    /**
        Allow piece to do something after player has taken a turn.
    
        - Returns: True if piece did something.
    */
    func takeTurn() -> Bool {
        if (self.skipTurnCounter > 0) {
            self.skipTurnCounter--
            self.didTakeTurn = false
        } else {
            self.didTakeTurn = true
        }
        
        return self.didTakeTurn
    }
    
    /**
        Called when piece is collected by player
    */
    func wasCollected() {
        let scaleAction = SKAction.scaleTo(0.0, duration: 0.25)
        let collectSequence = SKAction.sequence([scaleAction, SKAction.removeFromParent()])
        
        // Animate the collection
        self.sprite!.runAction(collectSequence)
        
        // Play collect sound
        self.playCollectionSound()
    }
    
    func playCollectionSound() {
        self.sprite!.runAction(SoundHelper.instance.collect)
    }
    
    func playPlacementSound() {
        self.sprite!.runAction(SoundHelper.instance.placePiece)
    }
    
    func playMergeSound() {
        self.sprite!.runAction(SoundHelper.instance.mergePieces)
    }
    
    /**
        Called when piece is removed from the gameboard without collection / merge, i.e. by player using a RemovePiece.
    */
    func wasRemoved() {
        let collectSequence = SKAction.sequence([
            SKAction.scaleTo(1.2, duration: 0.08),
            SKAction.scaleTo(0.8, duration: 0.08),
            SKAction.scaleTo(1.0, duration: 0.08),
            SKAction.scaleTo(0.8, duration: 0.08),
            SKAction.scaleTo(0.9, duration: 0.08),
            SKAction.scaleTo(0.7, duration: 0.08),
            SKAction.scaleTo(0.8, duration: 0.08),
            SKAction.scaleTo(0.5, duration: 0.08),
            SKAction.scaleTo(0.2, duration: 0.08),
            SKAction.scaleTo(0.0, duration: 0.08),
            SKAction.removeFromParent()
        ])
        
        // Animate the collection
        self.sprite!.runAction(collectSequence)
    }

    
}