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
    
    func saveTorchRawData() -> ([[Float]], [[Float]]) {
        let maxLen: Int = 1000
       
        let filterNum: Int = Int(ceil(Double(SensorOutputs.count) / Double(maxLen)))
        // rolling
        var data: [[Float]] = []
        for _ in 0..<filterNum-1 {
            data.append([0, 0, 0, 0, 0, 0, 0, 0])
        }
        for row in 0..<filterNum {
            data.append(getMeanFromTo(from: row, to: filterNum))
        }
        data = sampling(data: data, samplingNum: filterNum)
        
//        n = 5
//        b = [1.0 / n] * n
//        a = 1
//        for col in data.columns:
//            data[col]= lfilter(b, a, data[col])
//
//        data_n6= pd.DataFrame()
//        n = 6
//        b = [1.0 / n] * n
//        a = 1
//        for col in data.columns:
//            data_n6[col]= lfilter(b, a, data[col])
        
//        // normalization
//        data = (data - data.mean())/data.std()
//        data_n6 = (data_n6 - data_n6.mean())/data_n6.std()
        data = normalization(data: data, mean: getMeanFromTo(data: data, from: 0, to: data.count), std: getStd(data: data))
        
        if data.count < maxLen {
            let pad: [Float] = [Float](repeating: 0.0, count: 8)
            // cat_df = pd.concat([data, pad], axis=0).reset_index()
            for _ in 0..<(maxLen - data.count) {
                data.append(pad)
            }
            // cat_df_n6 = pd.concat([data_n6, pad], axis=0).reset_index()
        }
        
        // return data, dataN6
    }
  
    private func sampling(data: [[Float]], samplingNum: Int) -> [[Float]] {
        var sampledData: [[Float]] = []
        let len = SensorOutputs.count
        for row in stride(from: 0, to: len, by: samplingNum) {
            if row + samplingNum > len {
                var extraRaw = row + samplingNum - len
                sampledData.append(getMeanFromTo(data: data, from: row, to: row + extraRaw))
            }
            else {
                sampledData.append(getMeanFromTo(data: data, from: row, to: row + samplingNum))
            }
        }
        return sampledData
    }
    
     
    private func getMeanFromTo(from: Int, to: Int) -> [Float] {
        var tempAccX: Float = 0.0
        var tempAccY: Float = 0.0
        var tempAccZ: Float = 0.0
        
        var tempGyroX: Float = 0.0
        var tempGyroY: Float = 0.0
        var tempGyroZ: Float = 0.0
        
        var tempAccScala: Float = 0.0
        var tempGyroScala: Float = 0.0
        
        for row in from..<to {
            tempAccX += SensorOutputs[row].accX
            tempAccY += SensorOutputs[row].accY
            tempAccZ += SensorOutputs[row].accZ
            
            tempGyroX += SensorOutputs[row].gyroX
            tempGyroY += SensorOutputs[row].gyroY
            tempGyroZ += SensorOutputs[row].gyroZ
            
            tempAccScala += SensorOutputs[row].accScala
            tempAccScala += SensorOutputs[row].gyroScala
        }
        let size: Float = Float(to - from)
        return [tempAccX / size, tempAccY / size, tempAccZ / size, tempGyroX / size,
                tempGyroY / size, tempGyroZ / size, tempAccScala / size, tempGyroScala / size]
    }
    
    private func getMeanFromTo(data: [[Float]], from: Int, to: Int) -> [Float] {
        var tempAccX: Float = 0.0
        var tempAccY: Float = 0.0
        var tempAccZ: Float = 0.0
        
        var tempGyroX: Float = 0.0
        var tempGyroY: Float = 0.0
        var tempGyroZ: Float = 0.0
        
        var tempAccScala: Float = 0.0
        var tempGyroScala: Float = 0.0
        
        for row in from..<to {
            tempAccX += data[row][0]
            tempAccY += data[row][1]
            tempAccZ += data[row][2]
            
            tempGyroX += data[row][3]
            tempGyroY += data[row][4]
            tempGyroZ += data[row][5]
            
            tempAccScala += data[row][6]
            tempGyroScala += data[row][7]
        }
        let size: Float = Float(to - from)
        return [tempAccX / size, tempAccY / size, tempAccZ / size, tempGyroX / size,
                tempGyroY / size, tempGyroZ / size, tempAccScala / size, tempGyroScala / size]
    }
    
    private func getStd(data: [[Float]]) -> [Float] {
        let mean:[Float] = getMeanFromTo(data: data, from: 0, to: data.count)
        var deviation: [[Float]] = [[Float]] (repeating: Array(repeating: 0, count: data[0].count), count: data.count)
        for col in 0..<data.count {
            for row in 0..<data[0].count {
                let value: Float = data[col][row] - mean[row]
                deviation[col][row] = value * value
            }
        }
        let variance: [Float] = getMeanFromTo(data: deviation, from: 0, to: deviation.count)
        
        return variance.map { sqrtf($0) }
    }
    
    private func normalization(data: [[Float]], mean: [Float], std: [Float]) -> [[Float]] {
        var normal: [[Float]] = [[Float]](repeating: (Array(repeating: 0.0, count: data[0].count)), count: data.count)
        
        for col in 0..<data.count {
            for row in 0..<data[0].count {
                normal[col][row] = (data[col][row] - mean[row]) / std[row]
            }
        }
        
        return normal
    }
}
