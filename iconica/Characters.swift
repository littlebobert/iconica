//
//  Characters.swift
//  iconica
//
//  Created by Justin Garcia on 8/27/14.
//  Copyright (c) 2014 jg. All rights reserved.
//

import Foundation

public func character45() -> Character {
    var actionElement1 = ActionElement(healing: 30)
    var actionElement2 = ActionElement(damage: 30)
    var action1 = Action(name: "Redeeming Quality", type: .Healing, elements: [actionElement1, actionElement2])
    
    var actionElement3 = ActionElement(action: { (originator:Character, targets:Array<Character>) -> () in
        for target in targets {
            applyBlind(target)
        }
    }, resolution: nil, chooser: nil, numberOfTargets:.Some(3), start:.ThisTurn)
    var action2 = Action(name: "Glaring Beauty", type: .Status, elements: [actionElement3])
    
    var actionElement4 = ActionElement(action: { originator, targets -> () in
        if countElements(targets) != 1 {
            return
        }
        targets[0].targetable = false
    }, resolution: { (targets:Array<Character>) -> () in
        let target = targets[0] as Character
        target.targetable = true
    }, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
        for character in allCharacters {
            if character.name == "Wandering Siryn" {
                return [character]
            }
        }
        assert(false, "Should have found Wandering Siryn")
        return []
    }, numberOfTargets:.Some(1), start:.NextTurn)
    
    var actionElement5 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            if target.gender == Gender.Female {
                target.damageMitigation = { (var damage:Int) -> Int in
                    damage = damage - 20
                    if (damage < 0) {
                        damage = 0
                    }
                    return damage
                }
            }
        }
    }, resolution: { (targets:Array<Character>) -> () in
        for target in targets {
            if target.gender == .Female {
                target.damageMitigation = nil
            }
        }
    }, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
        var characters = Array<Character>()
        for character in allCharacters {
            if character.gender == .Female {
                characters.append(character)
            }
        }
        return characters
    }, numberOfTargets:.Arbitrary, start:.NextTurn)
    var action3 = Action(name: "Transfix", type:.Stance, elements: [actionElement4, actionElement5])
    println("finished creating action: \(action3.elements[0].chooser)")
    
    var actionElement6 = ActionElement(action: { originator, targets -> () in
        if countElements(targets) != 1 {
            return
        }
        damageCharacter(targets[0], originator, 60)
        gameController!.roll("Fear", {
            if gameController!.die1.toRaw() >= 5 {
                applyFear(targets[0])
            }
            gameController!.continueGame()
        })
    }, resolution:nil, chooser:nil, numberOfTargets:.Some(1), start: .ThisTurn)
    var action4 = Action(name: "Backstab", type:.Melee, elements: [actionElement6])
    
    var actionElement7 = ActionElement(action: { originator, targets -> () in
        if countElements(targets) != 1 {
            return
        }
        gameController!.roll("Action", {
            // perform the target's action
            let roll = gameController!.die1.toRaw()
            if targets[0].actions.count >= roll {
                var resolutionTargets = Array<Targets>()
                var resolutions = Array<Targets -> ()>()
                gameController!.performAction(targets[0].actions[roll-1], resolutions: &resolutions, resolutionTargets: &resolutionTargets)
            }
            gameController!.continueGame()
        })
    }, resolution:nil, chooser:nil, numberOfTargets:.Some(1), start: .ThisTurn)
    actionElement7.targetFilter = { (character:Character) in
        return character.gender == .Male
    }
    var actionElement8 = ActionElement(damage: 30)
    var action5 = Action(name: "Irresistible Charm", type:.Support, elements: [actionElement7, actionElement8], actionChoice:.Or)
    
    var actionElement9 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            if target.gender != Gender.Male {
                continue
            }
            
            gameController!.roll("Damage Prevention", closure: {
                let roll = gameController!.die1.toRaw()
                if roll % 2 == 0 {
                    damageCharacter(target, originator, 30)
                }
            })
        }
    }, resolution: nil, chooser: nil, numberOfTargets:.Some(2), start:.ThisTurn)
    actionElement9.targetFilter = { (character:Character) in
        return character.gender == .Male
    }
    var actionElement10 = ActionElement(damage: 20)
    var action6 = Action(name: "Siryn Song", type: .Ranged, elements: [actionElement9, actionElement10], actionChoice:.Or)
    
    var reaction2 = Reaction(healthTrigger: 100, damage: 20)
    var reaction3 = Reaction(healthTrigger: 10, damage: 20)
    
    var character = Character(name: "Wandering Siryn", life: 190, gender: .Female, classType: .Adaptive, faction: .Independent, actions: [action1, action2, action3, action4, action5, action6], reactions: [reaction2, reaction3])
    character.courage = [40, 50, 80, 90]
    character.focus = [170, 180]
    
    return character
}

