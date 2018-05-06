//
//  AppDelegate.swift
//  Avenue
//
//  Created by Saransh Mittal on 05/05/18.
//  Copyright © 2018 Saransh Mittal. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var locationManager: CLLocationManager!
    var notificationCenter: UNUserNotificationCenter!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        // get the singleton object
        self.notificationCenter = UNUserNotificationCenter.current()
        // register as it's delegate
        notificationCenter.delegate = self
        // define what do you need permission to use
        let options: UNAuthorizationOptions = [.alert, .sound]
        // request permission
        notificationCenter.requestAuthorization(options: options) { (granted, error) in
            if !granted {
                print("Permission not granted")
            }
        }
        if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil {
            print("I woke up thanks to geofencing")
        }
        return true
    }
    
    func handleEvent(forRegion region: CLRegion!) {
        print("notificgg6666666666666666666666666666666666666666666ation sent")
        // customize your notification content
        let content = UNMutableNotificationContent()
        content.title = "Early warning alert notification"
        content.body = "The applciation has detected a lot of diagnosed cases regarding Dengue around your location! Be Safe!"
        content.sound = UNNotificationSound.default()
        // when the notification will be triggered
        let timeInSeconds: TimeInterval = 3
        // the actual trigger object
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInSeconds,
            repeats: false
        )
        // notification unique identifier, for this example, same as the region to avoid duplicate notifications
        let identifier = region.identifier
        // the notification request object
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        // trying to add the notification request to notification center
        notificationCenter.add(request, withCompletionHandler: { (error) in
            if error != nil {
                print("Error adding notification with identifier: \(identifier)")
            }
        })
    }
}


extension AppDelegate: CLLocationManagerDelegate {
    // called when user Exits a monitored region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Did exit the area")
        if region is CLCircularRegion {
            // Do what you want if this information
            self.handleEvent(forRegion: region)
        }
    }
    
    // called when user Enters a monitored region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Did enter the area")
        if region is CLCircularRegion {
            // Do what you want if this information
            self.handleEvent(forRegion: region)
        }
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // when app is onpen and in foregroud
        print("Notificatipon")
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // get the notification identifier to respond accordingly
        let identifier = response.notification.request.identifier
        // do what you need to do
        print(identifier)
        // ...
    }
}


