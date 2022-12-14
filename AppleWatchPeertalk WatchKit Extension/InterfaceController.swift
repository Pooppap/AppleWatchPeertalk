//
//  InterfaceController.swift
//  AppleWatchPeertalk WatchKit Extension
//
//  Created by Chaiyawan Auepanwiriyakul on 28/07/2022.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    let workoutManager = WorkoutManager()
    let dataManager = DataManager.shared


    override func awake(withContext context: Any?) {
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }

}
