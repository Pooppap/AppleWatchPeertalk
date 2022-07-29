//
//  DeviceManager.swift
//  Data Collection Watch App Extension
//
//  Created by Chaiyawan Auepanwiriyakul on 15/01/2018.
//  Copyright © 2018 Imperial College London, National Institute of Health Research. All rights reserved.
//

import Foundation
import CoreMotion
import HealthKit

protocol DeviceManagerDelegate: class
{
    func didUpdateHeartRateAndRotationRate(_ manager: DeviceManager, heartRate: Double, deviceRotationRate: CMRotationRate)
}

class DeviceManager
{
    // WorkoutManager section
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    var heartRateQuery: HKQuery?
    weak var delegate: DeviceManagerDelegate?
    var session: HKWorkoutSession?
    
    //MotionManager section
    
    let motionManager = CMMotionManager()
    let deviceQueue = OperationQueue()
    var deviceRotationRate = CMRotationRate()
    var samplingInterval:Double
    var heartRate = 0
    init(samplingFrequency: Double)
    {
        samplingInterval = 1.0/samplingFrequency
        deviceQueue.maxConcurrentOperationCount = 1
        deviceQueue.name = "DeviceManagerQueue"
    }
}
