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
//            calcPreprocessor()
//            machineLearning()
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
                
                let sensorOutput = SensorOutput(gyroX: Float(gyroX), gyroY: Float(gyroY), gyroZ: Float(gyroZ), accX: Float(accX), accY: Float(accY), accZ: Float(accZ))
                
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
    @Published var squatCount: Double = 0
    @Published var LungeCount: Double = 0
    @Published var situpCount: Double = 0
    @Published var BurpeeCount: Double = 0
    
    func resetWorkout() {
        squatCount = 0
        LungeCount = 0
        situpCount = 0
        BurpeeCount = 0
    }
    
    // func calcPreprocessor() { }
    // func machineLearning() { }
}