public func character61() -> Character {
    var actionElement1 = ActionElement(action: { originator, targets -> () in
        if targets.count != 1 {
            return
        }
        damageCharacter(targets[0], originator, 20)
        
        // create an embedded action element for preventing melee actions next turn
        var embeddedActionElement = ActionElement(action: { originator, targets -> () in
            let target = targets[0] as Character
            target.canTakeMeleeAction = false
            }, resolution: { (targets:Array<Character>) -> () in
                let target = targets[0] as Character
                target.canTakeMeleeAction = true
            }, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
                return targets // returns the target of the damage action
            }, numberOfTargets: .Some(1), start: .NextTurn)
        gameController!.actionsForNextTurn.append(embeddedActionElement)
        
        }, resolution: nil, chooser: nil, numberOfTargets: .Some(1), start: .ThisTurn)
    var action1 = Action(name: "Spyscope", type:.Ranged, elements: [actionElement1])
    
    var actionElement2 = ActionElement(action: { originator, targets -> () in
        if countElements(targets) != 1 {
            return
        }
        damageCharacter(targets[0], originator, 30)
        gameController!.roll("Stun", {
            if gameController!.die1.toRaw() % 2 == 1 {
                applyStun(targets[0])
            }
        })
        }, resolution:nil, chooser:nil, numberOfTargets:.Some(1), start: .ThisTurn)
    var action2 = Action(name: "Flying Fist", type:.Melee, elements: [actionElement2])
    
    var actionElement3  = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.damageMitigation = { (var damage:Int) -> Int in
                return 0
            }
        }
        }, resolution: { (targets:Array<Character>) -> () in
            for target in targets {
                target.damageMitigation = nil
            }
        }, chooser: nil, numberOfTargets:.Some(3), start:.NextTurn)
    var action3 = Action(name: "Evasive Maneuvers", type: .Stance, elements: [actionElement3])
    
    var actionElement4 = ActionElement(healing: 20)
    var actionElement5 = ActionElement(damage: 20)
    var action4 = Action(name: "Translator", type: .Healing, elements: [actionElement4, actionElement5])
    
    var actionElement6 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.actionTrigger = ActionTrigger(description: "If you take an action this turn, you will take 20 damage and Fear.", effect: { (triggerTarget:Character) -> () in
                damageCharacter(triggerTarget, originator, 20)
                triggerTarget.fear = true
            })
        }
        }, resolution: { (targets:Array<Character>) -> () in
            for target in targets {
                target.actionTrigger = nil
            }
        }, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
            var targets = Array<Character>()
            for character in allCharacters {
                if character.player === gameController!.currentPlayer {
                    targets.append(character)
                }
            }
            return targets
        }, numberOfTargets:.Arbitrary, start:.NextTurn)
    var action5 = Action(name: "Vigilance", type: .Stance, elements: [actionElement6])
    
    var actionElement7 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.fear = false
            target.stun = false
            target.poison = false
            target.confusion = false
            target.blind = false
        }
    }, resolution: nil, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
        var targets = Array<Character>()
        for character in allCharacters {
            if character.player === gameController!.currentPlayer {
                targets.append(character)
            }
        }
        return targets
    }, numberOfTargets:.Arbitrary, start:.ThisTurn)
    
    var actionElement8 = ActionElement(action: { originator, targets -> () in
        if targets.count != 1 {
            assert(false, "This should only target a single Character")
            return
        }
        // fixme: perform action #4
        
    }, resolution: nil, chooser: nil, numberOfTargets: .Some(1), start: .ThisTurn)
    var action6 = Action(name: "Inspire Crew", type: .Ranged, elements: [actionElement7, actionElement8])
    
    var reaction1 = Reaction(healthTrigger: 160, damage: 20)
    
    var character = Character(name: "Grynevian Navigator", life: 220, gender:.Male, classType: .Defensive, faction: .Independent, actions: [action1, action2, action3, action4, action5, action6], reactions: [reaction1])
    character.courage = [80, 90, 100, 120, 180, 190, 200, 210]
    character.parry = [40, 110, 170]
    
    return character
}

