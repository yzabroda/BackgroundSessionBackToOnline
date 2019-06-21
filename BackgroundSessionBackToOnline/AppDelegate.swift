//
//  AppDelegate.swift
//  BackgroundSessionBackToOnline
//
//  Created by Yuriy Zabroda on 5/28/19.
//  Copyright © 2019 Yuriy Zabroda. All rights reserved.
//

import os.log
import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        os_log("------ didFinishLaunchingWithOptions")

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        os_log("------ applicationWillResignActive")
    }


    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        os_log("------ handleEventsForBackgroundURLSession; state: %{public}d", application.applicationState.rawValue)
        os_log("------ handleEventsForBackgroundURLSession: backgroundTimeRemaining = %{public}f", application.backgroundTimeRemaining)

        guard identifier == BigFileDownloadManager.backgroundSessionIdentifier else { return }

        backgroundCompletionHandler = completionHandler

        BigFileDownloadManager.shared.resumeBackgroundDownload()
    }


    func applicationDidEnterBackground(_ application: UIApplication) {
        var bti: UIBackgroundTaskIdentifier!

        bti = application.beginBackgroundTask {
            application.endBackgroundTask(bti)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            os_log("------ Going to kill myself now!!!!!!! %{public}d", bti.rawValue)
            exit(EXIT_SUCCESS)
        }
    }


    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        os_log("------ applicationDidBecomeActive")
//        BigFileDownloadManager.shared.forceResume()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    private(set) var backgroundCompletionHandler: (() -> Void)?
}

