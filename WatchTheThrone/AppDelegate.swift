//
//  AppDelegate.swift
//  WatchTheThrone
//
//  Created by Patrick Tescher on 7/10/15.
//  Copyright (c) 2015 Ticketfly. All rights reserved.
//

import Cocoa


enum ThroneOccupiedState {
    case Unknown
    case Vacant
    case Occupied
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CocoaMQTTDelegate {

    @IBOutlet weak var menu: NSMenu!

    @IBOutlet weak var notificationMenuItem: NSMenuItem!

    var notificationTimer: NSTimer?

    var throneState = ThroneOccupiedState.Unknown {
        didSet {
            switch throneState {
            case .Unknown:
                println("State changed to Unknown")
                statusItem.title = "📡"
                if notificationMenuItem.state == NSOffState {
                    notificationMenuItem.enabled = false
                }
            case .Vacant:
                println("State changed to Vacant")
                statusItem.title = "🚽"
                if notificationMenuItem.state == NSOffState {
                    notificationMenuItem.enabled = false
                }
            case .Occupied:
                println("State changed to Occupied")
                statusItem.title = "💩"
                notificationMenuItem.enabled = true
            }
        }
    }

    lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
        statusItem.title = "📡"
        return statusItem
    }()

    lazy var mqttClient: CocoaMQTT = {
        let mqttClient = CocoaMQTT(clientId: NSUUID().UUIDString.lowercaseString, host: "cloud.pat2man.com", port: 1883)
        mqttClient.delegate = self
        mqttClient.username = "macosx"
        mqttClient.password = "blahblahblah"
        return mqttClient
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem.menu = menu
        mqttClient.connect()
    }

    @IBAction func notifyMe(sender: NSMenuItem) {
        switch sender.state {
            case NSOffState:
                sender.state = NSOnState
            default:
                sender.state = NSOffState
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // MARK: - CocoaMQTTDelegate

    func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {

    }

    func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        mqtt.subscribe("test", qos: CocoaMQTTQOS.QOS0)
    }

    func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {

    }

    func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {

    }

    func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {

    }

    func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError) {
        statusItem.title = "📡"
    }

    func mqttDidPing(mqtt: CocoaMQTT) {

    }

    func mqttDidReceivePong(mqtt: CocoaMQTT) {

    }

    func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if let string = message.string {
            if string.hasSuffix("lse") {
                if throneState == .Occupied {
                    if notificationTimer == nil {
                        notificationTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "vacantTimerFired:", userInfo: nil, repeats: false)
                    }
                } else {
                    throneState = .Vacant
                }
            } else if string.hasSuffix("ue") {
                notificationTimer?.invalidate()
                throneState = .Occupied
            } else {
                throneState = .Unknown
            }
        }
    }

    func vacantTimerFired(timer: NSTimer) {
        notificationTimer = nil
        throneState = .Vacant
        if notificationMenuItem.state == NSOnState {
            notificationMenuItem.state = NSOffState
            let notification = NSUserNotification()
            notification.title = "Stall Free"
            notification.informativeText = "The stall is now free!"
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
    }
}

