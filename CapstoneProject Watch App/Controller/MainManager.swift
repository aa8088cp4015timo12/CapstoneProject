//
//  MainController.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/29.
//

import Foundation
import CoreMotion
import CoreML
import HealthKit

class MainManager: NSObject, ObservableObject {
    @Published var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    @Published var running = false
    let motion = CMMotionManager()
    var sensorOutputs: [SensorOutput] = []
    let queue = OperationQueue()
    @Published var squatCount: Int = 0
    @Published var lungeCount: Int = 0
    @Published var situpCount: Int = 0
    @Published var burpeeCount: Int = 0
    @Published var calculating: Bool = false
    
    // For background work
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    
    func startMainManager() {
        // Serial queue for sample handling and calculations.
        sensorOutputs.reserveCapacity(3000)
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"

        // read mlmodelc file
        readModel()
    }
    
    // MARK: - Session State Control
    func togglePause() {
        if running == true {
            calculating = true
            stopGettingData()
            executeModel()
            running = false
            showingSummaryView = true
            sensorOutputs.removeAll()
        } else {
            running = true
            startGettingData()
        }
    }
    
    /// 처음 watch app이 실행될 때 한 번 실행되는 함수
    func startGettingData() {
        // Configure the workout session.
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .outdoor
        
        // Create the session and obtain the workout builder.
        do {
            self.session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            return
        }
        
        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        
        // Check motion availability
        if self.motion.isDeviceMotionAvailable {
            print("현재 기기는 core motion이 이용가능합니다.")
        } else {
            print("core motion 불가합니다.")
        }
        self.motion.deviceMotionUpdateInterval = 1.0 / 60.0
        
        // Starts device-motion updates
        self.motion.startDeviceMotionUpdates(to: queue) { (data, error) in
            if let error = error {
                print("모션 데이터 업데이트 에러: \(error.localizedDescription)")
            }
            
            guard let data = data else { return }
            DispatchQueue.main.async {
                let currenTime = self.returnCurrentTime()
                let gyroX = data.rotationRate.x
                let gyroY = data.rotationRate.y
                let gyroZ = data.rotationRate.z
                
                let accX = data.gravity.x + data.userAcceleration.x
                let accY = data.gravity.y + data.userAcceleration.y
                let accZ = data.gravity.z + data.userAcceleration.z
                
                let sensorOutput = SensorOutput(Float(gyroX), Float(gyroY), Float(gyroZ), Float(accX), Float(accY), Float(accZ))
                // print("\(currenTime), \(accX), \(accY), \(accZ), \(gyroX), \(gyroY), \(gyroZ)")
                self.sensorOutputs.append(sensorOutput)
            }
        }
    }
    
    func returnCurrentTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        
        let currentTime = "\(hour):\(minutes):\(seconds):\(nanoseconds)"
        
