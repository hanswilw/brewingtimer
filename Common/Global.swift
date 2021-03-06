//
//  Global.swift
//  brewingtimer
//
//  Created by Hans-Wilhelm Warlo on 11/03/2018.
//  Copyright © 2018 Hans-Wilhelm Warlo. All rights reserved.
//

import Foundation
import YOChartImageKit

var time: Double = 0.0
var started: Date?
var triggeredDate: Date?
var aboveThresholdDiff = 0.0

let thresholdPhone: Float = -25.0
let thresholdWatch: Float = -40.0
var threshold: Float = 0

var running = false

var timer: Timer?
var graphTimer: Timer?

var useMic = true
var pauseBelowThreshold = true
var triggered = false
var asyncWork: DispatchWorkItem?

extension CGRect {
    init(
        _ xPoint: CGFloat,
        _ yPoint: CGFloat,
        _ width: CGFloat,
        _ height: CGFloat
    ) {
        self.init(x: xPoint, y: yPoint, width: width, height: height)
    }
}

extension CGSize {
    init(_ width: CGFloat, _ height: CGFloat) {
        self.init(width: width, height: height)
    }
}

extension CGPoint {
    init(_ xPoint: CGFloat, _ yPoint: CGFloat) {
        self.init(x: xPoint, y: yPoint)
    }
}

func resetGlobalVariables() {
    time = 0.0
    started = nil
    triggeredDate = nil
    aboveThresholdDiff = 0.0

    running = false
    timer?.invalidate()
    timer = nil
    triggered = false
}

protocol CommonController {
    var microphone: MicrophoneController { get set }
    var graph: GraphController { get set }

    func getAsyncWork(new: Bool) -> DispatchWorkItem
    func getGraph() -> GraphController
    func getMicrophone() -> MicrophoneController
    func getDimensions() -> (width: CGFloat, height: CGFloat, scale: CGFloat)
    func updateMeter()
    func updateGraph()
    func loadRecordingUI()
    func loadFailUI()
    func updateDecibelLabel(decibels: Float)
    func updateTimerLabel(time: Double)
    func updateImage(image: UIImage)
    func updateButtonText(text: String)
    func start()
    func stop()
    func onLoad()
    func onAppear()
    func onDisappear()
}

extension CommonController {
    var microphone: MicrophoneController { return getMicrophone() }

    var graph: GraphController { return getGraph() }

    func getAsyncWork(new: Bool = false) -> DispatchWorkItem {
        if new || asyncWork == nil {
            asyncWork = DispatchWorkItem(block: {
                self.stop()
            })
        }
        return asyncWork!
    }

    func updateMeter() {
        if useMic {
            let decibels: Float = microphone.getDecibels()
            if triggered || decibels > threshold {
                if !pauseBelowThreshold {
                    triggered = true
                }

                if triggeredDate == nil {
                    triggeredDate = Date()
                } else {
                    aboveThresholdDiff = time + Date().timeIntervalSince(triggeredDate!)
                }
                updateTimerLabel(time: aboveThresholdDiff)
            } else {
                triggeredDate = nil
                time = aboveThresholdDiff
            }
        } else {
            time = Date().timeIntervalSince(started!)
            updateTimerLabel(time: time)
        }
    }

    func updateGraph() {
        let decibels: Float = microphone.getDecibels()
        let (width, height, scale) = getDimensions()
        updateDecibelLabel(decibels: decibels)
        graph.updateGraphValues(decibels: decibels)
        graph.drawGraph(width: width, height: height, scale: scale) { graphImage in
            self.updateImage(image: graphImage)
        }
    }

    func loadRecordingUI() {
        triggered = false
        updateButtonText(text: "RESET")
    }

    func startTimer() {
        running = true
        started = Date()
        updateTimerLabel(time: 0.00)

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.01,
            repeats: true
        ) { _ in self.updateMeter() }
        loadRecordingUI()
    }

    func start() {
        if !running {
            if !useMic {
                startTimer()
            } else {
                microphone.initRecorder { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            graphTimer = Timer.scheduledTimer(
                                withTimeInterval: 0.1,
                                repeats: true
                            ) { _ in self.updateGraph() }

                            self.startTimer()
                        }
                    } else {
                        self.loadFailUI()
                    }
                }
            }
        }
    }

    func stop() {
        updateButtonText(text: "START")
        graphTimer?.invalidate()
        graphTimer = nil

        resetGlobalVariables()
        graph.clearGraph()
        microphone.closeRecorder()
    }

    func onLoad() {
        start()
    }

    func onAppear() {
        getAsyncWork(new: false).cancel()
    }

    func onDisappear() {
        // Stop the microphone 15 seconds after leaving app
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 15,
            execute: getAsyncWork(new: true)
        )
    }
}
