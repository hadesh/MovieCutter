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
    
    var videoComposition: AVMutableVideoComposition?
    var composition: AVMutableComposition?
    
    init(_ input: String?) {
        self.inputFile = input
        
        if (inputFile != nil) {
            self.asset = AVAsset(url: URL(fileURLWithPath: inputFile!))
        }
    }
    
    func movieLength() -> Double {
        if asset == nil {
            return 0.0
        }
        
        return Double(asset!.duration.value) / Double(asset!.duration.timescale)
    }
    
    
    func trimMovie(startTime: Double, durationTime: Double) {
        
        if asset == nil {
            return
        }
        
        print("start triming...")
        
        let assetVideoTrack = asset!.tracks(withMediaType: AVMediaTypeVideo).first;
        let assetAudioTrack = asset!.tracks(withMediaType: AVMediaTypeAudio).first;
        
        
        var modifiedStart = startTime
        
        if modifiedStart < 0.0 {
            modifiedStart = self.movieLength() - durationTime
        }
        
        var modifiedDuration = durationTime
        if modifiedStart + modifiedDuration > self.movieLength() {
            modifiedDuration = self.movieLength() - modifiedStart
        }

        let start = CMTimeMakeWithSeconds(modifiedStart, 1)
        let dutation = CMTimeMakeWithSeconds(modifiedDuration, 1)
        let timeRange = CMTimeRange(start: start, duration: dutation)
        
        
        if self.composition == nil {
            self.composition = AVMutableComposition()
            if assetVideoTrack != nil {
                let compositionVideoTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionVideoTrack.insertTimeRange(timeRange, of: assetVideoTrack!, at: kCMTimeZero)
                }
                catch {
                    print("error :\(error)")
                }
            }
            if assetAudioTrack != nil {
                let compositionAudioTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: assetAudioTrack!, at: kCMTimeZero)
                }
                catch {
                    print("error :\(error)")
                }
            }
        }
        else {
            
            self.composition!.removeTimeRange(CMTimeRangeMake(kCMTimeZero, start))
            
            // 尾部有剩余
            if modifiedStart + modifiedDuration < self.movieLength() {
                
                let endStart = CMTimeMakeWithSeconds(modifiedDuration, 1)
                let endDuration = CMTimeMakeWithSeconds(self.movieLength() - modifiedStart - modifiedDuration, 1)
                self.composition!.removeTimeRange(CMTimeRangeMake(endStart, endDuration))
            }
        }
        
    }
    
    func cropMovie(width: Double, height: Double, fps: Int) {
        if asset == nil {
            return
        }
        
        print("start cropping...")
        
        let assetVideoTrack = asset!.tracks(withMediaType: AVMediaTypeVideo).first;
        let assetAudioTrack = asset!.tracks(withMediaType: AVMediaTypeAudio).first;
        
        if self.composition == nil {
            let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset!.duration)
            self.composition = AVMutableComposition()
            if assetVideoTrack != nil {
                let compositionVideoTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionVideoTrack.insertTimeRange(timeRange, of: assetVideoTrack!, at: kCMTimeZero)
                }
                catch {
                    print("error :\(error)")
                }
            }
            if assetAudioTrack != nil {
                let compositionAudioTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: assetAudioTrack!, at: kCMTimeZero)
                }
                catch {
                    print("error :\(error)")
                }
            }
        }
        
        let originalSize = self.composition!.naturalSize
        
        var instruction: AVMutableVideoCompositionInstruction?
        var layerInstruction: AVMutableVideoCompositionLayerInstruction?
        var t1: CGAffineTransform?
        
        
        if self.videoComposition == nil {
            // Create a new video composition
            self.videoComposition = AVMutableVideoComposition()
            
            self.videoComposition!.frameDuration = CMTimeMake(1, Int32(fps))
            self.videoComposition!.renderSize = CGSize(width: width, height: height)
            
            
            instruction = AVMutableVideoCompositionInstruction()
            instruction!.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition!.duration)
            
            layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: (self.composition!.tracks.first)!)

            t1 = CGAffineTransform(scaleX: CGFloat(width) / originalSize.width, y: CGFloat(height) / originalSize.height)
            
            layerInstruction!.setTransform(t1!, at: kCMTimeZero)
        }
        else {
            
            self.videoComposition!.renderSize = CGSize(width: width, height: height)
            
            // Extract the existing layer instruction on the mutableVideoComposition
            instruction = self.videoComposition!.instructions.first as! AVMutableVideoCompositionInstruction?
            layerInstruction = instruction?.layerInstructions.first as! AVMutableVideoCompositionLayerInstruction?
            
            var existingTransform: CGAffineTransform = CGAffineTransform()
            
            if layerInstruction!.getTransformRamp(for: self.composition!.duration, start: &existingTransform, end: nil, timeRange: nil) {
                
                t1 = CGAffineTransform(scaleX: CGFloat(width) / originalSize.width, y: CGFloat(height) / originalSize.height)
                
                let newTransform = existingTransform.concatenating(t1!)
                layerInstruction!.setTransform(newTransform, at: kCMTimeZero)
            }
            else {
                t1 = CGAffineTransform(scaleX: CGFloat(width) / originalSize.width, y: CGFloat(height) / originalSize.height)
                
                layerInstruction!.setTransform(t1!, at: kCMTimeZero)
            }
        }
        
        instruction!.layerInstructions = [layerInstruction!]
        self.videoComposition!.instructions = [instruction!]

    }
    
    func exportMovie(output: String!, completionHandler: @escaping (Bool) -> Void) {
        
        if asset == nil || self.composition == nil {
            
            print("invalid params")
            return
        }
        
        let manager = FileManager.default
        
        let outPath = URL(fileURLWithPath: output!)
        //Remove existing file
        _ = try? manager.removeItem(at: outPath)
        
        guard let exportSession = AVAssetExportSession(asset: self.composition!.copy() as! AVAsset, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = outPath
        exportSession.outputFileType = AVFileTypeMPEG4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.videoComposition = self.videoComposition
        
        print("start exporting...")
        exportSession.exportAsynchronously {
            print("export done, status \(exportSession.status.rawValue), error \(exportSession.error)")
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
