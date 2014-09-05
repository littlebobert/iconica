//
//  GameModel.swift
//  iconica
//
//  Created by Justin Garcia on 8/27/14.
//  Copyright (c) 2014 jg. All rights reserved.
//

import Foundation
import UIKit

public typealias Targets = Array<Character>

var gameController:GameController?

public class RollDelegate : NSObject {
    
    var rollClosure:() -> ()
    
    init(rollClosure:() -> ()) {
        self.rollClosure = rollClosure
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        self.rollClosure()
        gameController!.continueGame()
    }
}

public struct TestRoll {
    public var msg:String
    var die1Value:Int
    
    public init(msg:String, die1Value:Int) {
        self.msg = msg
        self.die1Value = die1Value
    }
}

public class GameController : NSObject {
    
    var currentPlayer:Player
    var players:Array<Player>
    var turn:Int
    var die1:Die
    var rollDelegate:RollDelegate?
    public var actionsForNextTurn:Array<ActionElement>
    var actionsForTurnAfterNext:Array<ActionElement>
    var gameLogic:Array<() -> ()>
    public var testRolls:Array<TestRoll>?
    public var testTargets:Array<Targets>?
    
    public init(players:Array<Player>) {
        self.players = players
        self.currentPlayer = players[0]
        self.turn = 0
        self.die1 = Die()
        self.actionsForNextTurn = Array<ActionElement>()
        self.actionsForTurnAfterNext = Array<ActionElement>()
        self.gameLogic = Array<() -> ()>()
        super.init()
        gameController = self
    }
    
    public init(players:Array<Player>, testRolls:Array<TestRoll>, testTargets:Array<Targets>) {
        self.players = players
        self.currentPlayer = players[0]
        self.turn = 0
        self.die1 = Die()
        self.actionsForNextTurn = Array<ActionElement>()
        self.actionsForTurnAfterNext = Array<ActionElement>()
        self.gameLogic = Array<() -> ()>()
        self.testRolls = testRolls
        self.testTargets = testTargets
        super.init()
        gameController = self
    }
    
    func allCharacters() -> Array<Character> {
        var characters = Array<Character>()
        for player in self.players {
            characters.append(player.character!)
        }
        return characters
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        self.die1.roll()
        var alert = UIAlertView(title: "You rolled a \(die1.toRaw())", message: "", delegate:rollDelegate, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func roll(msg:String, closure:(() -> ())?) {
        
        if self.testRolls != nil {
            var testRoll = self.testRolls![0]
            assert(testRoll.msg == msg, "The roll message was incorrect")
            if let die1Value = Die.fromRaw(testRoll.die1Value) {
                self.die1 = die1Value
            } else {
                assert(false, "The die roll should convert into a Die")
            }
            self.testRolls!.removeAtIndex(0)
            closure!()
            gameController!.continueGame()
            return
        }
        
        self.rollDelegate = nil
        if closure != nil {
            self.rollDelegate = RollDelegate(rollClosure:closure!)
        }
        var alert = UIAlertView(title: "Roll for \(msg)", message: "", delegate:self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func performActionElement(element:ActionElement, inout resolutions:Array<Targets -> ()>, inout resolutionTargets:Array<Targets>) {
        
        // fixme: display UI showing off this ActionElement
        var targets: Targets
        if element.chooser != nil {
            targets = element.chooser!(self.allCharacters())
        } else {
            if self.testTargets != nil {
                targets = self.testTargets![0]
                self.testTargets!.removeAtIndex(0)
            } else {
                // fixme: display Character picker (for element.numberOfTargets Characters)
                // fixme: only show the Character picker for Characters that pass .targetFilter
                if self.currentPlayer === self.players[0] {
                    targets = [self.players[1].character!]
                } else {
                    targets = [self.players[0].character!]
                }
            }
        }
        element.action(targets)
        if element.resolution != nil {
            resolutionTargets.append(targets)
            resolutions.append(element.resolution!)
        }
    }
    
    func continueGame() {
        if self.gameLogic.count == 0 {
            return
        }
        let f = self.gameLogic.removeAtIndex(0)
        f()
    }
    
    func performAction(action:Action, inout resolutions:Array<Targets -> ()>, inout resolutionTargets:Array<Targets>) {
        
        // fixme: show a chooser for which ActionElement to perform for ActionChoice.Or
        
        if action.actionChoice == .Or {
            self.gameLogic.append({
                var element = action.elements[0]
                
                if element.start == .NextTurn {
                    // fixme: show UI to show that this will happen next turn
                    self.actionsForNextTurn.append(element)
                    NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("continueGame"), userInfo: nil, repeats: false)
                } else if element.start == .TurnAfterNext {
                    self.actionsForTurnAfterNext.append(element)
                    NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("continueGame"), userInfo: nil, repeats: false)
                } else {
                    self.performActionElement(element, resolutions: &resolutions, resolutionTargets: &resolutionTargets)
                }
                
                self.continueGame()
            })
            return
        }
        
        for var i = 0; i < action.elements.count; i++ {
            self.gameLogic.append({ [i] in
                
                var element = action.elements[i]
                
                if element.start == .NextTurn {
                    // fixme: show UI to show that this will happen next turn
                    self.actionsForNextTurn.append(element)
                    NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("continueGame"), userInfo: nil, repeats: false)
                } else if element.start == .TurnAfterNext {
                    self.actionsForTurnAfterNext.append(element)
                    NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("continueGame"), userInfo: nil, repeats: false)
                } else {
                    self.performActionElement(element, resolutions: &resolutions, resolutionTargets: &resolutionTargets)
                }
                
                self.continueGame()
            })
        }
    }
    
