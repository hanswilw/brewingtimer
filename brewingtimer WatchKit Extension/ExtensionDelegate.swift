//
//  ExtensionDelegate.swift
//  brewingtimer WatchKit Extension
//
//  Created by Hans-Wilhelm Warlo on 21/02/2018.
//  Copyright © 2018 Hans-Wilhelm Warlo. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        UserDefaults.standard.register(defaults: [
            "useMic": true,
            "pauseBelowThreshold": true,
            "threshold": thresholdWatch,
        ])
        useMic = UserDefaults.standard.bool(forKey: "useMic")
        pauseBelowThreshold = UserDefaults.standard.bool(forKey: "pauseBelowThreshold")
        threshold = UserDefaults.standard.float(forKey: "threshold")
    }

    func applicationDidBecomeActive() {}

    func applicationWillResignActive() {
        UserDefaults.standard.set(useMic, forKey: "useMic")
        UserDefaults.standard.set(pauseBelowThreshold, forKey: "pauseBelowThreshold")
        UserDefaults.standard.set(threshold, forKey: "threshold")
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date.distantFuture,
                    userInfo: nil
                )
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
