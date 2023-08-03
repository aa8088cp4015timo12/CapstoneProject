//
//  InputData.swift
//  CapstoneProject Watch App
//
//  Created by KNUSW_2 on 2023/08/01.
//

import Foundation
import CoreML

class InputData: MLFeatureProvider {
    let inputData: [[Float]]
    
    init(inputData: [[Float]]) {
        self.inputData = inputData
    }
    
    var featureNames: Set<String> {
        get {
            return ["inputData"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "inputData" {
            guard let inputDataArray = try? MLMultiArray(shape: [1, 8, 1000], dataType: .float32) else {
                fatalError("Unexpected runtime error. MLMultiArray")
            }
            return MLFeatureValue(multiArray: inputDataArray)
        }
        return nil
    }
}