    public func endTurn() {
        var opponent = self.currentPlayer === self.players[0] ? self.players[1] : self.players[0]
        self.currentPlayer = opponent
        
        if self.testRolls == nil {
            gameController!.takeTurn()
        }
    }
    
    public func takeTurn() {
        
        var resolutionTargets = Array<Targets>()
        var resolutions = Array<Targets -> ()>()
        
        // perform delayed ActionElements
        if self.actionsForNextTurn.count > 0 {
            for element in self.actionsForNextTurn {
                
                performActionElement(element, resolutions: &resolutions, resolutionTargets: &resolutionTargets)
                
            }
            self.actionsForNextTurn.removeAll(keepCapacity: false)
        }
        
        if self.actionsForTurnAfterNext.count > 0 {
            self.actionsForNextTurn = self.actionsForTurnAfterNext
            self.actionsForTurnAfterNext.removeAll(keepCapacity: false)
        }
        
        // fixme: display Character picker to choose which character acts
        // fixme: display action trigger, fear, stun icon over Characters that have them
        // fixme: display actionTrigger.description confirmation if the use chooses a character with one
        
        if self.currentPlayer.character!.stun == true {
            // fixme: display UI to highlight this
            self.currentPlayer.character!.stun = false
            
            self.endTurn()
            
            return
        }
        
        if self.currentPlayer.character!.fear == true {
            self.roll("Remove Fear", closure: {
                let rollValue = self.die1.toRaw()
                if rollValue % 2 == 1 {
                    self.currentPlayer.character!.fear = false
                }
                
                self.endTurn()
            })
            return
        }
        
        if self.currentPlayer.character!.actionTrigger != nil {
            self.currentPlayer.character!.actionTrigger!.effect(self.currentPlayer.character!)
        }
        
        self.roll("Action", closure: {
            let rollValue = self.die1.toRaw()
            if (rollValue < 1 && rollValue > 6 && rollValue > self.currentPlayer.character!.actions.count) {
                return
            }
            let action = self.currentPlayer.character!.actions[rollValue-1]
            println("attempting action \(rollValue) for \(self.currentPlayer.character!.name)")
            
            // fixme: check to see that character can perform this action type
            if action.type != .Melee || self.currentPlayer.character!.canTakeMeleeAction {
                self.performAction(action, resolutions: &resolutions, resolutionTargets: &resolutionTargets)
            }
            
            self.gameLogic.append({
                
                // perform resolutions
                for var i = 0; i < resolutions.count; i++ {
                    resolutions[i](resolutionTargets[i])
                }
                
                self.endTurn()
            })
            
            self.continueGame()
        })
    }
}

public enum ActionType {
    case Melee, Ranged, Status, Support, Healing, Stance
}

public enum ActionChoice {
    case And, Or
}

public class Action {
    var name:String
    public var elements:Array<ActionElement>
    var type:ActionType
    var actionChoice:ActionChoice
    
    init(name:String, type:ActionType, elements:Array<ActionElement>, actionChoice:ActionChoice) {
        self.name = name
        self.type = type
        self.elements = elements
        self.actionChoice = actionChoice
    }
    
    init(name:String, type:ActionType, elements:Array<ActionElement>) {
        self.name = name
        self.type = type
        self.elements = elements
        self.actionChoice = .And
    }
}

public func damageCharacter(character:Character, var damage:Int) {
    if character.targetable == false {
        assert(false, "Should not be able to target an untargetable Character")
        return
    }
    
    if character.damageMitigation != nil {
        damage = character.damageMitigation!(damage)
        character.life -= damage
    } else {
        character.life -= damage
    }
}

public func applyPoison(character:Character) {
    if character.avoidsNegativeStatusEffects {
        return
    }
    character.poison = true
}

public func applyFear(character:Character) {
    if character.avoidsNegativeStatusEffects {
        return
    }
    character.fear = true
}

