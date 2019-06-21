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

        os_log("------ %{public}@", #function)
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
        guard currentFileIndex < filesToDownload.count else {
            os_log("------ ------ Download complete!!!!!!!!!!!")

            return
        }

        let fileToDown = filesToDownload[currentFileIndex]
        let url = URL(string: fileToDown)!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3.0)

        os_log("------ Going to create a downloadTask")
        let downloadTask = urlSession.downloadTask(with: request)
        overallProgress!.addChild(downloadTask.progress, withPendingUnitCount: 1)

//        utilityQueue.sync {
            downloadTask.resume()
            os_log("------ Just called resume()")
//        }
    }


//    final func forceResume() {
//        urlSession.getTasksWithCompletionHandler { [weak self] _, _, downloadTasks in
//            self?.utilityQueue.async {
//                downloadTasks.first(where: { $0.state == .suspended })?.resume()
//            }
//        }
//    }


    final func resumeBackgroundDownload() {
        currentFileIndex = UserDefaults.standard.integer(forKey: "Bomzh")

        // Re-creates
        let _ = urlSession
    }


    private override init() {
        super.init()

//        currentFileIndex = UserDefaults.standard.integer(forKey: "Bomzh")
//        os_log("------ init(): currentFileIndex: %{public}d", currentFileIndex)
    }


    private(set) lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: type(of: self).backgroundSessionIdentifier)

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private let filesToDownload = [
//        "https://devstreaming-cdn.apple.com/videos/wwdc/2017/250lnw83hnjfutowrg/250/250_sd_extend_your_apps_presence_with_deep_linking.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/ensuring_beautiful_rich_links/ensuring_beautiful_rich_links_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/web_inspector_walkthrough/web_inspector_walkthrough_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/using_web_inspector_with_tvos_apps/using_web_inspector_with_tvos_apps_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/20170912/202uhvrcg65c7/updating_your_app_for_apple_tv_4k/updating_your_app_for_apple_tv_4k_sd.mp4?dl=1"
    ]

    private weak var overallProgress: Progress?
    private var currentFileIndex = 0

    private lazy var operationQueue: OperationQueue = {
        let oq = OperationQueue()
        oq.maxConcurrentOperationCount = 1
//        oq.qualityOfService = .utility

        return oq
    }()

    private var utilityQueue = DispatchQueue(label: "com.bomz.uu", qos: .utility)
}



extension BigFileDownloadManager: URLSessionDownloadDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log("------ Entering urlSessionDidFinishEvents(forBackgroundURLSession")

        DispatchQueue.main.async {
            let timeRemaining = UIApplication.shared.backgroundTimeRemaining
            os_log("------ urlSessionDidFinishEvents: backgroundTimeRemaining = %{public}f", timeRemaining)

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let backgroundCompletionHandler =
                appDelegate.backgroundCompletionHandler else {
                    return
            }

            os_log("------ urlSessionDidFinishEvents: calling backgroundCompletionHandler")
            backgroundCompletionHandler()
        }
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        os_log("------ Entering urlSession didCompleteWithError")

        DispatchQueue.main.async {
            let timeRemaining = UIApplication.shared.backgroundTimeRemaining
            os_log("------ didCompleteWithError: backgroundTimeRemaining = %{public}f", timeRemaining)
        }

        if let error = error {
            os_log("------ didCompleteWithError: %{public}@", error.localizedDescription)

            return
        }

//        let nextOperation = BlockOperation { [weak self] in
//            guard let strongSelf = self else { return }
//            os_log("------ Inside nextOperation")

//            strongSelf.currentFileIndex += 1
//            UserDefaults.standard.set(strongSelf.currentFileIndex, forKey: "Bomzh")
//            strongSelf.startDownload()
//        }

        currentFileIndex += 1
        UserDefaults.standard.set(currentFileIndex, forKey: "Bomzh")
        startDownload()

//        let taskIdentifier = UIApplication.shared.beginBackgroundTask {
//            nextOperation.cancel()
//            os_log("------ Unable to start download of file #%{public}d", self.currentFileIndex)
//        }
//
//        guard taskIdentifier != .invalid else {
//            os_log("------ Unable to start download of file #%{public}d as we unable to beginBackgroundTask", currentFileIndex)
//
//            return
//        }
//
//        nextOperation.completionBlock = {
//            UIApplication.shared.endBackgroundTask(taskIdentifier)
//        }

//        operationQueue.addOperations([nextOperation], waitUntilFinished: true)
//        os_log("------ nextOperation looks finished")
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        os_log("------ Entering urlSession didFinishDownloadingTo")

        DispatchQueue.main.async {
            let timeRemaining = UIApplication.shared.backgroundTimeRemaining
            os_log("------ didFinishDownloadingTo: backgroundTimeRemaining = %{public}f", timeRemaining)
        }

        guard let response = downloadTask.response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            os_log("------ !!!! Server side error!!! Unable to download!!!")

            return
        }

        guard let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            os_log("------ FATAL!!!! Unable to find .downloadsDirectory, in: .userDomainMask")

            return
        }

        let docURL = documentURL.appendingPathComponent("BomzhTemp")

        do {
            try FileManager.default.createDirectory(at: docURL, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("------ createDirectory: %{public}@", error.localizedDescription)
        }

        do {
//            let zzz = try FileManager.default.contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil, options: [])
//            print("\(zzz)")

            let loc = docURL.appendingPathComponent("aaa\(currentFileIndex).mp4")
            os_log("------ Target filepath: %{public}@", loc.path)

            try FileManager.default.moveItem(at: location, to: loc)
            os_log("------ Successfully moved item to %{public}@", loc.path)
//            let attribs = try FileManager.default.attributesOfItem(atPath: loc.path)
//            let attrs = "\(attribs)"
//            os_log("------ File attributes: %{public}@", attrs)
        } catch {
            os_log("------ FATAL!!! %{public}@", error.localizedDescription)
        }
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        os_log("------ bytesWritten: %{public}d, totalBytesExpectedToWrite: %{public}d", bytesWritten, totalBytesExpectedToWrite)
    }
}
