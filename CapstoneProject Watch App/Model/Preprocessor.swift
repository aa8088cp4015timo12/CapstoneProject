//
//  Preprocessor.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/29.
//

import Foundation

class Preprocessor {
    let SensorOutputs: [SensorOutput]
    init(_ input: [SensorOutput]) {
        self.SensorOutputs = input
    }
    
    func sampling(samplingNum: Int) -> [[Float]] {
        var sampledData: [[Float]] = []
        let len = SensorOutputs.count
        for row in stride(from: 0, to: len, by: samplingNum) {
            if row + samplingNum > len {
                var extraRaw = row + samplingNum - len
                sampledData.append(getMeanFromTo(from: row, to: row + extraRaw))
            }
            else {
                sampledData.append(getMeanFromTo(from: row, to: row + samplingNum))
            }
        }
        return sampledData
    }
    func getMeanFromTo(from: Int, to: Int) -> [Float] {
        var tempAccX: Float = 0.0
        var tempAccY: Float = 0.0
        var tempAccZ: Float = 0.0
        
        var tempGyroX: Float = 0.0
        var tempGyroY: Float = 0.0
        var tempGyroZ: Float = 0.0
        
        for row in from..<to {
            tempAccX += SensorOutputs[row].accX
            tempAccY += SensorOutputs[row].accY
            tempAccZ += SensorOutputs[row].accZ
            
            tempGyroX += SensorOutputs[row].gyroX
            tempGyroY += SensorOutputs[row].gyroY
            tempGyroZ += SensorOutputs[row].gyroZ
        }
        let size: Float = Float(to - from)
        return [tempGyroX / size, tempGyroY / size, tempGyroZ / size, tempAccX / size, tempAccY / size, tempAccZ / size]
    }
    
    func saveTorchRawData() {
        let maxLen: Int = 1000
        let columnsList: [String] = ["WatchAccX", "WatchAccY", "WatchAccZ", "WatchGyroX", "WatchGryoY", "WatchGyroZ"]
        
        let filterNum: Int = Int(ceil(Double(SensorOutputs.count) / Double(maxLen)))
        // rolling
        var rollingData: [[Float]] = []
        for _ in 0..<filterNum {
            rollingData.append([0, 0, 0, 0, 0, 0, 0, 0])
        }
        for row in 0..<filterNum+1 {
            rollingData.append(getMeanFromTo(from: row, to: filterNum))
        }
    }
}