public func applyStun(character:Character) {
    if character.avoidsNegativeStatusEffects {
        return
    }
    character.stun = true
}

public func applyBlind(character:Character) {
    if character.avoidsNegativeStatusEffects {
        return
    }
    character.blind = true
}

public func applyConfusion(character:Character) {
    if character.avoidsNegativeStatusEffects {
        return
    }
    character.confusion = true
}

public enum NumberOfTargets {
    case Some(Int)
    case Arbitrary
}

public enum Turn {
    case ThisTurn
    case NextTurn
    case TurnAfterNext
}

public class ActionElement {
    var action:Array<Character> -> ()
    var numberOfTargets:NumberOfTargets
    var resolution:(Array<Character> -> ())?
    public var chooser:(Array<Character> -> Array<Character>)?
    var targetFilter:(Character -> Bool)?
    var start:Turn
    
    init(var damage:Int) {
        self.action = {(targets:Array<Character>) -> () in
            if countElements(targets) != 1 {
                return
            }
            
            damageCharacter(targets[0], damage)
        }
        self.numberOfTargets = .Some(1)
        self.start = .ThisTurn
    }
    
    init(healing:Int) {
        self.action = {(targets:Array<Character>) -> () in
            if countElements(targets) != 1 {
                return
            }
            targets[0].life += healing
            if (targets[0].life > targets[0].maxLife) {
                targets[0].life = targets[0].maxLife
            }
        }
        self.numberOfTargets = .Some(1)
        self.start = .ThisTurn
    }
    init(damageWithPoison:Int) {
        self.action = {(targets:Array<Character>) -> () in
            if countElements(targets) != 1 {
                return
            }
            damageCharacter(targets[0], damageWithPoison)
            applyPoison(targets[0])
        }
        self.numberOfTargets = .Some(1)
        self.start = .ThisTurn
    }
    
    init(action:Array<Character> -> (), resolution:(Array<Character> -> ())?, chooser:(Array<Character> -> Array<Character>)?, numberOfTargets:NumberOfTargets, start:Turn) {
        self.action = action
        self.resolution = resolution
        self.chooser = chooser
        self.numberOfTargets = numberOfTargets
        self.start = start
    }
}

public enum Ability {
    case Evasion(Array<Int>), Courage(Array<Int>), Antidote(Array<Int>), Parry(Array<Int>)
}

public struct Reaction {
    var healthTrigger:Int
    var damage:Int
    init(healthTrigger:Int, damage:Int) {
        self.healthTrigger = healthTrigger
        self.damage = damage
    }
}

public enum Gender {
    case Male, Female
}

public class ActionTrigger {
    var description:String
    var effect:(Character) -> ()
    
    init(description:String, effect:(Character) -> ()) {
        self.description = description
        self.effect = effect
    }
}

public enum Faction {
    case Legion, Protectorate, Independent
}

public enum Class {
    case Offensive, Defensive, Adaptive, Disruptive, Supportive
}

public class Character {
    var name:String
    public var life:Int
    public var maxLife:Int
    var classType:Class
    var faction:Faction
    public var actions:Array<Action>
    var reactions:Array<Reaction>
    public var damageMitigation:(Int -> Int)?
    var gender:Gender
    var targetable:Bool
    var poison:Bool
    public var fear:Bool
    public var stun:Bool
    var confusion:Bool
    var blind:Bool
    var restoration:Bool
    public var canTakeMeleeAction:Bool
    public var actionTrigger:ActionTrigger?
    public var player:Player?
    var avoidsNegativeStatusEffects:Bool
    public var parry:Array<Int>?
    var evasion:Array<Int>?
    var antidote:Array<Int>?
    var courage:Array<Int>?
    var focus:Array<Int>?
    
    init(name:String, life:Int, gender:Gender, classType:Class, faction:Faction, actions:Array<Action>, reactions:Array<Reaction>) {
        self.name = name
        self.maxLife = life
        self.life = life
        self.gender = gender
        self.classType = classType
        self.faction = faction
        self.actions = actions
        self.reactions = reactions
        self.targetable = true
        self.poison = false
        self.fear = false
        self.stun = false
        self.confusion = false
        self.blind = false
        self.restoration = false
        self.canTakeMeleeAction = true
        self.avoidsNegativeStatusEffects = false
    }
}

public enum Die: Int {
    case One = 1
    case Two, Three, Four, Five, Six
    
    init() {
        self = .One
    }
    
    mutating func roll() {
        switch (arc4random() % 6) {
        case 0:
            self = .One
        case 1:
            self = .Two
        case 2:
            self = .Three
        case 3:
            self = .Four
        case 4:
            self = .Five
        case 5:
            self = .Six
        default:
            self = .One
        }
    }
}

public class Player {
    var name:String
    public var character:Character?
    
    public init(name:String) {
        self.name = name
    }
}
