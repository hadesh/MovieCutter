//
//  MovieCutter.swift
//  MovieCutter
//
//  Created by hanxiaoming on 17/2/23.
//  Copyright © 2017年 Amap. All rights reserved.
//

import Foundation
import AVFoundation

class MovieCutter {
    var inputFile: String?
    var asset: AVAsset?
    
    init(_ input: String?) {
        self.inputFile = input
        
        if (inputFile != nil) {
            self.asset = AVAsset(url: URL(fileURLWithPath: inputFile!))
        }
    }
    
    func movieLength() -> Float {
        if asset == nil {
            return 0.0
        }
        
        return Float(asset!.duration.value) / Float(asset!.duration.timescale)
    }
    
    func cropMovie(output: String?, startTime: Float, durationTime: Float, completionHandler: @escaping (Bool) -> Void) {
        if output == nil || asset == nil {
            
            print("invalid params")
            return
        }
        
        let manager = FileManager.default
        
        let outPath = URL(fileURLWithPath: output!)
        //Remove existing file
        _ = try? manager.removeItem(at: outPath)
        
        guard let exportSession = AVAssetExportSession(asset: asset!, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = outPath
        exportSession.outputFileType = AVFileTypeMPEG4
        
        var modifiedStart = startTime
        
        if modifiedStart < 0.0 {
            modifiedStart = self.movieLength() - durationTime
        }
        
        
        
        let start = CMTime(seconds: Double(modifiedStart ), preferredTimescale: 1000)
        let dutation = CMTime(seconds: Double(durationTime), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: start, duration: dutation)
        
        print("time range: \(timeRange.start.seconds) - \(timeRange.duration.seconds)")
        exportSession.timeRange = timeRange
        
        print("start cropping...")
        exportSession.exportAsynchronously {
            print("export done...")
            print("status \(exportSession.status.rawValue), error \(exportSession.error)")
            switch exportSession.status {
            case .completed:
                completionHandler(true)
                print("exported at \(output!)")
            case .failed:
                completionHandler(false)
                print("failed \(exportSession.error)")
            case .cancelled:
                completionHandler(false)
                print("cancelled \(exportSession.error)")
                
            default:
                completionHandler(false)
                break
            }
        }
        
    }
    
    
    
    
    
}
