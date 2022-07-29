//
//  ViewController.swift
//  AppleWatchPeertalk
//
//  Created by Chaiyawan Auepanwiriyakul on 28/07/2022.
//

import UIKit
import HealthKit

final class ViewController: UIViewController {
//    @IBOutlet private var stackView: UIStackView!
//    @IBOutlet private var textView: UITextView!
//    @IBOutlet private var textField: UITextField!
//    @IBOutlet private var bottomConstraint: NSLayoutConstraint!
    
    var timer: Timer?
    let watchConnectivityManager = WatchConnectivityManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        textField.becomeFirstResponder()
        
        let healthStore = HKHealthStore()
                
        let allTypes = Set([
                            HKObjectType.quantityType(forIdentifier: .heartRate)!
                            ])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                // Handle the error here.
            }
        }


        // Create a new channel that is listening on our IPv4 port
//        self.timer = Timer.scheduledTimer(timeInterval: 3.0, target: watchConnectivityManager, selector: #selector(watchConnectivityManager.heartBeat), userInfo: nil, repeats: true)
    }

//    @objc func keyboardWillShow(notification: Notification) {
//        guard let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
//            return
//        }
//        bottomConstraint.constant = -keyboardEndFrame.height
//    }
    

//    func send(message: String) {
//        if let peerChannel = peerChannel {
//            var m = message
//            let payload = m.withUTF8 { buffer -> Data in
//                var data = Data()
//                data.append(CFSwapInt32HostToBig(UInt32(buffer.count)).data)
//                data.append(buffer)
//                return data
//            }
//            peerChannel.sendFrame(type: Frame.message.rawValue, tag: 0, payload: payload, callback: nil)
//        } else {
//            NSLog("Cannot send message - not connected")
//        }
//    }

//    func append(output message: String) {
//        var text = textView.text ?? ""
//        if text.count == 0 {
//            text.append(message)
//        } else {
//            text.append("\n\(message)")
//        }
//        textView.text = text
//        textView.scrollRangeToVisible(NSRange(location: text.count, length: 0))
//    }
}

//extension ViewController: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        guard peerChannel != nil,
//                    let message = textField.text else {
//            return false
//        }
//        send(message: message)
//        textField.text = nil
//        return true
//    }
//}

