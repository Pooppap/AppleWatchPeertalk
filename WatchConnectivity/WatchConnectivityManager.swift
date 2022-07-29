//
//  WatchConnectivityManager.swift
//  AppleWatchPeertalk
//
//  Created by Chaiyawan Auepanwiriyakul on 28/07/2022.
//
#if os(iOS)
import Peertalk
#endif
import Foundation
import WatchConnectivity

#if os(iOS)
struct Settings {
    static let port: in_port_t = 50444
}
enum Frame: UInt32 {
    case deviceInfo = 100
    case message = 101
    case ping = 102
    case pong = 103
}
#endif

struct NotificationMessage: Identifiable {
    let id = UUID()
    let text: String
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    @Published var notificationMessage: NotificationMessage? = nil
    
    #if os(iOS)
    var hasConnection: Bool = false
    private var serverChannel: PTChannel?
    private var peerChannel: PTChannel?
    #endif
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        #if os(iOS)
        let channel = PTChannel(protocol: nil, delegate: self)
        channel.listen(on: Settings.port, IPv4Address: INADDR_LOOPBACK) { error in
            if let error = error {
                NSLog("Failed to listen on 127.0.0.1:\(Settings.port) \(error)")
            } else {
                NSLog("Listening on 127.0.0.1:\(Settings.port)")
                self.serverChannel = channel
            }
        }
        #endif
    }
    
    private let kMessageKey = "message"
    private let kPayloadKey = "payload"
    
    func send(_ message: String) {
        guard WCSession.default.activationState == .activated else {
          return
        }
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
        #else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
        #endif
        
        WCSession.default.sendMessage([kMessageKey : message], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
    
    func send(_ payload: Data) {
        guard WCSession.default.activationState == .activated else {
          return
        }
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
        #else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
        #endif
        
        WCSession.default.sendMessage([kPayloadKey : payload], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
    
    #if os(iOS)
    func upload(payload: Data){
//        NSLog("payload upload")
        if let peerChannel = peerChannel {
            peerChannel.sendFrame(type: Frame.message.rawValue, tag: 0, payload: payload, callback: nil)
        } else {
            NSLog("Cannot send message - not connected")
        }
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    @objc func heartBeat() {
        if self.hasConnection {
            var message = self.randomString(length: 5)
            let payload = message.withUTF8 { buffer -> Data in
                var data = Data()
                data.append(CFSwapInt32HostToBig(UInt32(buffer.count)).data)
                data.append(buffer)
                return data
            }
            NSLog(message)
            self.upload(payload: payload)
        }
    }
    #endif
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if (message[kMessageKey] != nil) {
            if let notificationText = message[kMessageKey] as? String {
                DispatchQueue.main.async { [weak self] in
                    self?.notificationMessage = NotificationMessage(text: notificationText)
                }
            }
        }
        #if os(iOS)
        if (message[kPayloadKey] != nil) {
            if self.hasConnection {
                if let payload = message[kPayloadKey] as? Data {
                    DispatchQueue.main.async { [weak self] in
    //                    NSLog(self!.kPayloadKey)
                        self?.upload(payload: payload)
                    }
//                    self.upload(payload: payload)
                }
            }
            else {
                NSLog(self.kPayloadKey)
            }
        }
        #endif
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

#if os(iOS)
extension WatchConnectivityManager: PTChannelDelegate {
    func channel(_ channel: PTChannel, didRecieveFrame type: UInt32, tag: UInt32, payload: Data?) {
        if let type = Frame(rawValue: type) {
            switch type {
            case .message:
                guard let payload = payload else {
                    return
                }
                payload.withUnsafeBytes { buffer in
                    let textBytes = buffer[(buffer.startIndex + MemoryLayout<UInt32>.size)...]
                    if let message = String(bytes: textBytes, encoding: .utf8) {
                        NSLog("[\(channel.userInfo)] \(message)")
                    }
                }
            case .ping:
                peerChannel?.sendFrame(type: Frame.pong.rawValue, tag: 0, payload: nil, callback: nil)
            default:
                break
            }
        }
    }

    func channel(_ channel: PTChannel, shouldAcceptFrame type: UInt32, tag: UInt32, payloadSize: UInt32) -> Bool {
        guard channel == peerChannel else {
            return false
        }
        guard let frame = Frame(rawValue: type),
                    frame == .ping || frame == .message else {
            print("Unexpected frame of type: \(type)")
            return false
        }
            return true
    }

    func channel(_ channel: PTChannel, didAcceptConnection otherChannel: PTChannel, from address: PTAddress) {
        peerChannel?.cancel()
        peerChannel = otherChannel
        peerChannel?.userInfo = address
        hasConnection = true
        NSLog("Connected to \(address)")
    }

    func channelDidEnd(_ channel: PTChannel, error: Error?) {
        if let error = error {
            NSLog("\(channel) ended with \(error)")
        } else {
            NSLog("Disconnected from \(channel.userInfo)")
        }
    }
}

extension FixedWidthInteger {
    var data: Data {
        var bytes = self
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: self))
    }
}
#endif
