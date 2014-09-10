//
//  GCTurnBasedMatchHelper.swift
//  iconica
//
//  Created by Justin Garcia on 9/10/14.
//  Copyright (c) 2014 jg. All rights reserved.
//

import UIKit
import GameKit
import Foundation

var gSharedInstance:GCTurnBasedMatchHelper?

class GCTurnBasedMatchHelper: NSObject {
    var gameCenterAvailable:Bool
    var userAuthenticated:Bool
    
    override init() {
        self.gameCenterAvailable = false
        self.userAuthenticated = false
        super.init()
        self.gameCenterAvailable = isGameCenterAvailable()
        if self.gameCenterAvailable {
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector:Selector("authenticationChanged"),
                name:GKPlayerAuthenticationDidChangeNotificationName,
                object:nil)
        }
        gSharedInstance = self
    }
    
    class func sharedInstance() -> GCTurnBasedMatchHelper? {
        if gSharedInstance == nil {
            gSharedInstance = GCTurnBasedMatchHelper()
        }
        return gSharedInstance
    }
    
    func authenticateLocalUser(authenticateHandler:((UIViewController!, NSError!) -> ())) {
        if !gameCenterAvailable {
            return
        }
        
        println("Authenticating local user...")
        if GKLocalPlayer.localPlayer().authenticated == false {
            GKLocalPlayer.localPlayer().authenticateHandler = authenticateHandler
        } else {
            println("Already athenticated.")
        }
    }
    
    func authenticationChanged() {
        if GKLocalPlayer.localPlayer().authenticated && !self.userAuthenticated {
            println("Athentication changed: player authenticated")
            self.userAuthenticated = true
        } else if !GKLocalPlayer.localPlayer().authenticated && self.userAuthenticated {
            println("Athentication changed: player not authenticated")
            self.userAuthenticated = false
        }
    }
    
    func isGameCenterAvailable() -> Bool {
        var player:GKLocalPlayer? = GKLocalPlayer()
        
        var currentSystemVersion = UIDevice.currentDevice().systemVersion
        var requiredSystemVersion = "4.1"
        
        return player != nil
    }
}
