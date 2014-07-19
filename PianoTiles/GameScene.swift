//
//  GameScene.swift
//  PianoTiles
//
//  Created by Skip Wilson on 6/23/14.
//  Copyright (c) 2014 Skip Wilson. All rights reserved.
//
import SpriteKit

//to give the
extension String {
    subscript (i: Int) -> String {
        return String(Array(self)[i])
    }
}

class GameScene: SKScene {
    let numberOfRows = 4
    let numberOfColumns = 4
    var skBounds:CGRect = CGRect()
    let tileColor = UIColor(hex: 0x000000)
    var tileWidth:Int = 0
    var tileHeight:Int = 0
    var tileSize = CGSize()
    var tiles:[String] = []
    var topRowY = CGFloat(0)
    var flipPosition = 0
    var milliseconds = 0.0
    var timerLabel = SKLabelNode()
    var completed = 0
    
    var timer = NSTimer()

    override func didMoveToView(view: SKView) {
        //background color is white
        self.backgroundColor = UIColor(hex: 0xFFFFFF)
        //grab the bounds of the view
        self.skBounds = self.view.bounds
        //set a width to be the screen divided by the number of columns
        self.tileWidth = Int(skBounds.size.width / CGFloat(self.numberOfColumns))
        //set the height to be the screen divided by the number of rows
        self.tileHeight = Int(skBounds.size.height / CGFloat(self.numberOfRows))
        //create a cgsize to hold the size of the tile.
        self.tileSize = CGSize(width: tileWidth, height: tileHeight)

        self.timerLabel = SKLabelNode(fontNamed: "Courier")
        self.timerLabel.text = "0.00"
        self.timerLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        self.timerLabel.fontColor = UIColor(hex:0xFF0000)
        self.addChild(self.timerLabel)
        
        //put the tiles on the screen
        makeTiles()
        startTimer()
    }
    
    func startTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("updateTimer"), userInfo: nil, repeats: true)
    }
    
    func updateTimer() {
        ++milliseconds
        self.timerLabel.text = String(self.milliseconds * 0.01)
    }
    
    
    //our random function to color one tile on each row black
    func randomColumn() -> Int {
        var range = UInt32(0)..<UInt32(self.numberOfColumns-1)
        return Int(range.startIndex + arc4random_uniform(range.endIndex - range.startIndex + 1))
    }
    
    func makeTiles() {
        //this will make 5 rows. One extra for the top.
        for row in 0...(self.numberOfRows) {
            var specialColumn = randomColumn()
            //this will make 4 columns starting at 0
            for column in 0...(self.numberOfColumns-1) {
                //this is the place we want to put the square
                var point =  CGPoint(x: column * self.tileWidth, y: (row * self.tileHeight))
                //we need to move it by have because of where it is measured from (the center)
                point.x += CGFloat(self.tileWidth/2)
                point.y += CGFloat(self.tileHeight/2)
                //get top row for reseting positions
                if row == self.numberOfRows && column == 0 {
                    topRowY = point.y
                }
                //we create a rect of the tilesize. We position it manually with sprite.position
                var rectangleButton = SKShapeNode(rectOfSize: self.tileSize)
                rectangleButton.position = point
                //if it's a random special column we color it in
                if column == specialColumn {
                    rectangleButton.fillColor = UIColor(hex: 0x000000)
                }
                //set the stroke of the pen
                rectangleButton.strokeColor = UIColor(hex: 0x000000)
                //give it a unique name for finding it later.
                rectangleButton.name = "rectangle_\(row)\(column)"
                //add it to the stage
                self.addChild(rectangleButton)
                //save all the string names.
                tiles.append(rectangleButton.name)
            }
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        for touch: AnyObject in touches {
            //grab the location of said touch
            let location = touch.locationInNode(self)
            if !isRightTileAt(location: location) {
                return;
            }
            completed++
            if completed == 20 {
                println("You Win!")
            }
            
            if self.flipPosition > 0 {
                //last row * num columns (the last cell in said row)
                var last = flipPosition * self.numberOfColumns
                //the first cell in said row (last - (self.numcols - 1)
                var first = last - (self.numberOfColumns - 1)
                //include the last should give something like 5,6,7,8
                var rangeOfCurrentRow = first...last
                //get the highest y value of tiles so we know where to put it at the top.
                var highestYValue = highestTileY()
                //choose a new column to be black
                var newRandomColumn = randomColumn()
                //enumerate because we also need the index so we can color a cell from a column black
                for (index,cell) in enumerate(rangeOfCurrentRow) {
                    //grab the cell at that index. minus one because it's an array
                    var rowTile = self.childNodeWithName(self.tiles[cell-1]) as SKShapeNode
                    
                    //position the new cell of this row
                    rowTile.position.y = highestYValue + CGFloat(self.tileHeight)
                    //color the right new tile to be black
                    if index == newRandomColumn {
                        //correct one should be filled black
                        rowTile.fillColor = UIColor(hex:0x000000)
                    } else {
                        //else goes back to white
                        rowTile.fillColor = UIColor(hex:0xFFFFFF)
                    }
                }
            }
        
            //setting the correct flip position. If it is 5 we need to go back to 1
            if self.flipPosition == 5 {
                self.flipPosition = 1
            }else {
                self.flipPosition++
            }

            //loop through our array of string of tiles
            for tile in tiles {
                //this tile is the grabbed by it's node name
                var thisTile = self.childNodeWithName(tile)
                //we need a vector to say how far to move said tile.
                var cgVector = CGVectorMake(CGFloat(0), CGFloat(-self.tileHeight))
                thisTile.runAction(SKAction.moveBy(cgVector, duration: 0.1))
            }
            //only loop once
            return
        }
    }
    
    func isRightTileAt(#location:CGPoint) ->Bool {
        //as shape node so we can get fill
        var currentRect = self.nodeAtPoint(location) as SKShapeNode
        //get the 10th character which will contain the row and make it an int
        var rowOfNode = currentRect.name[10].toInt()
        //flip position is used for the row index below the screen to flip it to the top.
        var currentRow = self.flipPosition + 1
        var currentRowOfClick = self.flipPosition
        
        //we reuse the flip position because it hasn't flipped yet but it normally contains the right row.
        //because flip position happens after this check so it won't be sent back around yet
        if self.flipPosition == 5 {
            currentRowOfClick = 0
        }
        //if they are at least on the right row
        if rowOfNode == currentRowOfClick && currentRect.fillColor.hash == 65536{
            return true
        }
        return false
    }
    
    func highestTileY() -> CGFloat {
        //the largest int possible
        var maxY = CGFLOAT_MIN
        for tile in tiles {
            //we want to find the highest Y position available so we can put it there.
            var thisTile = self.childNodeWithName(tile)
            if thisTile.position.y > maxY {
                maxY = thisTile.position.y
            }
        }
        return maxY
    }
   
    override func update(currentTime: CFTimeInterval) {
    }
}
