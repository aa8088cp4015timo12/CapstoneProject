//
//  Preprocessor.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/29.
//

import Foundation

class Preprocessor {
    var SensorOutputs: [SensorOutput]
    init(_ input: [SensorOutput]) {
        self.SensorOutputs = input
    }
    func saveTorchRawData() -> ([[Float]], [[Float]]) {
        if SensorOutputs.isEmpty {
            return ( [], [])
        }
        let maxLen: Int = 1000
        let dataDecode: [[Float]] = decode()
        let filterNum: Int = Int(ceil(Double(SensorOutputs.count) / Double(maxLen)))
        
        
        // rollin
        print("smoothing")
        var data: [[Float]] = []
        for _ in 0..<filterNum-1 {
            data.append([0, 0, 0, 0, 0, 0, 0, 0])
        }
        for row in 0..<SensorOutputs.count-filterNum+1 {
            data.append(getMeanFromTo(data: dataDecode, from: row, to: row + filterNum))
        }
        
        
        
        print("sampling filterNum: \(filterNum)")
        data = sampling(data: data, samplingNum: filterNum)
        for n in 0..<data[0].count {
            data[0][n] = 0.0
        }
        
        print("lfilter")
        var data5 = lfilterN(data: data, n: 5)
        var data6 = lfilterN(data: data5, n: 6)
        
        for i in 0..<5 {
            for j in 0..<data5[0].count {
                data5[i][j] = 0.0
            }
        }
        
        for i in 0..<10 {
            for j in 0..<data6[0].count {
                data6[i][j] = 0.0
            }
        }
        
        // normalization
        print("정규화")
        data5 = normalization(data: data5, mean: getMeanWithoutNan(data: data5, from: 0, to: data5.count), std: getStd(data: data5))
        data6 = normalization(data: data6, mean: getMeanWithoutNan(data: data6, from: 0, to: data6.count), std: getStd(data: data6))
        print("IF")
        if data.count < maxLen {
            let pad: [Float] = [Float](repeating: 0.0, count: 8)
            // cat_df = pd.concat([data, pad], axis=0).reset_index()
            for _ in 0..<(maxLen - data5.count) {
                data5.append(pad)
            }
            // cat_df_n6 = pd.concat([data_n6, pad], axis=0).reset_index()
            for _ in 0..<(maxLen - data6.count) {
                data6.append(pad)
            }
        }
        return (data5, data6)
    }
    
    private func decode() -> [[Float]] {
        var tempArray2D: [[Float]] = []
        
        var tempAcc: Float = 0.0
        var tempGyro: Float = 0.0
        
        tempArray2D.append(append1D(i: 0, accScala: SensorOutputs[0].accScala, gyroScala: SensorOutputs[0].gyroScala))
        for i in 1...SensorOutputs.count-2 {
            for n in i-1...i+1 {
                tempAcc += SensorOutputs[n].accScala
                tempGyro += SensorOutputs[n].gyroScala
            }
            tempArray2D.append(append1D(i: i, accScala: tempAcc/3, gyroScala: tempGyro/3))
            tempAcc = 0.0
            tempGyro = 0.0
        }
        print("Sensorout.count: \(SensorOutputs.count)")
        let val = SensorOutputs.count - 1
        tempArray2D.append(append1D(i: val, accScala: SensorOutputs[val].accScala, gyroScala: SensorOutputs[val].gyroScala))
        return tempArray2D
    }
    
    private func append1D(i: Int, accScala: Float, gyroScala: Float) ->[Float] {
        var tempArray1D: [Float] = []
        tempArray1D.append(SensorOutputs[i].accX)
        tempArray1D.append(SensorOutputs[i].accY)
        tempArray1D.append(SensorOutputs[i].accZ)
        tempArray1D.append(SensorOutputs[i].gyroX)
        tempArray1D.append(SensorOutputs[i].gyroY)
        tempArray1D.append(SensorOutputs[i].gyroZ)
        tempArray1D.append(accScala)
        tempArray1D.append(gyroScala)
        return tempArray1D
    }
    
    private func lfilterN(data: [[Float]], n: Int) -> [[Float]] {
        var array: [[Float]] = []
        let b = [Float](repeating: 1.0 / Float(n) , count: n)
        let a: Float = 1
        
        var tempArray: [Float] = []
        
        for col in 0..<data[0].count {
            for n in 0..<data.count {
                tempArray.append(data[n][col])
            }
            array.append(lfilter(b: b, a: a, x: tempArray))
            tempArray = []
        }
        return matrixTranspose(array)
    }
    
    private func lfilter(b: [Float], a: Float, x: [Float]) -> [Float]{
        let n = b.count
        var x2 = [Float](repeating: 0.0, count: x.count)
        
        for idx in 0..<x.count {
            var sum : Float = 0.0
            for i in 0..<Int(n) {
                if idx-i < 0 {
                    break
                }
                sum += b[i] * x[idx-i]
            }
            x2[idx] = sum
        }
        return x2
    }
    private func matrixTranspose<T>(_ matrix: [[T]]) -> [[T]] {
        if matrix.isEmpty {return matrix}
        var result = [[T]]()
        for index in 0..<matrix.first!.count {
            result.append(matrix.map{$0[index]})
        }
        return result
    }
    private func sampling(data: [[Float]], samplingNum: Int) -> [[Float]] {
        var sampledData: [[Float]] = []
        let len = SensorOutputs.count
        for row in stride(from: 0, to: len, by: samplingNum) {
            if row + samplingNum > len {
                let extraRaw = row + samplingNum - len
                sampledData.append(getMeanFromTo(data: data, from: row, to: row + extraRaw))
            }
            else {
                sampledData.append(getMeanFromTo(data: data, from: row, to: row + samplingNum))
            }
        }
        return sampledData
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
    
    private func getMeanWithoutNan(data: [[Float]], from: Int, to: Int) -> [Float] {
        var tempAccX: Float = 0.0
        var tempAccY: Float = 0.0
        var tempAccZ: Float = 0.0
        
        var tempGyroX: Float = 0.0
        var tempGyroY: Float = 0.0
        var tempGyroZ: Float = 0.0
        
        var tempAccScala: Float = 0.0
        var tempGyroScala: Float = 0.0
        
        var size: Float = 0
        let zeroFloat = Float(0)
        for row in from..<to {
            if data[row][0] != zeroFloat {
                tempAccX += data[row][0]
                tempAccY += data[row][1]
                tempAccZ += data[row][2]
                
                tempGyroX += data[row][3]
                tempGyroY += data[row][4]
                tempGyroZ += data[row][5]
                
                tempAccScala += data[row][6]
                tempGyroScala += data[row][7]
                
                size = size + 1
            }
        }
        
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
        let variance: [Float] = getMeanWithoutNan(data: deviation, from: 0, to: deviation.count)
        
        return variance.map { sqrtf($0) }
    }
    
    private func normalization(data: [[Float]], mean: [Float], std: [Float]) -> [[Float]] {
        var normal: [[Float]] = [[Float]](repeating: (Array(repeating: 0.0, count: data[0].count)), count: data.count)
        let zeroFloat = Float(0.0)
        for col in 0..<data.count {
            if data[col][0] != zeroFloat {
                for row in 0..<data[0].count {
                    normal[col][row] = (data[col][row] - mean[row]) / std[row]
                }
            } else {
                for row in 0..<data[0].count {
                    normal[col][row] = zeroFloat
                }
            }
        }
        
        return normal
    }
}
