//
//  ViewController.swift
//  iconica
//
//  Created by Justin Garcia on 8/20/14.
//  Copyright (c) 2014 jg. All rights reserved.
//

import UIKit

class CharacterView : UIView {
    var nameLabel:UILabel
    var lifeLabel:UILabel
    
    override init(frame:CGRect) {
        self.nameLabel = UILabel()
        self.lifeLabel = UILabel()
        super.init(frame:frame)
        
    }
    required init(coder aDecoder: NSCoder) {
        self.nameLabel = UILabel()
        self.lifeLabel = UILabel()
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        self.nameLabel.center = CGPointMake(self.center.x - self.nameLabel.bounds.size.width / 2, self.center.y - self.nameLabel.bounds.size.height)
        self.lifeLabel.center = CGPointMake(self.center.x - self.lifeLabel.bounds.size.width / 2, self.center.y)
    }
}

class CharacterController {
    var character:Character
    var view:CharacterView?
    
    init(character:Character, view:CharacterView?) {
        self.character = character
        self.view = view
    }
}

class ViewController: UIViewController {
    
    var leftCharacterController:CharacterController?
    var rightCharacterController:CharacterController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GCTurnBasedMatchHelper.sharedInstance()?.authenticateLocalUser({ viewController, error in
            if viewController != nil {
                self.presentViewController(viewController, animated: false, completion: {
                    
                })
            } else if error != nil {
                println("There was an error authenticating the local user")
            }
        })
        
        /*
        var player1 = Player(name: "Bobert")
        var player2 = Player(name: "Don")
        
        var character1 = characterOne()
        var character1View = CharacterView(frame:CGRectZero)
        leftCharacterController = CharacterController(character: character1, view: character1View)
        
        var character2 = characterTwo()
        
        GameController(players: [player1, player2])
        
        character1.player = player1
        character2.player = player2
        
        player1.character = character1
        player2.character = character2
        
        gameController!.takeTurn()
*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

