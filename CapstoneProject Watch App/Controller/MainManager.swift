//
//  MainController.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/29.
//

import Foundation
import CoreMotion

class MainManager: NSObject, ObservableObject {
    @Published var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    // MARK: - Session State Control
    @Published var running = false
    
    func togglePause() {
        if running == true {
            stopGettingData()
            calculating = true
            //            calcPreprocessor()
            //            machineLearning()
            calculating = false
            showingSummaryView = true
        } else {
            startGettingData()
        }
    }
    
    let motion = CMMotionManager()
    var sensorOutputs: [SensorOutput] = []
    
    func startGettingData() {
        if self.motion.isDeviceMotionAvailable {
            print("현재 기기는 core motion이 이용되지 않습니다.")
        }
        self.motion.deviceMotionUpdateInterval = 1.0 / 60.0
        
        self.motion.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
            if let error = error {
                print("모션 데이터 업데이트 에러: \(error.localizedDescription)")
            }
            if let data = data {
                let gyroX = data.rotationRate.x
                let gyroY = data.rotationRate.y
                let gyroZ = data.rotationRate.z
                
                let accX = data.gravity.x + data.userAcceleration.x
                let accY = data.gravity.y + data.userAcceleration.y
                let accZ = data.gravity.z + data.userAcceleration.z
                
                var sensorOutput = SensorOutput(Float(gyroX), Float(gyroY), Float(gyroZ), Float(accX), Float(accY), Float(accZ))
                
                self.sensorOutputs.append(sensorOutput)
            }
        }
        running = true
    }
    
    func stopGettingData() {
        self.motion.stopDeviceMotionUpdates()
        sensorOutputs.removeAll()
        running = false
    }
    
    // MARK: - Workout Metrics
    @Published var squatCount: Int = 12
    @Published var lungeCount: Int = 13
    @Published var situpCount: Int = 15
    @Published var burpeeCount: Int = 17
    
    func resetWorkout() {
        squatCount = 0
        lungeCount = 0
        situpCount = 0
        burpeeCount = 0
    }
    
    @Published var calculating: Bool = false
    func calcPreprocessor() -> ([[Float]], [[Float]]){
        var preprocessor: Preprocessor = Preprocessor(sensorOutputs)
        return preprocessor.saveTorchRawData()
    }
    // func machineLearning() { }
}