public func character59() -> Character {
    var actionElement1 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.avoidsNegativeStatusEffects = true
        }
    }, resolution: { (targets:Array<Character>) -> () in
        for target in targets {
            target.avoidsNegativeStatusEffects = false
        }
    }, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
        var targets = Array<Character>()
        for character in allCharacters {
            if character.player !== gameController!.currentPlayer {
                targets.append(character)
            }
        }
        return targets
    }, numberOfTargets:.Arbitrary, start:.NextTurn)
    var action1 = Action(name: "Fortify Party Members", type: .Support, elements: [actionElement1])
    
    var actionElement2 = ActionElement(action: { originator, targets -> () in
        if targets.count != 1 {
            assert(false, "Action should have only one target")
            return
        }
        var target = targets[0]
        damageCharacter(target, originator, 20)
        applyFear(target)
        if target.parry != nil {
            for parry in target.parry! {
                if target.life == parry {
                    damageCharacter(target, originator, 30)
                }
            }
        }
    }, resolution: nil, chooser: nil, numberOfTargets:.Some(1), start:.ThisTurn)
    var action2 = Action(name: "Lance of Light", type: .Melee, elements: [actionElement2])
    
    var actionElement3 = ActionElement(action: { originator, targets -> () in
        if targets.count != 1 {
            assert(false, "Action should have only one target.")
            return
        }
        let target = targets[0]
        if target.name != "Lylean Sentinel" {
            assert(false, "Action targets self.")
            return
        }
        target.damageMitigation = { (var damage:Int) -> Int in
            return 0
        }
    }, resolution: { (targets:Array<Character>) -> () in
        targets[0].damageMitigation = nil
    }, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
        for character in allCharacters {
            if character.name == "Lylean Sentinel" {
                return [character]
            }
        }
        assert(false, "Should have found Lylean Sentinel")
        return []
    }, numberOfTargets: .Some(1), start: .NextTurn)
    var actionElement4 = ActionElement(damage: 30)
    var actionElement5 = ActionElement(action: { originator, targets -> () in
        // fixme: show a picker for targets[0] actions
        var resolutionTargets = Array<Targets>()
        var resolutions = Array<Targets -> ()>()
        gameController!.performAction(targets[0].actions[0], resolutions: &resolutions, resolutionTargets: &resolutionTargets)
        gameController!.continueGame()
    }, resolution: nil, chooser: nil, numberOfTargets: .Some(1), start: .ThisTurn)
    actionElement5.targetFilter = { (character:Character) -> Bool in
        return character.player === gameController!.currentPlayer
    }
    var action3 = Action(name: "Rynguard's Favor", type: .Stance, elements: [actionElement3, actionElement4, actionElement5])
    
    var actionElement6 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.life += 10
            for reaction in target.reactions {
                if reaction.healthTrigger == target.life {
                    var embeddedActionElement = ActionElement(damage: reaction.damage)
                    var embeddedAction = Action(name: "Reprisal", type: .Melee, elements: [embeddedActionElement])
                    var resolutionTargets = Array<Targets>()
                    var resolutions = Array<Targets -> ()>()
                    gameController!.performAction(embeddedAction, resolutions: &resolutions, resolutionTargets: &resolutionTargets)
                    gameController!.continueGame()
                }
            }
        }
    }, resolution: nil, chooser: { (allCharacters:Array<Character>) -> Array<Character> in
        var alliedCharacters = Array<Character>()
        for character in allCharacters {
            if character.player === gameController!.currentPlayer {
                alliedCharacters.append(character)
            }
        }
        return alliedCharacters
    }, numberOfTargets: .Arbitrary, start: .ThisTurn)
    var action4 = Action(name: "Lightwave", type: .Support, elements: [actionElement6])
    
    var actionElement7 = ActionElement(action: { originator, targets -> () in
        if targets.count > 1 {
            assert(false, "Action should only have one target")
            return
        }
        
        var closure: (() -> ())!
        closure = {
            if gameController!.die1.toRaw() >= 3 {
                damageCharacter(targets[0], originator, 10)
                // fixme: pick a new target
                gameController!.roll("Defender's Fury", closure: closure)
            }
        }
        gameController!.roll("Defender's Fury", closure: closure)
        
    }, resolution: nil, chooser: nil, numberOfTargets: .Some(1), start: .ThisTurn)
    var action5 = Action(name: "Defender's Fury", type: .Melee, elements: [actionElement7])
    
    var actionElement8:ActionElement!
    actionElement8 = ActionElement(action: { originator, targets in
        if targets.count > 1 {
            assert(false, "Action should only have one target")
            return
        }
        let target = targets[0]
        damageCharacter(target, originator, 20, false)
        for reaction in target.reactions {
            if reaction.healthTrigger == target.life {
                applyHealing(originator, reaction.damage)
            }
        }
    }, resolution: nil, chooser: nil, numberOfTargets: .Some(1), start: .ThisTurn)
    var action6 = Action(name: "Reactor Shield", type: .Stance, elements: [actionElement8])
    
    var reaction1 = Reaction(healthTrigger: 160, damage: 10)
    var reaction2 = Reaction(healthTrigger: 120, damage: 10)
    var reaction3 = Reaction(healthTrigger: 110, damage: 10)
    
    var character = Character(name: "Lylean Sentinel", life: 190, gender: .Male, classType: .Defensive, faction: .Protectorate, actions: [action1, action2, action3, action4], reactions: [reaction1, reaction2, reaction3])
    character.courage = [20, 30, 60, 90, 100, 130, 140]
    character.parry = [10, 40, 150, 170]
    
    return character
}