        return currentTime
    }
    
    func stopGettingData() {
        self.motion.stopDeviceMotionUpdates()
        self.session?.stopActivity(with: Date())
        self.session?.end()
    }
    
    func resetWorkout() {
        squatCount = 0
        lungeCount = 0
        situpCount = 0
        burpeeCount = 0
    }
    
    // MARK: - Workout MLModel
    func readModel() {
        let mlmodelNames = ["compiled_burpee_model", "compiled_lunge_model", "compiled_squat_model", "compiled_situp_model", "all_model"]
        for name in mlmodelNames {
            guard let modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
                fatalError("Failed to locate the model in the app bundle.")
            }
            do{
                _ = try MLModel(contentsOf: modelURL)
            } catch {
                print("Error while loading Core ML model: \(error)")
            }
        }
        print("end readModel")
    }
    
    // main machine learning function
    private func executeModel() {
        // prepocessing data
        let preprocessor: Preprocessor = Preprocessor(sensorOutputs)
        let (data5, data6) = preprocessor.saveTorchRawData()
        
        let data5MMA = createMLMutliArray(data: data5)
        let data6MMA = createMLMutliArray(data: data6)
        
        // execute class model
        let sportModel = executeClassMLModel(inputData: data5MMA)
        
        // execute count model
        switch sportModel {
        case 0:
            squatCount = squatCount + executeSquatModel(inputData: data6MMA)
        case 1:
            lungeCount = lungeCount + executeLungeModel(inputData: data5MMA)
        case 2:
            situpCount = situpCount + executeSitupModel(inputData: data6MMA)
        case 3:
            burpeeCount = burpeeCount + executeBurpeeModel(inputData: data5MMA)
        default:
            print("sportModel out of bound")
        }
        calculating = false
    }
    
    // [[Float]] -> MLMultiArray
    private func createMLMutliArray(data: [[Float]]) -> MLMultiArray {
        guard let mmArray = try? MLMultiArray(shape: [1, 8, 1000], dataType: .float32) else {
            return MLMultiArray()
        }
        for n in 0..<data.count {
            mmArray[[0, 0, n] as [NSNumber]] = NSNumber(value: data[n][0])
            mmArray[[0, 1, n] as [NSNumber]] = NSNumber(value: data[n][1])
            mmArray[[0, 2, n] as [NSNumber]] = NSNumber(value: data[n][2])
            mmArray[[0, 3, n] as [NSNumber]] = NSNumber(value: data[n][3])
            mmArray[[0, 4, n] as [NSNumber]] = NSNumber(value: data[n][4])
            mmArray[[0, 5, n] as [NSNumber]] = NSNumber(value: data[n][5])
            mmArray[[0, 6, n] as [NSNumber]] = NSNumber(value: data[n][6])
            mmArray[[0, 7, n] as [NSNumber]] = NSNumber(value: data[n][7])
        }
        return mmArray
    }
    
    
    /// 운동 종류를 구분하는 머신러닝 all_class.mlmodelc, all_class.mlmodel
    /// - Parameter inputData: input Float matrix [8 * 1000]
    /// - Returns: 운동 종류 ( 1:  squat, 2: lunge, 3: sit up, 4: burpee)
    private func executeClassMLModel(inputData: MLMultiArray) -> Int{
        let defaultConfig = MLModelConfiguration()
        let classfierModel = try! all_model(configuration: defaultConfig)
        
        _ = try! all_modelInput(input: inputData)
        let output = try! classfierModel.prediction(input: inputData)
        let prediction = output.var_417
        
        // [1 * 4] float array에서 가장 큰 값을 가진 index를 구함
        var maxIndex = 0
        for n in 0..<(prediction.shape[1].intValue - 1) {
            if prediction[[0, NSNumber(value: n)]].intValue < prediction[[0, NSNumber(value: n + 1)]].intValue{
                maxIndex = n + 1
            }
        }
        return maxIndex
    }
    
    /// burpee 운동 횟수 측정 머신러닝
    /// - Parameter inputData: input Float matrix [8 * 1000]
    /// - Returns: burpee  운동 횟수
    private func executeBurpeeModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! burpee_round_model(configuration: defaultConfig)
        
        _ = try! burpee_round_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        guard !(prediction[[0, 0]].floatValue.isNaN || prediction[[0, 0]].floatValue.isInfinite) else {
            print("error: Float value cannot be converted to Int because it is either infinite or NaN")
            print("prediction: \(prediction[[0, 0]].floatValue)")
            return 0
        }
        
        return Int(roundf(prediction[[0, 0]].floatValue))
    }
    
    /// lunge 운동 횟수 측정 머신러닝
    /// - Parameter inputData: input Float matrix [8 * 1000]
    /// - Returns: lunge 운동 횟수
    private func executeLungeModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! lunge_round_model(configuration: defaultConfig)
        
        _ = try! lunge_round_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        guard !(prediction[[0, 0]].floatValue.isNaN || prediction[[0, 0]].floatValue.isInfinite) else {
            print("error: Float value cannot be converted to Int because it is either infinite or NaN")
            print("prediction: \(prediction[[0, 0]].floatValue)")
            return 0
        }
        
        return Int(roundf(prediction[[0, 0]].floatValue))
    }
    
    /// sit up 운동 횟수 측정 머신러닝
    /// - Parameter inputData: input Float matrix [8 * 1000]
    /// - Returns: sit up 운동 횟수
    private func executeSitupModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! situp_round_model(configuration: defaultConfig)
        
        _ = try! situp_round_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        guard !(prediction[[0, 0]].floatValue.isNaN || prediction[[0, 0]].floatValue.isInfinite) else {
            print("error: Float value cannot be converted to Int because it is either infinite or NaN")
            print("prediction: \(prediction[[0, 0]].floatValue)")
            return 0
        }
        
        return Int(roundf(prediction[[0, 0]].floatValue))
    }
    
    /// squat 운동 횟수 측정 머신러닝
    /// - Parameter inputData: input Float matrix [8 * 1000]
    /// - Returns: squat 운동 횟수
    private func executeSquatModel(inputData: MLMultiArray) -> Int {
        let defaultConfig = MLModelConfiguration()
        let countModel = try! squat_round_model(configuration: defaultConfig)
        
        _ = try! squat_round_modelInput(input: inputData)
        let output = try! countModel.prediction(input: inputData)
        let prediction = output.var_417
        
        guard !(prediction[[0, 0]].floatValue.isNaN || prediction[[0, 0]].floatValue.isInfinite) else {
            print("error: Float value cannot be converted to Int because it is either infinite or NaN")
            print("prediction: \(prediction[[0, 0]].floatValue)")
            return 0
        }
        
        return Int(roundf(prediction[[0, 0]].floatValue))
    }
}
