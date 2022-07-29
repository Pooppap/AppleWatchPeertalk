//
//  MotionManager.swift
//  Data Collection Watch App Extension
//
//  Created by Chaiyawan Auepanwiriyakul on 13/01/2018.
//  Copyright © 2018 Imperial College London, National Institute of Health Research. All rights reserved.
//

import Foundation
import CoreMotion

protocol MotionManagerDelegate: class
{
    func didUpdateBackgroundClock(_ manager: MotionManager)
//    func didUpdateDeviceMotion(_ manager: MotionManager, packetStamp: UInt, packetStampMinute: UInt, fileCount: Int)
}

class MotionManager
{
    
    let motionManager = CMMotionManager()
    let deviceQueue = OperationQueue()
    let dataManager = DataManager.shared
    
    weak var delegate: MotionManagerDelegate?

    var tickTracker: UInt = 0
//    var packetStamp: UInt = 0
//    var packetStampMinute: UInt = 0
//    var fileCount: Int = 0
    
    init()
    {
        deviceQueue.maxConcurrentOperationCount = 1
        deviceQueue.name = "DeviceMotionManagerQueue"
    }
    
    func startUpdates()
    {
        if !motionManager.isDeviceMotionAvailable
        {
            print("Device Motion is not available.")
            return
        }
        dataManager.reset()
        motionManager.deviceMotionUpdateInterval = 1.0/60.0
        motionManager.startDeviceMotionUpdates(to: deviceQueue)
        {
            (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil
            {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil
            {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }
    
    func stopUpdates()
    {
        
        if motionManager.isDeviceMotionAvailable
        {
            motionManager.stopDeviceMotionUpdates()
        }
//        dataManager.writeToFile()
//        dataManager.fileHourStamp = 0
    }
    
//    func resetAll()
//    {
//        dataManager.reset()
//        packetStamp = 0
//        packetStampMinute = 0
//        updateDeviceMotionDelegate()
//    }
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion)
    {
        
        dataManager.addMotionData(deviceMotion)
        tickTracker += 1
        
        if tickTracker == 100
        {
            tickTracker = 0
            updateBackgroundClock()
        }
        
//        if dataManager.isMinuteFull() && !dataManager.isFull()
//        {
//            packetStampMinute += 1
//            updateDeviceMotionDelegate()
//            return
//        }
        
//        if !dataManager.isFull()
//        {
//            return
//        }
//        dataManager.writeToFile()
        
//        if dataManager.isFull()
//        {
//            dataManager.writeToFile()
//            packetStamp += 1
//            packetStampMinute = 0
//            fileCount = dataManager.getFileCount()
//            updateDeviceMotionDelegate()
//            print(packetStamp)
//        }
    }
    
    func updateBackgroundClock()
    {
        delegate?.didUpdateBackgroundClock(self)
    }
    
//    func updateDeviceMotionDelegate()
//    {
//        delegate?.didUpdateDeviceMotion(self, packetStamp: packetStamp, packetStampMinute: packetStampMinute, fileCount: fileCount)
//    }
    
}
