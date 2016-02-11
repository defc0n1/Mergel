//
//  HexMapHelper.swift
//  HexMatch
//
//  Created by Josh McKee on 1/12/16.
//  Copyright © 2016 Josh McKee. All rights reserved.
//
import SpriteKit

class HexMapHelper: NSObject {
    // singleton
    static let instance = HexMapHelper()
    
    // Debugging
    let displayCellCoordinates = false
    
    // Hex Map
    var hexMap: HexMap?
    
    var addedCounter = 0
    
    // Collection of the sprites which were created to represent the hexmap
    var hexMapSprites: [[SKSpriteNode]] = Array()
    
    // Constants related to rendering of hex cell nodes
    let cellNodeHorizontalAdvance = 44
    let cellNodeVerticalAdvance = 50
    let cellNodeVerticalStagger = 25
    
    // Actual height/width dimensions of each cell
    let cellActualHeight = 59
    let cellActualWidth = 60
    
    // Offsets
    let offsetLeft = 30
    let offsetBottom = 60
    
    // Hex piece textures
    let hexPieceTextureNames = ["Triangle","Rhombus","Square","Pentagon","Hexagon","Star","GoldStar"]
    var maxPieceValue = 0
    var hexPieceTextures: [SKTexture] = Array()
    
    // Wildcard 
    let wildcardPieceTextureNames = ["Wildcard"]
    var wildcardPieceTextures: [SKTexture] = Array()
    
    let wildcardPlacedTextureName = "Blackstar"
    var wildcardPlacedTexture: SKTexture?
    let wildcardPlacedValue = 10
    
    override init() {
        super.init()
        
        // Load each texture and store them for later use
        for textureName in hexPieceTextureNames {
            self.hexPieceTextures.append(SKTexture(imageNamed: textureName))
        }
        
        // Load wildcard texture(s)
        for textureName in wildcardPieceTextureNames {
            self.wildcardPieceTextures.append(SKTexture(imageNamed: textureName))
        }
        
        // Load wildcard placed texture
        self.wildcardPlacedTexture = SKTexture(imageNamed: self.wildcardPlacedTextureName)
        
        // set maximum value
        self.maxPieceValue = self.hexPieceTextureNames.count-1
    }
    
    /**
        Converts a hexmap co-ordinate to screen position

        - Parameters:
            - x: row of the hex cell
            - y: column of the hex cell

        - Returns: A CGPoint of the on-screen location of the hex cell
    */
    func hexMapToScreen(x: Int, _ y: Int) -> CGPoint {
        let x2 = self.cellNodeHorizontalAdvance * x
        var y2 = Int(CGFloat(self.cellNodeVerticalAdvance) * CGFloat(y))
        
        if (x % 2 != 0) {
            y2 -= self.cellNodeVerticalStagger
        }
        
        return CGPointMake(CGFloat(x2+self.offsetLeft),CGFloat(y2+self.offsetBottom))
    }
    
    func hexMapToScreen(position: HCPosition) -> CGPoint {
        return self.hexMapToScreen(position.x, position.y)
    }
    
    func getRenderedWidth() -> CGFloat {
        return CGFloat(self.cellNodeHorizontalAdvance*(self.hexMap!.width)) + CGFloat(self.cellActualWidth - self.cellNodeHorizontalAdvance)
    }
    
    func getRenderedHeight() -> CGFloat {
        return CGFloat(self.cellActualHeight*(self.hexMap!.height)) - CGFloat(self.cellActualHeight - self.cellNodeVerticalAdvance)
    }
    
