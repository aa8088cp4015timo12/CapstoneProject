//
//  MainController.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/29.
//

import Foundation
import CoreMotion
import CoreML

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
    func calcPreprocessor() -> (MLMultiArray, MLMultiArray){
        var preprocessor: Preprocessor = Preprocessor(sensorOutputs)
        return preprocessor.saveTorchRawData()
    }
    
    func executeClassMLModel(inputData: MLMultiArray) -> Int{
        let defaultConfig = MLModelConfiguration()
        let classfierModel = try! all_model(configuration: defaultConfig)
        
        let input = try! all_modelInput(input: inputData)
        let output = try! classfierModel.prediction(input: inputData)
        let prediction = output.var_417
        
        var maxIndex = 0
        for n in 0..<(prediction.shape[1].intValue - 1) {
            if prediction[[0, NSNumber(value: n)]].intValue < prediction[[0, NSNumber(value: n + 1)]].intValue{
                maxIndex = n + 1
            }
        }
        return maxIndex
    }
    
    func executeBurpeeModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! burpee_model(configuration: defaultConfig)
        
        let input = try! burpee_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        return Int(round(prediction[[0, 0]].floatValue))
    }
    
    func executeLungeModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! lunge_model(configuration: defaultConfig)
        
        let input = try! lunge_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        return Int(round(prediction[[0, 0]].floatValue))
    }
    
    func executeSitupModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! situp_model(configuration: defaultConfig)
        
        let input = try! situp_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        return Int(round(prediction[[0, 0]].floatValue))
    }
    
    func executeSquatModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! squat_model(configuration: defaultConfig)
        
        let input = try! squat_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        return Int(round(prediction[[0, 0]].floatValue))
    }
}
