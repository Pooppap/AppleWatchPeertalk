//
//  WorkoutManager.swift
//  Data Collection Watch App Extension
//
//  Created by Chaiyawan Auepanwiriyakul on 15/01/2018.
//  Copyright © 2018 Imperial College London, National Institute of Health Research. All rights reserved.
//

import Foundation
import HealthKit
import WatchKit


class WorkoutManager: MotionManagerDelegate
{
    
    let healthStore = HKHealthStore()
    let motionManager = MotionManager()
    let dataManager = DataManager.shared
    let WKBattery = WKInterfaceDevice.current()
    
    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    var heartRateQuery: HKQuery?
    
    let heartBeatUnit = HKUnit.count().unitDivided(by: HKUnit.second())
    let heartBeatSeriesType = HKSeriesType.heartbeat()
    var heartBeatQuery: HKQuery?
    var heartBeatTime = DispatchTime.distantFuture

    var session: HKWorkoutSession?
    var batteryState: WKInterfaceDeviceBatteryState = .unknown
    var backgroundTimer: Timer?
    var heartRate = 0.0
    
    init()
    {
        WKBattery.isBatteryMonitoringEnabled = true
        motionManager.delegate = self
        
        if session != nil
        {
            NSLog("Session is not nil")
            return
        }
        
        let heartRateDataType = Set(arrayLiteral: heartRateQuantityType)

        healthStore.requestAuthorization(toShare: heartRateDataType, read: heartRateDataType) { (success, error) in
            if success == false
            {
                print("Encountered error: \(error!)")
            }
            else
            {
                print("Authorisation success")
            }
        }

        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .indoor
        session = try? HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        
        startBackgroundTimer()
        session?.startActivity(with: Date())
    }

    
    @objc func stateManager()
    {
        let newBatteryState: WKInterfaceDeviceBatteryState = WKBattery.batteryState
        
        if  batteryState != newBatteryState
        {
            switch newBatteryState
            {
                case .unplugged:
                    startCollection()
                case .charging:
                    stopCollection()
                default:
                    ()
            }
        }
        else
        {
            if newBatteryState == .charging || newBatteryState == .full
            {
//                if dataManager.readyToUpload()
//                {
//                    dataManager.uploadToServer()
//                }
                dataManager.uploadTracker += 1
            }
        }
        batteryState = newBatteryState
    }
    
    func startCollection()
    {
        stopBackgroundTimer()
        motionManager.startUpdates()
        heartRateQuery = self.createHeartRateStreamingQuery()
        heartBeatQuery = self.createHeartBeatStreamingQuery()
        healthStore.execute(heartRateQuery!)
        healthStore.execute(heartBeatQuery!)
    }
    
    func stopCollection()
    {
        motionManager.stopUpdates()
        if heartRateQuery != nil
        {
            healthStore.stop(self.heartRateQuery!)
        }
        if heartBeatQuery != nil
        {
            healthStore.stop(self.heartBeatQuery!)
        }
        startBackgroundTimer()
    }
    
    func startBackgroundTimer()
    {
        backgroundTimer = Timer(timeInterval: 1, target: self, selector: #selector(stateManager), userInfo: nil, repeats: true)
        RunLoop.main.add(backgroundTimer!, forMode: RunLoop.Mode.default)
    }
    
    func stopBackgroundTimer()
    {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }
    
    func didUpdateBackgroundClock(_ manager: MotionManager)
    {
        stateManager()
    }
    
    deinit
    {
        if session == nil
        {
            return
        }
        session?.end()
        stopBackgroundTimer()
        session = nil
    }
    
    func createHeartBeatStreamingQuery() -> HKQuery?
    {
        NSLog("Creating heartbeat queue")
        self.heartBeatTime = DispatchTime.now()
        let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictEndDate)
        let heartBeatQuery = HKAnchoredObjectQuery(type: HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!, predicate: datePredicate, anchor: nil, limit: HKObjectQueryNoLimit)
        {
            (heartBeatQuery, heartBeatSamples, heartBeatDeleteds, heartBeatAnchor, error) in
            if error == nil
            {
                self.heartBeatTime = DispatchTime.now()
            }
            else
            {
                print("Encountered error: \(error!)")
            }
        }
        heartBeatQuery.updateHandler =
            {
                (heartBeatQuery, heartBeatSamples, heartBeatDeleteds, heartBeatAnchor, error) -> Void in
                if error == nil
                {
                    self.updateHeartBeat(DispatchTime.now())
                }
                else
                {
                    print("Encountered error: \(error!)")
                }
        }
        return heartBeatQuery
    }
    
    func createHeartRateStreamingQuery() -> HKQuery?
    {
        NSLog("Creating heartrate queue")
        let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictEndDate)
        let heartRateQuery = HKAnchoredObjectQuery(type: self.heartRateQuantityType, predicate: datePredicate, anchor: nil, limit: HKObjectQueryNoLimit)
        {
            (heartRateQuery, heartRateSamples, heartRateDeleteds, heartRateAnchor, error) in
            if error == nil
            {
                self.updateHeartRate(heartRateSamples)
            }
            else
            {
                print("Encountered error: \(error!)")
            }
        }
        heartRateQuery.updateHandler =
            {
                (heartRateQuery, heartRateSamples, heartRateDeleteds, heartRateAnchor, error) -> Void in
                if error == nil
                {
                    self.updateHeartRate(heartRateSamples)
                }
                else
                {
                    print("Encountered error: \(error!)")
                }
        }
        return heartRateQuery
    }
    
    func userAuthorisation()
    {
        let hkTypes: Set<HKSampleType> = Set([
            HKSeriesType.heartbeat(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            ])
        
        healthStore.requestAuthorization(toShare: hkTypes, read: hkTypes) { (success, error) in
            if !success
            {
                NSLog("Authorisation error: \(error!)")
            }
        }
//        let dataTypes: Set<HKSampleType> = Set([
//            HKSeriesType.heartbeat()
//            ])
//        
//        healthStore.requestAuthorization(toShare: dataTypes, read: dataTypes) { (success, error) in
//            if !success
//            {
//                NSLog("Authorisation error: \(error!)")
//            }
//        }
    }

    func updateHeartRate(_ heartRateSamples: [HKSample]?)
    {
        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else
        {
            return
        }
        guard let heartRateSample = heartRateSamples.last?.quantity else
        {
            return
        }
        self.heartRate = heartRateSample.doubleValue(for: self.heartRateUnit)
        dataManager.updateHeartRate(newHeartRate: self.heartRate)
        NSLog("Heart Rate: \(self.heartRate)")
    }
    
    func updateHeartBeat(_ heartBeatEndTime: DispatchTime)
    {
        let nanoTime = heartBeatEndTime.uptimeNanoseconds - self.heartBeatTime.uptimeNanoseconds
        self.heartBeatTime = DispatchTime.now()
        let RR = Double(nanoTime) / 1_000_000_000
//        NSLog("Heart Rate: \(RR)")
    }
    
}
