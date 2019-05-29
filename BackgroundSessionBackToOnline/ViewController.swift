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

        overallProgress = Progress.discreteProgress(totalUnitCount: Int64(filesToDownload.count))
    }


    @IBAction func resumeDownload(_ sender: UIButton) {
        theProgressView.observedProgress = overallProgress

        fractionCompletedObservation = overallProgress.observe(\.fractionCompleted) { [weak self] progress, _ in
            guard let strongSelf = self else { return }

            OperationQueue.main.addOperation {
                strongSelf.descriptionLabel.text = progress.localizedDescription
                strongSelf.additionalDescriptionLabel.text = progress.localizedAdditionalDescription
            }
        }

        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/250lnw83hnjfutowrg/250/250_hd_extend_your_apps_presence_with_deep_linking.mp4?dl=1")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3.0)

        let downloadTask = urlSession.downloadTask(with: request)
        overallProgress.addChild(downloadTask.progress, withPendingUnitCount: 1)
        downloadTask.resume()
    }


    @IBOutlet var theProgressView: UIProgressView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var additionalDescriptionLabel: UILabel!
    

    private final func startDownload() {
        guard currentFileIndex < filesToDownload.count else {
            os_log("--- Downloading finished!!!")

            return
        }

        let url = URL(string: filesToDownload[currentFileIndex])!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 3.0)

        let downloadTask = urlSession.downloadTask(with: request)
        overallProgress.addChild(downloadTask.progress, withPendingUnitCount: 1)
        downloadTask.resume()
    }


    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.bomzh.uu")

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()


    var downloadTaskAddresses = Set<String>()

    private let filesToDownload = [
//        "https://devstreaming-cdn.apple.com/videos/wwdc/2017/250lnw83hnjfutowrg/250/250_sd_extend_your_apps_presence_with_deep_linking.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/ensuring_beautiful_rich_links/ensuring_beautiful_rich_links_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/web_inspector_walkthrough/web_inspector_walkthrough_sd.mp4?dl=1",
        "https://devstreaming-cdn.apple.com/videos/tutorials/using_web_inspector_with_tvos_apps/using_web_inspector_with_tvos_apps_sd.mp4?dl=1" // ,
//        "https://devstreaming-cdn.apple.com/videos/tutorials/20170912/202uhvrcg65c7/updating_your_app_for_apple_tv_4k/updating_your_app_for_apple_tv_4k_sd.mp4?dl=1"
    ]

    private var overallProgress: Progress!
    private var currentFileIndex = 0
    private var fractionCompletedObservation: NSKeyValueObservation?
}



extension ViewController: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            os_log("--- didCompleteWithError: %{public}@", error.localizedDescription)
        } else {
            os_log("--- didCompleteWithError: nil")
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.currentFileIndex += 1
                strongSelf.startDownload()
            }
        }
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        os_log("didFinishDownloadingTo")
        os_log("--- %{public}@", downloadTaskAddresses)
    }


    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let address = String(format: "%p", downloadTask)
        downloadTaskAddresses.insert(address)
        os_log("--- downloadTask: %{public}@, bytesWritten: %{public}d, totalBytesExpectedToWrite: %{public}d", address, bytesWritten, totalBytesExpectedToWrite)
    }
}
