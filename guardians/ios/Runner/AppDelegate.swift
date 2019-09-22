import UIKit
import Flutter
import UserNotifications
import GoogleMaps

class Notifications: NSObject, UNUserNotificationCenterDelegate {
    
}

@available(iOS 10.0, *)
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
    let notifications = Notifications()
    let notificationCenter = UNUserNotificationCenter.current()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        notificationCenter.delegate = self
        notificationRequest()
        GMSServices.provideAPIKey("AIzaSyATcu886D3cfxtrgsspKUjszSK5DzNoqBo")

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func notificationRequest() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
    func scheduleNotification(notificationType: String) {
        
        let content = UNMutableNotificationContent() // Содержимое уведомления
        let userActions = "User Actions"
        
        content.title = "알람"
        content.body = "알람이 울렸습니다."
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = userActions
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        
        let snoozeAction = UNNotificationAction(identifier: "Snooze", title: "Snooze", options: [])
        let deleteAction = UNNotificationAction(identifier: "Delete", title: "Delete", options: [.destructive])
        let category = UNNotificationCategory(identifier: userActions, actions: [snoozeAction, deleteAction], intentIdentifiers: [], options: [])
        
        notificationCenter.setNotificationCategories([category])
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleNotification(notificationType: "Snooze")
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }
}