    /**
        Creates SKSpriteNode instances based on self.hexMap and adds them to a given parent SKNode. Each node is tracked in array hexMapSprites for later reference.

        - Parameters:
            - parent: The parent SKNode which will receive the hexmap's nodes

        - Returns: None
    */
    func renderHexMap(parent: SKNode) {
        self.renderHexMapShadow(parent);
    
        let emptyCellTexture = SKTexture(imageNamed: "HexCell")
        let voidCellTexture = SKTexture(imageNamed: "HexCellVoid")
        
        var rows:[[SKSpriteNode]] = Array()
        
        for x in 0...self.hexMap!.width-1 {
            var rowSprites:[SKSpriteNode] = Array()
            for y in 0...self.hexMap!.height-1 {
                let hexCell = hexMap!.cell(x, y)
                
                var mapNode = SKSpriteNode(texture: emptyCellTexture)
                
                if (hexCell!.isVoid) {
                    mapNode = SKSpriteNode(texture: voidCellTexture)
                }
                
                // Name the node for convenience later
                mapNode.name = "hexMapCell"
                
                // We store the hex map x,y co-ordinate in the mapNode's userData dictionary so that
                // we can quickly know which cell was interacted with by the user (e.g. in the various thouch events)
                mapNode.userData = NSMutableDictionary()
                mapNode.userData!.setValue(x, forKey: "hexMapPositionX")
                mapNode.userData!.setValue(y, forKey: "hexMapPositionY")
                
                // Convert x,y to screen position
                mapNode.position = self.hexMapToScreen(x,y)
                
                // Add node to parent
                parent.addChild(mapNode)
                
                // Add node to our rows array (which gets rolled up in to self.hexMapSprites)
                rowSprites.append(mapNode)
                
                // Render piece, if any, and add to parent
                if (hexCell!.hexPiece != nil) {
                    let hexPieceSprite = hexCell!.hexPiece!.createSprite()
                    
                    hexPieceSprite.position = mapNode.position
                    hexPieceSprite.zPosition = 2
                    
                    hexCell!.hexPiece!.sprite = hexPieceSprite
                    
                    parent.addChild(hexPieceSprite)
                }
                
                if (self.displayCellCoordinates) {
                    let positionSprite = SKLabelNode(text: "\(x),\(y)")
                    positionSprite.zPosition = 10000
                    mapNode.addChild(positionSprite)
                }
            }
            
            // Add nodes from the row to our columns array (which becomes self.hexMapSprites)
            rows.append(rowSprites)
        }
        
        self.hexMapSprites = rows
    }
    
    
    func renderHexMapShadow(parent: SKNode) {
        let emptyCellTexture = SKTexture(imageNamed: "HexCellShadow")
        let voidCellTexture = SKTexture(imageNamed: "HexCellVoid")
        
        for x in 0...self.hexMap!.width-1 {
            for y in 0...self.hexMap!.height-1 {
                let hexCell = hexMap!.cell(x, y)
                
                var mapNode = SKSpriteNode(texture: emptyCellTexture)
                
                mapNode.zPosition = -1
                
                if (hexCell!.isVoid) {
                    mapNode = SKSpriteNode(texture: voidCellTexture)
                }
                
                // Name the node for convenience later
                mapNode.name = "hexMapCellShadow"
                
                // Convert x,y to screen position
                mapNode.position = self.hexMapToScreen(x,y)
                
                // Add node to parent
                parent.addChild(mapNode)
            }
        }
    }
    
    func clearHexMap(parent: SKNode) {
        for childNode in parent.children {
            if (childNode.name == "hexPiece" || childNode.name == "hexMapCell" || childNode.name == "hexMapCellShadow") {
                childNode.removeFromParent()
            }
        }
    }
    
    
    
    /**
        Creates a sprite to represent a wildcard piece

        - Parameters:
            - hexPiece: The hexPiece instance for which the sprite is being created
            
        - Returns: Instance of SKSpriteNode
    */
    func createWildCardSprite(hexPiece: HexPiece) -> SKSpriteNode {
        let node = SKSpriteNode(texture: self.hexPieceTextures.first)
        node.name = "hexPiece"
        
        node.runAction(
            SKAction.repeatActionForever(
                SKAction.animateWithTextures(
                    self.wildcardPieceTextures,
                    timePerFrame: 0.2,
                    resize: false,
                    restore: true
                )
            ),
            withKey:"wildcardAnimation"
        )
        
        return node
    }
    
    func getFirstMerge() -> [HexPiece] {
        var merged: [HexPiece] = Array()
        
        let occupiedCells = self.hexMap?.getOccupiedCells()
        
        if (occupiedCells != nil) {
            for occupiedCell in occupiedCells! {
                if (occupiedCell.hexPiece != nil) {
                    merged = occupiedCell.getWouldMergeWith(occupiedCell.hexPiece!)
                    
                    if (merged.count>0) {
                        merged.append(occupiedCell.hexPiece!)
                        break;
                    }
                }
            }
        }
        
        return merged
    }
}
