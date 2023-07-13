//
//  ExcelReader.swift
//  regression
//
//  Created by Gia Duc on 10/07/2023.
//

import Foundation
import CoreXLSX

struct ExcelReader {
    private let filePath : String
    
    init(_ filePath : String) {
        self.filePath = filePath
    }
    
    func split(
        _ labelColIndex : Int,
        _ trainPercent : Double) throws -> ([(Vector, Double)], [(Vector, Double)]) {
            var trainSet : [(Vector, Double)] = []
            var testSet : [(Vector, Double)] = []
            
            guard let file = XLSXFile(filepath: filePath)
            else {
              fatalError("XLSX file at \(filePath) is corrupted or does not exist")
            }

            for wbk in try file.parseWorkbooks() {
                for (_, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                    let worksheet = try file.parseWorksheet(at: path)
                    
                    let rows = worksheet.data?.rows
                    let trainSize = Int(Double(rows!.count) * trainPercent)
                    
                    for (rowIndex, row) in (rows ?? []).enumerated() {
                        if rowIndex == 0 {
                            continue
                        }

                        var v = Vector(row.cells.count - 1) // account for label column
                        
                        var y = 0.0
                        var vIndex = 0
                        
                        for (index, c) in row.cells.enumerated() {
                            if index != labelColIndex {
                                v[vIndex] = Double(c.value!)!
                                vIndex += 1
                            }
                            else {
                                y = Double(c.value!)!
                            }
                        }
                        
                        if rowIndex < trainSize {
                            trainSet.append((v, y))
                        }
                        else {
                            testSet.append((v, y))
                        }
                    }
                }
            }
            
            return (trainSet, testSet)
        }
}

