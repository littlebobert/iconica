//
//  GameTest1.swift
//  iconica
//
//  Created by Justin Garcia on 8/27/14.
//  Copyright (c) 2014 jg. All rights reserved.
//

import UIKit
import XCTest

import iconica

class GameTest1: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        
        var player1 = Player(name: "Bobert")
        var player2 = Player(name: "Don")
        
        var character1 = character61()
        var character2 = character45()
        
        var rolls = Array<TestRoll>()
        // character 1
        rolls.append(TestRoll(msg:"Action", die1Value: 2))
        rolls.append(TestRoll(msg:"Stun", die1Value: 5))
        // character 2 is stunned
        // character 1
        rolls.append(TestRoll(msg:"Action", die1Value: 4))
        // character 2
        rolls.append(TestRoll(msg:"Action", die1Value: 1))
        // character 1
        rolls.append(TestRoll(msg:"Action", die1Value: 1))
        // character 2, this won't go off because its a melee action
        rolls.append(TestRoll(msg:"Action", die1Value: 4))
        // character 1
        rolls.append(TestRoll(msg:"Action", die1Value: 5))
        // character 2
        rolls.append(TestRoll(msg:"Action", die1Value: 4))
        rolls.append(TestRoll(msg:"Fear", die1Value: 5))
        // character 1
        rolls.append(TestRoll(msg:"Remove Fear", die1Value: 5))
        // character 2
        rolls.append(TestRoll(msg:"Remove Fear", die1Value: 5))
        // character 1
        rolls.append(TestRoll(msg:"Action", die1Value: 1))
        // character 2 does Irresistible Charm
        rolls.append(TestRoll(msg:"Action", die1Value: 5))
        // and uses it to do Flying Fist
        rolls.append(TestRoll(msg:"Action", die1Value: 2))
        // which stuns character 1
        rolls.append(TestRoll(msg:"Stun", die1Value: 3))
        // character 1 is stunned so character 2 goes
        rolls.append(TestRoll(msg:"Action", die1Value: 3))
        // character 1 does evasive manuevers
        rolls.append(TestRoll(msg:"Action", die1Value: 3))
        // character 2 does Backstab
        rolls.append(TestRoll(msg:"Action", die1Value: 4))
        rolls.append(TestRoll(msg:"Fear", die1Value: 4))
        
        var targets = Array<Targets>()
        // character 1
        targets.append([character2])
        // character 1
        targets.append([character1])
        targets.append([character2])
        // character 2
        targets.append([character2])
        targets.append([character1])
        // character 1
        targets.append([character2])
        // character 2's action won't take place because it's a melee action
        // character 1's action is delayed and uses a chooser
        // character 2
        targets.append([character1])
        // characeter 1 rolls to remove Fear
        // character 2 rolls to remove Fear
        // character 1
        targets.append([character2])
        // character 2 does Irresistible Charm
        targets.append([character1])
        // character 2 uses Irrestible Charm to perform character 1's Flying Fist
        targets.append([character1])
        // character 1 is stunned
        // character 2 does Transfix
        // character 1 does Evasive Manuevers
        // character 2 does Backstab
        targets.append([character1]) // Evasive Manuevers
        targets.append([character1])
        
        var gameController = GameController(players: [player1, player2], testRolls:rolls, testTargets:targets)
        
        character1.player = player1
        character2.player = player2
        
        player1.character = character1
        player2.character = character2
        
        let character2InitialLife = character2.life
        let character1InitialLife = character1.life
        
        gameController.takeTurn()
        
        XCTAssert(character2.life == character2InitialLife - 30, "Character should now have 30 less life")
        XCTAssert(character2.stun == true, "Character should be stunned")
        
        // character 2
        gameController.takeTurn()
        
        XCTAssert(character2.stun == false, "Character shouldn't be stunned")
        
        // character 1
        gameController.takeTurn()
        
        // fixme: check to see that health did not go over max health
        XCTAssert(character2.life == character2InitialLife - 50, "Character should have 50 less life")
        
        // character 2
        gameController.takeTurn()
        
        XCTAssert(character1.life == character1InitialLife - 30, "Character should have 30 less life")
        XCTAssert(character2.life == character2InitialLife - 20, "Character should have 20 less life")
        
        // character 1
        gameController.takeTurn()
        
        XCTAssert(character2.life == character2InitialLife - 40, "Character should have 50 less life")
        
        // character 2
        gameController.takeTurn()
        
        XCTAssert(character1.life == character1InitialLife - 30, "Character should still have 30 less life")
        
        // character 1
        gameController.takeTurn()
        
        XCTAssert(gameController.actionsForNextTurn.count == 1, "There should be an action queued for the next turn")
        
        // character 2 backstabs for 60, takes 20 bc of Vigilance
        gameController.takeTurn()
        
        XCTAssert(character1.life == character1InitialLife - 90, "Character should have 90 less life")
        XCTAssert(character2.life == character2InitialLife - 60, "Character should have 70 less life")
        XCTAssert(character2.fear == true, "Character should have Fear")
        XCTAssert(character1.fear == true, "Character should have Fear")
        XCTAssert(character2.actionTrigger == nil, "Character shouldn't have an action trigger")
        
        // character 1 rolls to remove fear
        gameController.takeTurn()
        
        XCTAssert(character1.fear == false, "Character shouldn't have Fear")
        XCTAssert(character2.fear == true, "Character should have Fear")
        
        // character 2 rolls to remove Fear
        gameController.takeTurn()

        XCTAssert(character2.fear == false, "Character shouldn’t have Fear")
        
        // character 1
        gameController.takeTurn()
        
        XCTAssert(character2.life == character2InitialLife - 80, "Character should have 90 less life")
        
        // character 2
        gameController.takeTurn()
        
        XCTAssert(character1.stun == true, "Character should be stunned")
        XCTAssert(character1.life == character1InitialLife - 120, "Character should have 120 less life.")
        
        // character 1 is stunned
        gameController.takeTurn()
        
        // character 2 does Transfix
        gameController.takeTurn()

        XCTAssert(character1.life == character1InitialLife - 120, "Character should have 120 less life.")
        XCTAssert(character2.life == character2InitialLife - 80, "Character should have 90 less life")
        
        // character 1 does Evasive Manuevers
        gameController.takeTurn()
        
        XCTAssert(character1.life == character1InitialLife - 120, "Character should have 120 less life.")
        XCTAssert(character2.life == character2InitialLife - 80, "Character should have 90 less life")
        
        // character 2 does Backstab but it has no effect
        gameController.takeTurn()
        
        XCTAssert(character1.fear == false, "Character should not have Fear")
        XCTAssert(character1.life == character1InitialLife - 120, "Character should have 120 less life.")
        XCTAssert(character2.life == character2InitialLife - 80, "Character should have 90 less life")
        
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
