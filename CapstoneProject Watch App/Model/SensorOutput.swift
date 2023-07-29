//
//  SensorOutput.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/07/29.
//

import Foundation

class SensorOutput {
    let gyroX : Float
    let gyroY : Float
    let gyroZ : Float
     
    let accX : Float
    let accY : Float
    let accZ : Float
    
    let gyroScala : Float
    let AccScala : Float
    
    init(_ gyroX: Float, _ gyroY: Float, _ gyroZ: Float, _ accX: Float, _ accY: Float, _ accZ: Float) {
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
        self.accX = accX
        self.accY = accY
        self.accZ = accZ
        
        self.gyroScala = sqrt(pow(gyroX, 2) + pow(gyroY, 2) + pow(gyroZ, 2))
        self.AccScala = sqrt(pow(accX, 2) + pow(accY, 2) + pow(accZ, 2))
    }
}
