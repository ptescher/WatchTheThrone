//
//  AppDelegate.swift
//  WatchTheThrone
//
//  Created by Patrick Tescher on 7/10/15.
//  Copyright (c) 2015 Ticketfly. All rights reserved.
//

import Cocoa
import Fabric
import Crashlytics

enum ThroneOccupiedState {
    case Unknown
    case Vacant
    case Occupied
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CocoaMQTTDelegate {

    @IBOutlet weak var menu: NSMenu!

    @IBOutlet weak var notificationMenuItem: NSMenuItem!

    weak var notificationTimer: NSTimer?
    weak var reconnectionTimer: NSTimer?
    
    let vacantImage: NSImage? = NSImage(named: "vacant")
    let occupiedImage: NSImage? = NSImage(named: "occupied")

    var throneState = ThroneOccupiedState.Unknown {
        didSet {
            switch throneState {
            case .Unknown:
                statusItem.button?.image = vacantImage
                statusItem.button?.appearsDisabled = true
                if notificationMenuItem.state == NSOffState {
                    notificationMenuItem.enabled = false
                }
            case .Vacant:
                statusItem.button?.image = vacantImage
                if notificationMenuItem.state == NSOffState {
                    notificationMenuItem.enabled = false
                }
            case .Occupied:
                statusItem.button?.image = occupiedImage
                notificationMenuItem.enabled = true
            }
        }
    }

    lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
        statusItem.button?.image = self.vacantImage
        statusItem.button?.appearsDisabled = true
        return statusItem
    }()

    lazy var mqttClient: CocoaMQTT = {
        let mqttClient = CocoaMQTT(clientId: NSUUID().UUIDString.lowercaseString, host: "cloud.pat2man.com", port: 1883)
        mqttClient.delegate = self
        mqttClient.username = "macosx"
        mqttClient.password = "blahblahblah"
        mqttClient.keepAlive = 30
        return mqttClient
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        Fabric.with([Crashlytics()])
        statusItem.menu = menu
        statusItem.button?.appearsDisabled = true
        mqttClient.connect()
        vacantImage?.setTemplate(true)
        occupiedImage?.setTemplate(true)
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
        reconnectionTimer?.invalidate()
        statusItem.button?.appearsDisabled = false
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
        statusItem.button?.appearsDisabled = true
        if reconnectionTimer == nil {
            reconnectionTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "reconnect:", userInfo: nil, repeats: true)
            reconnectionTimer?.fire()
        }
    }

    func reconnect(timer: NSTimer?) {
        mqttClient.connect()
    }

    func mqttDidPing(mqtt: CocoaMQTT) {

    }

    func mqttDidReceivePong(mqtt: CocoaMQTT) {

    }

    func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if let string = message.string {
            statusItem.button?.appearsDisabled = false
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

