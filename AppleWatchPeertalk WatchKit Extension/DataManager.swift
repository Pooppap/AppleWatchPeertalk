//
//  DataBuffer.swift
//  Data Collection Watch App Extension
//
//  Created by Chaiyawan Auepanwiriyakul on 30/04/2018.
//  Copyright © 2018 Imperial College London, National Institute of Health Research. All rights reserved.
//

//import WatchKit
import Foundation
import CoreMotion

final class DataManager
{
    
    static let shared = DataManager()
    // static let uploadSession = URLSession(configuration: .ephemeral)
//    static let uploadSession = URLSession(
//        configuration: .ephemeral,
//        delegate: NSURLSessionPinningDelegate(),
//        delegateQueue: nil)
    static let defaults = UserDefaults.standard
//    static let bufferSize = ((8 * 11)) * 100 * 60 * 5
    //    static let bufferMinute = ((8 * 13) + 1) * 100 * 60
//    static let mainFileName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    static var dataBuffer = Data()
//    static var toWriteFileStamp = 0
//    static var toUploadFileStamp = 0
    
    let watchConnectivityManager = WatchConnectivityManager.shared
    
    var uploadTracker = 0
    var heartRate = 0.0
    var appUUID: String = "nil"
    
//    private var writeBuffer = Data()
//    private var fileName: URL
//    private var logFileName: URL
//    private var uploadRequest: URLRequest
    
    private init()
    {
        if !DataManager.defaults.bool(forKey: "appLaunched")
        {
            appUUID = UUID().uuidString
            DataManager.defaults.set(appUUID, forKey: "appUUID")
            DataManager.defaults.set(true, forKey: "appLaunched")
        }
        
//        DataManager.toWriteFileStamp = DataManager.defaults.integer(forKey: "toWriteFileStamp")
//        DataManager.toUploadFileStamp = DataManager.defaults.integer(forKey: "toUploadFileStamp")
        
        appUUID = DataManager.defaults.string(forKey: "appUUID")!
//        fileName = DataManager.mainFileName.appendingPathComponent(appUUID + ".bin")
//        logFileName = DataManager.mainFileName.appendingPathComponent(appUUID + ".log")
//        uploadRequest = URLRequest(url: URL(string: "https://192.168.100.2:5000/upload")!)
//        uploadRequest.httpMethod = "POST"
//        uploadRequest.setValue("raw-data", forHTTPHeaderField: "Content-Type")
//        uploadRequest.setValue("filename=\"\(appUUID)\"", forHTTPHeaderField: "Content-Disposition")
    }
    
    func addMotionData(_ sample: CMDeviceMotion)
    {

        DataManager.dataBuffer.append(Date().ticks.data)
        DataManager.dataBuffer.append(sample.rotationRate.x.data)
        DataManager.dataBuffer.append(sample.rotationRate.y.data)
        DataManager.dataBuffer.append(sample.rotationRate.z.data)
        DataManager.dataBuffer.append(sample.attitude.roll.data)
        DataManager.dataBuffer.append(sample.attitude.pitch.data)
        DataManager.dataBuffer.append(sample.attitude.yaw.data)
        DataManager.dataBuffer.append(sample.userAcceleration.x.data)
        DataManager.dataBuffer.append(sample.userAcceleration.y.data)
        DataManager.dataBuffer.append(sample.userAcceleration.z.data)
//        DataManager.dataBuffer.append(sample.gravity.x.data)
//        DataManager.dataBuffer.append(sample.gravity.y.data)
//        DataManager.dataBuffer.append(sample.gravity.z.data)
        DataManager.dataBuffer.append(self.heartRate.data)

        //        DataManager.dataBuffer.append(sample.magneticField.field.x.data)
        //        DataManager.dataBuffer.append(sample.magneticField.field.y.data)
        //        DataManager.dataBuffer.append(sample.magneticField.field.z.data)
        //        DataManager.dataBuffer.append(Int8(sample.magneticField.accuracy.rawValue).data)
        self.sendData()
    }
    
    func sendData()
    {
        watchConnectivityManager.send(DataManager.dataBuffer)
        self.removeData()
        
    }
    
    //    func isMinuteFull() -> Bool
    //    {
    //        return Int(DataManager.dataBuffer.count % DataManager.bufferMinute) == 0
    //    }
    
//    func isFull() -> Bool
//    {
//        return DataManager.bufferSize == DataManager.dataBuffer.count
//    }
    
