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
    
    func numberOfDice() -> Int {
        return 1
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        self.rollClosure()
        gameController!.continueGame()
    }
    
    func message() -> String {
        return "You rolled a \(gameController!.die1.toRaw())."
    }
}

public class RollTwoDelegate : RollDelegate {
    override func numberOfDice() -> Int {
        return 2
    }
    
    override func message() -> String {
        return "You rolled a \(gameController!.die1.toRaw()) and a \(gameController!.die2.toRaw())."
    }
}

public struct TestRoll {
    public var msg:String
    var die1Value:Int
    var die2Value:Int?
    
    public init(msg:String, die1Value:Int) {
        self.msg = msg
        self.die1Value = die1Value
    }
    
    public init(msg:String, die1Value:Int, die2Value:Int) {
        self.msg = msg
        self.die1Value = die1Value
        self.die2Value = die2Value
    }
}

public class GameController : NSObject {
    
    var currentPlayer:Player
    var players:Array<Player>
    var turn:Int
    var die1:Die
    var die2:Die
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
        self.die2 = Die()
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
        self.die2 = Die()
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
        var alert = UIAlertView(title: self.rollDelegate!.message(), message: "", delegate:rollDelegate, cancelButtonTitle: "OK")
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
    
    func rollTwo(msg:String, closure:(() -> ())?) {
        if self.testRolls != nil {
            var testRoll = self.testRolls![0]
            assert(testRoll.msg == msg, "The roll message was incorrect")
            if let die1Value = Die.fromRaw(testRoll.die1Value) {
                self.die1 = die1Value
            } else {
                assert(false, "The die roll should convert into a Die")
            }
            assert(testRoll.die2Value != nil, "Test roll should have a second die roll")
            if let die2Value = Die.fromRaw(testRoll.die2Value!) {
                self.die2 = die2Value
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
            self.rollDelegate = RollTwoDelegate(rollClosure:closure!)
        }
        var alert = UIAlertView(title: "Roll for \(msg)", message: "", delegate:self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func performActionElement(element:ActionElement, inout resolutions:Array<Targets -> ()>, inout resolutionTargets:Array<Targets>) {
        
        // fixme: display UI showing off this ActionElement
        var targets: Targets
        if element.chooser != nil {
            let originator = element.parentAction != nil ? element.parentAction!.character! : element.character
            targets = element.chooser!(originator!, self.allCharacters())
        } else {
            if self.testTargets != nil {
                targets = self.testTargets![0]
                self.testTargets!.removeAtIndex(0)
            } else {
                // fixme: display Character picker (for element.numberOfTargets Characters)
                // fixme: only show the Character picker for Characters that pass .targetFilter
                // fixme: only show the Character picker for Characters that don't .avoidsActionTypes
                if self.currentPlayer === self.players[0] {
                    targets = [self.players[1].character!]
                } else {
                    targets = [self.players[0].character!]
                }
            }
        }
        element.action(self.currentPlayer.character!, targets)
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
                } else if element.start == .TurnAfterNext {
                    self.actionsForTurnAfterNext.append(element)
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
                } else if element.start == .TurnAfterNext {
                    self.actionsForTurnAfterNext.append(element)
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
            
            if self.currentPlayer.character!.allowedActions & action.type {
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

public struct ActionTypes : RawOptionSetType, BooleanType {
    private var value: UInt = 0
    
    init(_ value: UInt) {
        self.value = value
    }
    
    public static func fromMask(raw: UInt) -> ActionTypes {
        return self(raw)
    }
    
    public static func fromRaw(raw: UInt) -> ActionTypes? {
        return self(raw)
    }
    
    public func toRaw() -> UInt {
        return value
    }
    
    public var boolValue: Bool {
        return value != 0
    }
    
    public static var allZeros: ActionTypes {
        return self(0)
    }
    
    public static func convertFromNilLiteral() -> ActionTypes {
        return self(0)
    }
    
    static var None: ActionTypes        { return self(0b000000) }
    static var Melee: ActionTypes       { return self(0b000001) }
    static var Ranged: ActionTypes      { return self(0b000010) }
    static var Status: ActionTypes      { return self(0b000100) }
    static var Support: ActionTypes     { return self(0b001000) }
    static var Healing: ActionTypes     { return self(0b010000) }
    static var Stance: ActionTypes      { return self(0b100000) }
}

public enum ActionChoice {
    case And, Or
}

public class Action {
    var name:String
    public var elements:Array<ActionElement>
    var type:ActionTypes
    var actionChoice:ActionChoice
    public var character:Character?
    
    init(name:String, type:ActionTypes, elements:Array<ActionElement>, actionChoice:ActionChoice) {
        self.name = name
        self.type = type
        self.elements = elements
        self.actionChoice = actionChoice
        for element in self.elements {
            element.parentAction = self
        }
    }
    
    convenience init(name:String, type:ActionTypes, elements:Array<ActionElement>) {
        self.init(name:name, type:type, elements:elements, actionChoice:.And)
    }
}

public func damageCharacter(character:Character, attacker:Character, var damage:Int, skipReaction:Bool) {
    if character.targetable == false {
        assert(false, "Should not be able to target an untargetable Character")
        return
    }
    
    if character.damageMitigation != nil {
        damage = character.damageMitigation!(damage)
    }
    
    if character.damageApplicator != nil {
        character.damageApplicator!(attacker, damage)
    } else {
        character.life -= damage
    }
    
    if skipReaction == false {
        for reaction in character.reactions {
            if reaction.healthTrigger == character.life {
                damageCharacter(character, attacker, reaction.damage)
            }
        }
    }
}

public func damageCharacter(character:Character, attacker:Character, var damage:Int) {
    damageCharacter(character, attacker, damage, false)
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

public func applyHealing(character:Character, healing:Int) {
    character.life += healing
    if character.life > character.maxLife {
        character.life = character.maxLife
    }
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
    var action:(Character, Array<Character>) -> ()
    var numberOfTargets:NumberOfTargets
    var resolution:(Array<Character> -> ())?
    public var chooser:((Character, Array<Character>) -> Array<Character>)?
    var targetFilter:(Character -> Bool)?
    var start:Turn
    public var parentAction:Action?
    
    // for embedded ActionElements that have no parent Action
    public var character:Character?
    public var actionType:ActionTypes?
    
    init(var damage:Int) {
        self.action = {originator, targets -> () in
            if countElements(targets) != 1 {
                return
            }
            
            damageCharacter(targets[0], originator, damage)
        }
        self.numberOfTargets = .Some(1)
        self.start = .ThisTurn
    }
    
    init(healing:Int) {
        self.action = { originator, targets -> () in
            if countElements(targets) != 1 {
                return
            }
            applyHealing(targets[0], healing)
        }
        self.numberOfTargets = .Some(1)
        self.start = .ThisTurn
    }
    init(damageWithPoison:Int) {
        self.action = { originator, targets -> () in
            if countElements(targets) != 1 {
                return
            }
            damageCharacter(targets[0], originator, damageWithPoison)
            applyPoison(targets[0])
        }
        self.numberOfTargets = .Some(1)
        self.start = .ThisTurn
    }
    
    init(action:((Character, Array<Character>) -> ()), numberOfTargets:NumberOfTargets, start:Turn) {
        self.action = action
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
    case Offensive, Defensive, Adaptive, Disruptive, Supportive, Protective
}

public class Character {
    public var name:String
    public var life:Int
    public var maxLife:Int
    var classType:Class
    var faction:Faction
    public var actions:Array<Action>
    var reactions:Array<Reaction>
    public var damageMitigation:(Int -> Int)?
    var gender:Gender
    public var targetable:Bool
    var poison:Bool
    public var fear:Bool
    public var stun:Bool
    var confusion:Bool
    var blind:Bool
    var restoration:Bool
    public var actionTrigger:ActionTrigger?
    public var player:Player?
    var avoidsNegativeStatusEffects:Bool
    public var parry:Array<Int>?
    var evasion:Array<Int>?
    var antidote:Array<Int>?
    var courage:Array<Int>?
    var focus:Array<Int>?
    public var charge:Character?
    public var damageApplicator:((Character, Int) -> ())?
    public var allowedActions:ActionTypes
    public var avoidsActionTypes:ActionTypes
    
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
        self.avoidsNegativeStatusEffects = false
        self.allowedActions = .Melee | .Ranged | .Status | .Healing | .Support | .Stance
        self.avoidsActionTypes = .None
        
        for action in self.actions {
            action.character = self
        }
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
    public var name:String
    public var character:Character?
    
    public init(name:String) {
        self.name = name
    }
}
