//
//  main.swift
//  regression
//
//  Created by Gia Duc on 10/07/2023.
//

import Foundation

struct Vector : Codable {
    private var points : [Double]

    var size: Int {
        points.count
    }

    init(_ size : Int) {
        points = Array(
            repeating: 0, count: size)
    }
    
    mutating func randomise() {
        for i in 0..<size {
            points[i] = Double.random(in: 0...1)
        }
    }
    
    mutating func scaleBy(_ factor : Double) {
        for i in 0..<size {
            points[i] *= factor
        }
    }
    
    mutating func subtract(_ v : Vector) {
        for i in 0..<size {
            points[i] -= v[i]
        }
    }
 
    static func *(v1 : Vector, v2 : Vector) -> Double {
        var total : Double = 0

        for i in (0..<v1.size) {
            total += (v1[i] * v2[i])
        }

        return total
    }

    subscript(index : Int) -> Double {
        get {
            points[index]
        }
        set(value) {
            points[index] = value
        }
    }
}

protocol Regression {
    func predict(_ x : Vector) throws -> Double
    func cost(dataset : [(Vector, Double)]?) throws -> Double
    func train(
        learningRate : Double,
        iteration : Int,
        maxToSave : Int) throws

    func saveParams() throws
    func loadParams() throws

    init(_ alias : String, _ dataset : [(Vector, Double)])
}

enum LRError : Error {
    case wrongSize
}

struct LRParameter : Codable {
    private var w : Vector
    private var b : Double
    
    init(featureSize : Int) {
        b = Double.random(in: 0...1)
        w = Vector(featureSize)
        w.randomise()
    }
    
    var featureSize : Int {
        return w.size
    }
    
    func predict(x : Vector) throws -> Double {
        if w.size != x.size {
            throw LRError.wrongSize
        }
        
        return w * x + b
    }
    
    mutating func update(
        _ deltaW : Vector,
        _ deltaB : Double,
        _ learningRate: Double,
        _ datasetSize : Int) {
            w.subtract(deltaW)
            b -= (deltaB * learningRate / Double(datasetSize))
        }
}

class LinearRegression : Regression {
    private let alias : String
    private var param : LRParameter
    private let dataset : [(Vector, Double)]
    
    required init(_ alias: String, _ dataset : [(Vector, Double)]) {
        self.alias = alias
        self.dataset = dataset
        self.param = LRParameter(featureSize: dataset[0].0.size)
    }
    
    func predict(_ x: Vector) throws -> Double {
        return try param.predict(x: x)
    }
    
    func cost(dataset : [(Vector, Double)]?) throws -> Double {
        var cost = 0.0
        
        var consideringData : [(Vector, Double)]
        
        if dataset != nil {
            consideringData = dataset!
        }
        else {
            consideringData = self.dataset
        }
        
        let m = consideringData.count
        
        for trainPoint in consideringData {
            let yHat = try predict(trainPoint.0)
            
            cost += (yHat - trainPoint.1) * (yHat - trainPoint.1)
        }
        
        return cost / (2.0 * Double(m))
    }
    
    func train(
        learningRate : Double,
        iteration: Int,
        maxToSave : Int) throws{
            for index in 0..<iteration {
                var deltaW = Vector(param.featureSize)
                var deltaB : Double = 0
                
                for data in dataset {
                    let error = (try predict(data.0) - data.1)
                    
                    for featureIndex in 0..<(param.featureSize) {
                        deltaW[featureIndex] += data.0[featureIndex] * error
                    }
                    
                    deltaB += error
                }
                
                deltaW.scaleBy(learningRate / Double(dataset.count))
                
                param.update(deltaW, deltaB, learningRate, dataset.count)
                
                if (index + 1) % maxToSave == 0 {
                    print("Iteration : \(index + 1). Cost: \(try cost(dataset: nil))")
                }
            }
        }
    
    func saveParams() throws{

    }
    
    func loadParams() {
        
    }
}

var reader = ExcelReader("/Users/giaduc/Desktop/advertising.xlsx")

let dataset = try reader.split(3, 0.7)

let trainSet = dataset.0
let testSet = dataset.1

let model = LinearRegression("lr", trainSet)

try model.train(learningRate: 0.00006, iteration: 150, maxToSave: 5)

print("Cost on test set: \(try model.cost(dataset: testSet))")