    func removeData()
    {
        DataManager.dataBuffer.removeAll()
    }
    
//    func readyToUpload() -> Bool
//    {
//        // upload stamp out of range
//        if DataManager.toUploadFileStamp >= DataManager.toWriteFileStamp
//        {
//            DataManager.defaults.set(true, forKey: "allUploaded")
//            DataManager.toUploadFileStamp = 0
//            DataManager.toWriteFileStamp = 0
//            DataManager.defaults.set(DataManager.toUploadFileStamp, forKey: "toUploadFileStamp")
//            DataManager.defaults.set(DataManager.toWriteFileStamp, forKey: "toWriteFileStamp")
//            return false
//        }
//
//        let fileToCheck = fileName.appendingPathExtension(String(DataManager.toUploadFileStamp))
//
//        if !FileManager.default.fileExists(atPath: fileToCheck.path) {
//            DataManager.toUploadFileStamp += 1
//            DataManager.defaults.set(DataManager.toUploadFileStamp, forKey: "toUploadFileStamp")
//            return false
//        }
//
//        //** WHY uploadTracker % 60 == 0
//        return (uploadTracker % 60 == 0 && !DataManager.defaults.bool(forKey: "allUploaded"))
//    }
    
    func reset()
    {
        removeData()
        uploadTracker = 0
        if DataManager.defaults.bool(forKey: "allUploaded")
        {
            DataManager.defaults.set(false, forKey: "allUploaded")
        }
        //        fileHourStamp = 0
    }
    
//    func writeToFile()
//    {
//        writeBuffer.removeAll()
//        writeBuffer = DataManager.dataBuffer
//        removeData()
//        let fileToWrite = fileName.appendingPathExtension(String(DataManager.toWriteFileStamp))
//
//        //***************************** code improvement
//        for _ in 1...10
//        {
//            do
//            {
//                // try? String("Try writing: \(writeChance)\n").appendLine(to: logFileName)
//                try writeBuffer.write(to: fileToWrite)
//                break
//            }
//            catch
//            {
//                // try? String("Failing at: \(writeChance)\n").appendLine(to: logFileName)
//                continue
//            }
//        }
//        DataManager.toWriteFileStamp += 1
//        DataManager.defaults.set(DataManager.toWriteFileStamp, forKey: "toWriteFileStamp")
//        // try? String("Writing: \(DataManager.toWriteFileStamp)\n").appendLine(to: logFileName)
//        //        fileHourStamp += 1
//    }
    
    //    func getFileCount() -> Int
    //    {
    //        let fileAttr = try? FileManager.default.contentsOfDirectory(atPath: DataManager.mainFileName.path)
    //        return (fileAttr?.count)!
    //    }
    
//    func readLogFile() -> String?
//    {
//        return try? String(contentsOf: logFileName, encoding: .utf8)
//    }
//
//    func uploadToServer()
//    {
//        let fileToUpload = fileName.appendingPathExtension(String(DataManager.toUploadFileStamp))
//
//        uploadRequest.setValue("filename=\"\(appUUID).\(DataManager.toUploadFileStamp).\(DataManager.toWriteFileStamp)\"", forHTTPHeaderField: "Content-Disposition")
//        // try? String("\(appUUID).\(DataManager.toUploadFileStamp).\(DataManager.toWriteFileStamp)").appendLine(to: logFileName)
//        NSLog("Sending: \(appUUID).\(DataManager.toUploadFileStamp).\(DataManager.toWriteFileStamp)")
////        try? String("Sending: \(DataManager.toUploadFileStamp)\n").appendLine(to: logFileName)
//        //        NSLog("Sending: \(DataManager.toUploadFileStamp)")
//        let uploadTask = DataManager.uploadSession.uploadTask(with: uploadRequest, fromFile: fileToUpload, completionHandler:
//        {
//            (serverData: Data?, serverResponse: URLResponse?, clientError: Error?) -> Void in
//
//
//            if clientError != nil
//            {
//                return
//            }
//
//            guard let serverResponse = serverResponse as? HTTPURLResponse,
//                (200...299).contains(serverResponse.statusCode) else
//            {
//                return
//            }
//
//            let receiveFileStamp = Int(serverData!.toString())
//            NSLog(String("Received: \(String(describing: receiveFileStamp))\n"))
//
//            if receiveFileStamp == DataManager.toUploadFileStamp
//            {
//                // try? FileManager.default.removeItem(at: self.fileName.appendingPathExtension(String(DataManager.toUploadFileStamp)))
//
//                for _ in 1...10
//                {
//                    do
//                    {
//                        try FileManager.default.removeItem(at: self.fileName.appendingPathExtension(String(DataManager.toUploadFileStamp)))
//                        break
//                    }
//                    catch
//                    {
//                        continue
//                    }
//                }
//
//
//                // try? String("Finishing: \(DataManager.toUploadFileStamp)/\(DataManager.toWriteFileStamp)\n").appendLine(to: self.logFileName)
//                //            NSLog("Finishing: \(DataManager.toUploadFileStamp)/\(DataManager.toWriteFileStamp)")
//
//                DataManager.toUploadFileStamp += 1
//                DataManager.defaults.set(DataManager.toUploadFileStamp, forKey: "toUploadFileStamp")
//            }
//
//            self.uploadTracker = 59
//
//            if DataManager.toUploadFileStamp == DataManager.toWriteFileStamp
//            {
//                DataManager.defaults.set(true, forKey: "allUploaded")
//                DataManager.toUploadFileStamp = 0
//                DataManager.toWriteFileStamp = 0
//                DataManager.defaults.set(DataManager.toUploadFileStamp, forKey: "toUploadFileStamp")
//                DataManager.defaults.set(DataManager.toWriteFileStamp, forKey: "toWriteFileStamp")
//                return
//            }
//
//        })
//        uploadTask.resume()
//        //uploadTracker = 0
//    }
    
