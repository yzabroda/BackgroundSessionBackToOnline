//
//  ViewController.swift
//  BackgroundSessionBackToOnline
//
//  Created by Yuriy Zabroda on 5/28/19.
//  Copyright © 2019 Yuriy Zabroda. All rights reserved.
//

import os.log
import UIKit



class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }


    @IBAction func resumeDownload(_ sender: UIButton) {
        theProgressView.observedProgress = BigFileDownloadManager.shared.launchDownload()

        fractionCompletedObservation = theProgressView.observedProgress!.observe(\.fractionCompleted) { [weak self] progress, _ in
            guard let strongSelf = self else { return }

            OperationQueue.main.addOperation {
                strongSelf.descriptionLabel.text = progress.localizedDescription
                strongSelf.additionalDescriptionLabel.text = progress.localizedAdditionalDescription
            }
        }
    }


    @IBOutlet var theProgressView: UIProgressView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var additionalDescriptionLabel: UILabel!
    

    private var fractionCompletedObservation: NSKeyValueObservation?
}


class BigFileDownloadManager: NSObject {
    
    static let shared = BigFileDownloadManager()
    
    static let backgroundSessionIdentifier = "com.weather.pilotbrief.download-manager"

    final func launchDownload() -> Progress? {
        let overProg = Progress.discreteProgress(totalUnitCount: Int64(filesToDownload.count))
        overallProgress = overProg
        startDownload()

        return overProg
    }


    final func startDownload() {
        for fileToDown in filesToDownload {
            let url = URL(string: fileToDown)!
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3.0)

            os_log("------ Going to create a downloadTask")
            let downloadTask = urlSession.downloadTask(with: request)
            overallProgress!.addChild(downloadTask.progress, withPendingUnitCount: 1)
        }

        urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            DispatchQueue.main.async {
                downloadTasks.first(where: { $0.state == .suspended })?.resume()
            }
        }
    }


    final func forceResume() {
        urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            OperationQueue.main.addOperation {
                downloadTasks.first(where: { $0.state == .suspended })?.resume()
            }
        }
    }


    private override init() {
        super.init()

//        currentFileIndex = UserDefaults.standard.integer(forKey: "Bomzh")
//        os_log("------ init(): currentFileIndex: %{public}d", currentFileIndex)
    }


    private(set) lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.bomzh.uu")

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private let filesToDownload = [
        //        "https://devstreaming-cdn.apple.com/videos/wwdc/2017/250lnw83hnjfutowrg/250/250_sd_extend_your_apps_presence_with_deep_linking.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/ensuring_beautiful_rich_links/ensuring_beautiful_rich_links_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/web_inspector_walkthrough/web_inspector_walkthrough_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/using_web_inspector_with_tvos_apps/using_web_inspector_with_tvos_apps_sd.mp4?dl=1" // ,
        //        "https://devstreaming-cdn.apple.com/videos/tutorials/20170912/202uhvrcg65c7/updating_your_app_for_apple_tv_4k/updating_your_app_for_apple_tv_4k_sd.mp4?dl=1"
    ]

    private weak var overallProgress: Progress?
    private var currentFileIndex = 0
    private var backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
}



extension BigFileDownloadManager: URLSessionDownloadDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            let timeRemaining = UIApplication.shared.backgroundTimeRemaining
            os_log("------ urlSessionDidFinishEvents: backgroundTimeRemaining = %{public}f", timeRemaining)
        }

        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let backgroundCompletionHandler =
                appDelegate.backgroundCompletionHandler else {
                    return
            }
            backgroundCompletionHandler()
        }
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            let timeRemaining = UIApplication.shared.backgroundTimeRemaining
            os_log("------ didCompleteWithError: backgroundTimeRemaining = %{public}f", timeRemaining)
        }

        if let error = error {
            os_log("------ didCompleteWithError: %{public}@", error.localizedDescription)

            return
        }

        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            DispatchQueue.main.async {
                downloadTasks.first(where: { $0.state == .suspended })?.resume()
            }
        }

//        guard let response = task.response as? HTTPURLResponse else { return }
//        os_log("------ didCompleteWithError: nil; response: %{public}d", response.statusCode)

//        DispatchQueue.main.async { [weak self] in
//            guard let strongSelf = self else { return }
//        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.yz.download-next-file") { [weak self] in
//            guard let strongSelf = self else { return }
//
//            UIApplication.shared.endBackgroundTask(strongSelf.backgroundTaskIdentifier)
//        }

//        DispatchQueue.main.async {
//            os_log("------ Right after beginBackgroundTask: backgroundTimeRemaining: %{public}f", UIApplication.shared.backgroundTimeRemaining)
//        }
        
//        let strongSelf = self

//            strongSelf.currentFileIndex += 1
//        UserDefaults.standard.set(strongSelf.currentFileIndex, forKey: "Bomzh")
//            strongSelf.startDownload()
//        }

//        if backgroundTaskIdentifier != .invalid {
//            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
//        }
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            os_log("------ FATAL!!!! Unable to find .downloadsDirectory, in: .userDomainMask")

            return
        }

        let docURL = documentURL.appendingPathComponent("Temp")

        do {
            try FileManager.default.createDirectory(at: docURL, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("------ createDirectory: %{public}@", error.localizedDescription)
        }

        do {
//            let zzz = try FileManager.default.contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil, options: [])
//            print("\(zzz)")

            let loc = docURL.appendingPathComponent("aaa\(currentFileIndex).zip")
            os_log("------ Target filepath: %{public}@", loc.path)

            try FileManager.default.moveItem(at: location, to: loc)
            os_log("------ Successfully moved item to %{public}@", loc.path)
        } catch {
            os_log("------ FATAL!!! %{public}@", error.localizedDescription)
        }

        currentFileIndex += 1

        DispatchQueue.main.async {
            let timeRemaining = UIApplication.shared.backgroundTimeRemaining
            os_log("------ didFinishDownloadingTo: backgroundTimeRemaining = %{public}f", timeRemaining)
        }

//        guard let response = downloadTask.response as? HTTPURLResponse else { return }

//        os_log("------ didFinishDownloadingTo; response: %{public}d", response.statusCode)
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        os_log("------ bytesWritten: %{public}d, totalBytesExpectedToWrite: %{public}d", bytesWritten, totalBytesExpectedToWrite)
    }
}
