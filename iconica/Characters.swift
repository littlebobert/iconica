//
//  Characters.swift
//  iconica
//
//  Created by Justin Garcia on 8/27/14.
//  Copyright (c) 2014 jg. All rights reserved.
//

import Foundation

func friendlyCharacterChooser(originator:Character, allCharacters:Array<Character>) -> Array<Character> {
    var characters = Array<Character>()
    for character in allCharacters {
        if character.player === gameController!.currentPlayer {
            characters.append(character)
        }
    }
    return characters
}

func enemyCharacterChooser(originator:Character, allCharacters:Array<Character>) -> Array<Character> {
    var characters = Array<Character>()
    for character in allCharacters {
        if character.player !== gameController!.currentPlayer {
            characters.append(character)
        }
    }
    return characters
}

func friendlyCharactersFilter(character:Character) -> Bool {
    return character.player === gameController!.currentPlayer
}

func enemyCharactersFilter(character:Character) -> Bool {
    return character.player !== gameController!.currentPlayer
}

public func character45() -> Character {
    var actionElement1 = ActionElement(healing: 30)
    var actionElement2 = ActionElement(damage: 30)
    var action1 = Action(name: "Redeeming Quality", type: .Healing, elements: [actionElement1, actionElement2])
    
    var actionElement3 = ActionElement(action: { (originator:Character, targets:Array<Character>) -> () in
        for target in targets {
            applyBlind(target)
        }
    }, numberOfTargets:.Some(3), start:.ThisTurn)
    var action2 = Action(name: "Glaring Beauty", type: .Status, elements: [actionElement3])
    
    var actionElement4 = ActionElement(action: { originator, targets -> () in
        if countElements(targets) != 1 {
            return
        }
        targets[0].targetable = false
    }, numberOfTargets:.Some(1), start:.NextTurn)
    actionElement4.resolution = { (targets:Array<Character>) -> () in
        let target = targets[0] as Character
        target.targetable = true
    }
    actionElement4.chooser = { (originator, allCharacters) -> Array<Character> in
        for character in allCharacters {
            if character.name == "Wandering Siryn" {
                return [character]
            }
        }
        assert(false, "Should have found Wandering Siryn")
        return []
    }
    
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
    }, numberOfTargets:.Arbitrary, start:.NextTurn)
    actionElement5.resolution = { (targets:Array<Character>) -> () in
        for target in targets {
            if target.gender == .Female {
                target.damageMitigation = nil
            }
        }
    }
    actionElement5.chooser = { (originator, allCharacters) -> Array<Character> in
        var characters = Array<Character>()
        for character in allCharacters {
            if character.gender == .Female {
                characters.append(character)
            }
        }
        return characters
    }
    var action3 = Action(name: "Transfix", type:.Stance, elements: [actionElement4, actionElement5])
    
    var actionElement6 = ActionElement(action: { originator, targets -> () in
        if countElements(targets) != 1 {
            return
        }
        damageCharacter(targets[0], originator, 60)
        gameController!.roll("Fear", {
            if gameController!.die1.toRaw() >= 5 {
                applyFear(targets[0])
            }
        })
    }, numberOfTargets:.Some(1), start: .ThisTurn)
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
        })
    }, numberOfTargets:.Some(1), start: .ThisTurn)
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
    }, numberOfTargets:.Some(2), start:.ThisTurn)
    actionElement9.targetFilter = { (character:Character) in
        return character.gender == .Male
    }
    var actionElement10 = ActionElement(damage: 20)
    var action6 = Action(name: "Siryn Song", type: .Ranged, elements: [actionElement9, actionElement10], actionChoice:.Or)
    
    var reaction2 = Reaction(healthTrigger: 100, damage: 20)
    var reaction3 = Reaction(healthTrigger: 10, damage: 20)
    
    var character = Character(name: "Wandering Siryn", life: 190, race:.Sarion, gender: .Female, classType: .Adaptive, faction: .Independent, actions: [action1, action2, action3, action4, action5, action6], reactions: [reaction2, reaction3])
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
            target.allowedActions = target.allowedActions ^ .Melee
        }, numberOfTargets: .Some(1), start: .NextTurn)
        embeddedActionElement.resolution = { (targets:Array<Character>) -> () in
            let target = targets[0] as Character
            target.allowedActions = target.allowedActions | .Melee
        }
        embeddedActionElement.chooser = { (originator, allCharacters) -> Array<Character> in
            return targets // returns the target of the damage action
        }
        gameController!.actionsForNextTurn.append(embeddedActionElement)
        embeddedActionElement.character = originator
        embeddedActionElement.actionType = .Ranged
        
    }, numberOfTargets: .Some(1), start: .ThisTurn)
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
        }, numberOfTargets:.Some(1), start: .ThisTurn)
    var action2 = Action(name: "Flying Fist", type:.Melee, elements: [actionElement2])
    
    var actionElement3  = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.damageMitigation = { (var damage:Int) -> Int in
                return 0
            }
        }
    }, numberOfTargets:.Some(3), start:.NextTurn)
    actionElement3.resolution = { (targets:Array<Character>) -> () in
        for target in targets {
            target.damageMitigation = nil
        }
    }
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
    }, numberOfTargets:.Arbitrary, start:.NextTurn)
    actionElement6.resolution = { (targets:Array<Character>) -> () in
        for target in targets {
            target.actionTrigger = nil
        }
    }
    actionElement6.chooser = friendlyCharacterChooser
    
    var action5 = Action(name: "Vigilance", type: .Stance, elements: [actionElement6])
    
    var actionElement7 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.fear = false
            target.stun = false
            target.poison = false
            target.confusion = false
            target.blind = false
        }
    }, numberOfTargets:.Arbitrary, start:.ThisTurn)
    actionElement7.chooser = friendlyCharacterChooser
    
    var actionElement8 = ActionElement(action: { originator, targets -> () in
        if targets.count != 1 {
            assert(false, "This should only target a single Character")
            return
        }
        // fixme: perform action #4 on one friendly character if possible
        
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action6 = Action(name: "Inspire Crew", type: .Ranged, elements: [actionElement7, actionElement8])
    
    var reaction1 = Reaction(healthTrigger: 160, damage: 20)
    
    var character = Character(name: "Grynevian Navigator", life: 220, race:.Sidrani, gender:.Male, classType: .Defensive, faction: .Independent, actions: [action1, action2, action3, action4, action5, action6], reactions: [reaction1])
    character.courage = [80, 90, 100, 120, 180, 190, 200, 210]
    character.parry = [40, 110, 170]
    
    return character
}

public func character59() -> Character {
    var actionElement1 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.avoidsNegativeStatusEffects = true
        }
    }, numberOfTargets:.Arbitrary, start:.NextTurn)
    actionElement1.resolution = { (targets:Array<Character>) -> () in
        for target in targets {
            target.avoidsNegativeStatusEffects = false
        }
    }
    actionElement1.chooser = enemyCharacterChooser
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
    }, numberOfTargets:.Some(1), start:.ThisTurn)
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
    }, numberOfTargets: .Some(1), start: .NextTurn)
    actionElement3.resolution = { (targets:Array<Character>) -> () in
        targets[0].damageMitigation = nil
    }
    actionElement3.chooser = { (originator, allCharacters) -> Array<Character> in
        for character in allCharacters {
            if character.name == "Lylean Sentinel" {
                return [character]
            }
        }
        assert(false, "Should have found Lylean Sentinel")
        return []
    }
    var actionElement4 = ActionElement(damage: 30)
    var actionElement5 = ActionElement(action: { originator, targets -> () in
        // fixme: show a picker for targets[0]'s actions
        var resolutionTargets = Array<Targets>()
        var resolutions = Array<Targets -> ()>()
        gameController!.performAction(targets[0].actions[0], resolutions: &resolutions, resolutionTargets: &resolutionTargets)
        gameController!.continueGame()
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    actionElement5.targetFilter = friendlyCharactersFilter
    var action3 = Action(name: "Rynguard's Favor", type: .Stance, elements: [actionElement3, actionElement4, actionElement5])
    
    var actionElement6 = ActionElement(action: { originator, targets -> () in
        for target in targets {
            target.life += 10
            for reaction in target.reactions {
                if reaction.healthTrigger == target.life {
                    var embeddedActionElement = ActionElement(damage: reaction.damage)
                    var embeddedAction = Action(name: "Reprisal", type: .Melee, elements: [embeddedActionElement])
                    embeddedAction.character = target
                    var resolutionTargets = Array<Targets>()
                    var resolutions = Array<Targets -> ()>()
                    gameController!.performAction(embeddedAction, resolutions: &resolutions, resolutionTargets: &resolutionTargets)
                    gameController!.continueGame()
                }
            }
        }
    }, numberOfTargets: .Arbitrary, start: .ThisTurn)
    actionElement6.chooser = friendlyCharacterChooser
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
        
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action5 = Action(name: "Defender's Fury", type: .Melee, elements: [actionElement7])
    
    var actionElement8:ActionElement!
    actionElement8 = ActionElement(action: { originator, targets in
        if targets.count > 1 {
            assert(false, "Action should only have one target")
            return
        }
        let target = targets[0]
        damageCharacter(target, originator, 20, true)
        for reaction in target.reactions {
            if reaction.healthTrigger == target.life {
                applyHealing(originator, reaction.damage)
            }
        }
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action6 = Action(name: "Reactor Shield", type: .Stance, elements: [actionElement8])
    
    var reaction1 = Reaction(healthTrigger: 160, damage: 10)
    var reaction2 = Reaction(healthTrigger: 120, damage: 10)
    var reaction3 = Reaction(healthTrigger: 110, damage: 10)
    
    var character = Character(name: "Lylean Sentinel", life: 190, race:.Sidrani, gender: .Male, classType: .Defensive, faction: .Protectorate, actions: [action1, action2, action3, action4], reactions: [reaction1, reaction2, reaction3])
    character.courage = [20, 30, 60, 90, 100, 130, 140]
    character.parry = [10, 40, 150, 170]
    
    return character
}

func character65() -> Character {
    
    var actionElement1 = ActionElement(action: { originator, targets in
        if targets.count > 1 {
            assert(false, "Should only have one target.")
            return
        }
        let target = targets[0]
        
        // fixme: show a life value chooser
        applyHealing(target, 50)
        damageCharacter(originator, originator, 50)
        
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    actionElement1.chooser = { (originator, allCharacters) -> Array<Character> in
        if originator.charge == nil {
            assert(false, "Guardian should have a charge.")
            return []
        }
        return [originator.charge!]
    }
    var action1 = Action(name: "Sacrifice", type: .Support, elements: [actionElement1])
    
    var actionElement2 = ActionElement(action: { originator, targets in
        applyHealing(originator, 20)
        if originator.charge == nil {
            assert(false, "Guardian should have a charge.")
            return
        }
        applyHealing(originator.charge!, 30)
        
    }, numberOfTargets: .Arbitrary, start: .ThisTurn)
    actionElement2.chooser = { (originator, allCharacters) -> Array<Character> in
        return [originator.charge!]
    }
    var action2 = Action(name: "Solace", type: .Healing, elements: [actionElement2])
    
    var actionElement3 = ActionElement(action: { originator, targets in
        for target in targets {
            target.avoidsActionTypes |= .Ranged
        }
        originator.avoidsActionTypes ^= .Ranged
    }, numberOfTargets: .Arbitrary, start: .NextTurn)
    actionElement3.resolution = { targets in
        for target in targets {
            target.avoidsActionTypes ^= .Ranged
        }
    }
    actionElement3.chooser = friendlyCharacterChooser
    
    var actionElement4 = ActionElement(action: { originator, targets in
        let target = targets[0]
        if target !== originator {
            assert(false, "Target should be the action's originator")
            return
        }
        target.damageApplicator = { attacker, damage in
            target.life -= damage
            attacker.life -= 40
        }
    }, numberOfTargets: .Arbitrary, start: .NextTurn)
    actionElement4.resolution = { targets in
        let target = targets[0]
        target.damageApplicator = nil
    }
    actionElement4.chooser = friendlyCharacterChooser
    var action3 = Action(name: "Draw Fire", type: .Stance, elements: [actionElement3, actionElement4])
    
    var actionElement5 = ActionElement(action: { originator, targets -> () in
        if targets.count != 1 {
            return
        }
        damageCharacter(targets[0], originator, 20)
        
        // create an embedded action element for preventing actions next turn
        var embeddedActionElement = ActionElement(action: { originator, targets -> () in
            let target = targets[0] as Character
            target.allowedActions = .None
            }, numberOfTargets: .Some(1), start: .NextTurn)
        embeddedActionElement.resolution = { (targets:Array<Character>) -> () in
            let target = targets[0] as Character
            // fixme: allow only those actions which were disallowed last turn
            target.allowedActions = .Melee | .Ranged | .Status | .Support | .Healing | .Stance
        }
        embeddedActionElement.chooser = { (originator, allCharacters) -> Array<Character> in
            return targets // returns the target of the damage action
        }
        gameController!.actionsForNextTurn.append(embeddedActionElement)
        embeddedActionElement.character = originator
        embeddedActionElement.actionType = .Melee
        
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var actionElement6 = ActionElement(action: { originator, targets in
        gameController!.roll("Charge’s Action", {
            // perform the target's action
            let roll = gameController!.die1.toRaw()
            if targets[0].actions.count >= roll {
                var resolutionTargets = Array<Targets>()
                var resolutions = Array<Targets -> ()>()
                gameController!.performAction(targets[0].actions[roll-1], resolutions: &resolutions, resolutionTargets: &resolutionTargets)
            }
        })
    }, numberOfTargets: .Arbitrary, start: .ThisTurn)
    actionElement6.chooser = { (originator, allCharacters) -> Array<Character> in
        return [originator.charge!]
    }
    var action4 = Action(name: "Double Team", type: .Melee, elements: [actionElement5, actionElement6])
    
    var actionElement7 = ActionElement(damageWithPoison: 20)
    var action5 = Action(name: "Throwing Spike", type: .Ranged, elements: [actionElement7])
    
    var actionElement8 = ActionElement(damage: 30)
    var actionElement9 = ActionElement(action: { originator, targets in
        // fixme: display a negative status effects picker
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    actionElement9.targetFilter = friendlyCharactersFilter
    var action6 = Action(name: "Protector’s Spear", type: .Melee, elements: [actionElement8, actionElement9])
    
    var reaction1 = Reaction(healthTrigger: 170, damage: 10)
    var reaction2 = Reaction(healthTrigger: 130, damage: 10)
    var reaction3 = Reaction(healthTrigger: 80, damage: 10)
    
    var character = Character(name: "Fangrune Guardian", life: 200, race:.SarajaSarion, gender: .Female, classType: .Protective, faction: .Independent, actions: [action1, action2, action3, action4, action5, action6], reactions: [reaction1, reaction2, reaction3])
    character.parry = [90, 140, 180]
    
    return character
}

func character62() -> Character {
    
    var actionElement1 = ActionElement(action: { originator, targets in
        gameController!.rollTwo("Frostfang Axe", closure: {
            if gameController!.die1.toRaw() % 2 == 1 {
                damageCharacter(targets[0], originator, 30)
            }
            if gameController!.die2.toRaw() % 2 == 1 {
                damageCharacter(targets[0], originator, 30)
            }
        })
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action1 = Action(name: "Frostfang Axe", type: .Melee, elements: [actionElement1])

    var actionElement2 = ActionElement(action: { originator, targets in
        damageCharacter(targets[0], originator, 20)
        applyFear(targets[0])
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var actionElement3 = ActionElement(action: { originator, targets in
        assert(targets[0] === originator, "Originator should be the target.")
        targets[0].avoidsActionTypes |= .Melee | .Ranged
    }, numberOfTargets: .Some(1), start: .NextTurn)
    actionElement3.resolution = { targets in
        targets[0].avoidsActionTypes ^= .Melee | .Ranged
    }
    actionElement3.chooser = { originator, allCharacters in
        return [originator]
    }
    var action2 = Action(name: "Shadow Steel", type: .Status, elements: [actionElement2, actionElement3])
    
    var actionElement4 = ActionElement(action: { originator, targets in
        damageCharacter(targets[0], originator, 30)
        applyPoison(targets[0])
        applyStun(targets[0])
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action3 = Action(name: "Gallowglass", type: .Melee, elements: [actionElement4])

    var actionElement5 = ActionElement(damage: 30)
    var action4 = Action(name: "Black Heap", type: .Melee, elements: [actionElement5])

    var actionElement6 = ActionElement(action: { originator, targets in
        if targets[0].life <= 30 {
            applyStun(targets[0])
        } else {
            damageCharacter(targets[0], originator, 30)
        }
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action5 = Action(name: "Freeze Dry", type: .Melee, elements: [actionElement6])
    
    // fixme: the opponent should choose whether to have one of their Characters take damage or the other player’s healed
    var actionElement7 = ActionElement(damage: 40)
    var actionElement8 = ActionElement(healing: 40)
    var action6 = Action(name: "Blade or Bribe", type: .Melee, elements: [actionElement6, actionElement7], actionChoice:.Or)
    
    var character = Character(name: "Ice Gate Mercenary", life: 180, race:.Sidrani, gender: .Male, classType: .Offensive, faction: .Independent, actions: [action1, action2, action3, action4, action5], reactions: [])
    character.parry = [90]
    character.evasion = [30, 110, 150]
    
    return character
}

func character30() -> Character {
    
    var actionElement1 = ActionElement(action: { originator, targets in
        if targets.count != 1 {
            assert(false, "Action should have exactly one target")
            return
        }
        targets[0].sleep = true
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action1 = Action(name: "Sleeping Gas", type: .Status, elements: [actionElement1])
    
    var actionElement2 = ActionElement(damage: 30)
    var actionElement3 = ActionElement(damage: 10)
    var actionElement4 = ActionElement(damage: 10)
    var action2 = Action(name: "Fire Trap", type: .Melee, elements: [actionElement2, actionElement3, actionElement4])
    
    // fixme: display a picker that lets the attacker distribute this damage
    var actionElement5 = ActionElement(action: { originator, targets in
        gameController!.roll("Tricks of the Trade", closure: {
            let damage = gameController!.die1.toRaw() * 10
            damageCharacter(targets[0], originator, damage)
        })
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action3 = Action(name: "Tricks of the Trade", type: .Stance, elements: [actionElement5])
    
    var actionElement6 = ActionElement(action: { originator, targets in
        if targets.count != 1 {
            assert(false, "Action should target exactly 1 target.")
            return
        }
        applyBlind(targets[0])
        damageCharacter(targets[0], originator, 10)
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action4 = Action(name: "Signal Lamp", type: .Status, elements: [actionElement6])
    
    var actionElement7 = ActionElement(action: { originator, targets in
        if targets.count > 3 {
            assert(false, "Action should target at most 3 targets.")
            return
        }
        for target in targets {
            applyConfusion(target)
            damageCharacter(target, originator, 10)
        }
    }, numberOfTargets: .Some(3), start: .ThisTurn)
    var action5 = Action(name: "Noxious Cloud", type: .Status, elements: [actionElement7])
    
    var actionElement8 = ActionElement(action: { originator, targets in
        if targets.count != 1 {
            assert(false, "Action should target exactly 1 target.")
            return
        }
        applyFear(targets[0])
        gameController!.rollTwo("Ferylide Dagger", closure: {
            if gameController!.die1.toRaw() == gameController!.die2.toRaw() {
                targets[0].life = 0
                targets[0].skulled = true
            }
        })
    }, numberOfTargets: .Some(1), start: .ThisTurn)
    var action6 = Action(name: "Ferylide Dagger", type: .Status, elements: [actionElement8])
    
    var reaction1 = Reaction(healthTrigger: 140, damage: 10)
    var reaction2 = Reaction(healthTrigger: 120, damage: 10)
    
    var character = Character(name: "Pykonian Dark Trader", life: 170, race:.Sarion, gender: .Male, classType: .Disruptive, faction: .Independent, actions: [action1, action2, action3, action4, action5, action6], reactions: [reaction1, reaction2])
    character.focus = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    
    return character
}