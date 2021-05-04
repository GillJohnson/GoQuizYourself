//
//  AppDelegate.swift
//  Go Quiz Yourself
//
//  Created by Gillian Johnson on 2021-03-05.
//

import UIKit
import Firebase
import SwiftyJSON
import UserNotifications
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow? = UIWindow()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }
    
    // handles user clicking on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if let vc = storyboard.instantiateViewController(withIdentifier: "QuizQuestionNotification") as? QuizQuestionNotificationViewController, let nav = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            vc.question = response.notification.request.content.userInfo["question"] as! [String]
            vc.questionLabelText = "\(vc.question[0].capitalized)?"
            vc.quizTitleLabelText = response.notification.request.content.userInfo["quizTitle"] as! String
            
            nav.pushViewController(vc, animated: true)
        }
        
        completionHandler()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
        }
        
        UIApplication.shared.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().delegate = self
        
        FirebaseApp.configure()
        
        AppCenter.start(withAppSecret: "7f4f76cb-8106-40d9-83c7-97c88497a1cd", services: [Analytics.self, Crashes.self])
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