    func updateHeartRate(newHeartRate: Double){
        self.heartRate = newHeartRate
    }
    
    //** when does this piece of code execute?
    deinit
    {
//        writeToFile()
//        uploadToServer()
//        DataManager.uploadSession.finishTasksAndInvalidate()
    }
    
}

protocol DataConvertible
{
    init?(data: Data)
    var data: Data { get }
}

extension UInt64 : DataConvertible { }
//extension UInt32 : DataConvertible { }
extension Double : DataConvertible { }
//extension Float : DataConvertible { }
extension Int8 : DataConvertible { }

//extension Double
//{
//    func roundedTo(places: Int) -> Double
//    {
//        let divisor = pow(10.0, Double(places))
//        return (self * divisor).rounded() / divisor
//    }
//
//}

extension DataConvertible where Self: ExpressibleByIntegerLiteral
{
    init?(data: Data)
    {
        var value: Self = 0
        guard data.count == MemoryLayout.size(ofValue: value) else { return nil }
        _ = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)})
        self = value
    }
    var data: Data
    {
        return withUnsafeBytes(of: self, {Data($0)})
    }
}

extension Date
{
    var ticks: UInt64
    {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}

extension String
{
    func appendLine(to url: URL) throws
    {
        try self.appending("\n").append(to: url)
    }
    func append(to url: URL) throws
    {
        let data = self.data(using: String.Encoding.utf8)
        try data?.appendString(to: url)
    }
}

extension Data
{
    func appendString(to url: URL) throws
    {
        if let fileHandle = try? FileHandle(forWritingTo: url)
        {
            defer
            {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else
        {
            try write(to: url)
        }
    }
    
    func toString() -> String
    {
        return String(data: self, encoding: .utf8)!
    }
}

//class NSURLSessionPinningDelegate: NSObject, URLSessionDelegate
//{
//
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void)
//    {
//        
//        // NSLog("Checking certificate\n")
//
//        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
//        {
//            if let serverTrust = challenge.protectionSpace.serverTrust
//            {
//                let status = SecTrustEvaluateWithError(serverTrust, nil)
//
//                if(status)
//                {
//                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
//                    {
//                        let serverCertificateData = SecCertificateCopyData(serverCertificate)
//                        let data = CFDataGetBytePtr(serverCertificateData);
//                        let size = CFDataGetLength(serverCertificateData);
//                        let cert1 = NSData(bytes: data, length: size)
//                        let file_der = Bundle.main.path(forResource: "flask-cert", ofType: "der")
//                        
//                        if let file = file_der
//                        {
//                            if let cert2 = NSData(contentsOfFile: file)
//                            {
//                                if cert1.isEqual(to: cert2 as Data)
//                                {
//                                    // NSLog("Certificate trusted\n")
//                                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
//                                    return
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//
//        // Pinning failed
//        NSLog("Pining failed\n")
//        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
//    }
//
//}
