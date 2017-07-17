//
//  MovieCutter.swift
//  MovieCutter
//
//  Created by hanxiaoming on 17/2/23.
//  Copyright © 2017年 Amap. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

class MovieCutter {
    var inputFile: String?
    var asset: AVAsset?
    let dispatchQueue: DispatchQueue!
    
    var videoComposition: AVMutableVideoComposition?
    var composition: AVMutableComposition?
    
    init(_ input: String?) {
        self.inputFile = input
        
        if (inputFile != nil) {
            self.asset = AVAsset(url: URL(fileURLWithPath: inputFile!))
        }
        dispatchQueue = DispatchQueue(label: "com.hades.writequeue")
        
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
        
        print("start trimming...")
        
        let assetVideoTrack = asset!.tracks(withMediaType: AVMediaTypeVideo).first;
        let assetAudioTrack = asset!.tracks(withMediaType: AVMediaTypeAudio).first;
        
        let movieLength = self.movieLength()
        var modifiedStart = startTime
        var modifiedDuration = durationTime
        
        if modifiedDuration < 0.0 {
            modifiedDuration = movieLength
        }
        
        if modifiedStart < 0.0 {
            modifiedStart = movieLength - modifiedDuration
        }
        
        if modifiedStart < 0.0 {
            modifiedStart = 0.0
        }
        
        if modifiedStart > movieLength {
            modifiedStart = movieLength
        }
      
        if modifiedStart + modifiedDuration > movieLength {

            modifiedDuration = movieLength - modifiedStart
        }

        let scale = asset!.duration.timescale
        
        let start = CMTimeMakeWithSeconds(modifiedStart, scale)
        let duration = CMTimeMakeWithSeconds(modifiedDuration, scale)
        let timeRange = CMTimeRange(start: start, duration: duration)
        
        print("trim time range :\(modifiedStart)-\(modifiedDuration)")
        
        if self.composition == nil {
            self.composition = AVMutableComposition()
            if assetVideoTrack != nil {
                let compositionVideoTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionVideoTrack.insertTimeRange(timeRange, of: assetVideoTrack!, at: kCMTimeZero)
                }
                catch {
                    print("add video track error :\(error)")
                }
            }
            if assetAudioTrack != nil {
                let compositionAudioTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: assetAudioTrack!, at: kCMTimeZero)
                }
                catch {
                    print("add audio track error :\(error)")
                }
            }
        }
        else {
            
            self.composition!.removeTimeRange(CMTimeRangeMake(kCMTimeZero, start))
            
            // 尾部有剩余
            if modifiedStart + modifiedDuration < movieLength {
                
                let endStart = CMTimeMakeWithSeconds(modifiedDuration, scale)
                let endDuration = CMTimeMakeWithSeconds((movieLength - modifiedStart - modifiedDuration), scale)
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
            print("export done, status \(exportSession.status.rawValue), error \(String(describing: exportSession.error))")
            switch exportSession.status {
            case .completed:
                completionHandler(true)
                print("exported at \(output!)")
            case .failed:
                completionHandler(false)
                print("failed \(String(describing: exportSession.error))")
            case .cancelled:
                completionHandler(false)
                print("cancelled \(String(describing: exportSession.error))")
                
            default:
                completionHandler(false)
                break
            }
        }

    }
    
    func exportMovieWithCompression(output: String!, width: Double, height: Double, compressRatio: Double, completionHandler: @escaping (Bool) -> Void) {
        
        print("start exporting...")
        
        let assetVideoTrack = asset!.tracks(withMediaType: AVMediaTypeVideo).first;
        let assetAudioTrack = asset!.tracks(withMediaType: AVMediaTypeAudio).first;
        
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset!.duration)
        
        if self.composition == nil {
            self.composition = AVMutableComposition()
            if assetVideoTrack != nil {
                let compositionVideoTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionVideoTrack.insertTimeRange(timeRange, of: assetVideoTrack!, at: kCMTimeZero)
                }
                catch {
                    print("add video track error :\(error)")
                }
            }
            if assetAudioTrack != nil {
                let compositionAudioTrack = composition!.addMutableTrack(withMediaType:AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                do {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: assetAudioTrack!, at: kCMTimeZero)
                }
                catch {
                    print("add audio track error :\(error)")
                }
            }
        }

        if self.composition?.tracks.count == 0 {
            print("there is no track, invalid asset: \(asset!)")
            completionHandler(false)
            return
        }
        
        let manager = FileManager.default
        
        let outPath = URL(fileURLWithPath: output!)
        //Remove existing file
        _ = try? manager.removeItem(at: outPath)
        
        // writer
        let assetWriter = try? AVAssetWriter(url: outPath, fileType: AVFileTypeMPEG4)
        
        let naturalSize = self.composition!.naturalSize
        let targetSize = CGSize(width: width, height: height)
        
        var bitrate = naturalSize.width * naturalSize.height * CGFloat(compressRatio)
        
        if bitrate <= 0.0 {
            bitrate = 1.0
        }
        
//        let keyFrameInterval: Int = 30
        let videoSettings = [AVVideoCodecKey: AVVideoCodecH264,
                             AVVideoWidthKey: targetSize.width,
                             AVVideoHeightKey: targetSize.height,
                             AVVideoCompressionPropertiesKey:
                                [//AVVideoMaxKeyFrameIntervalKey: keyFrameInterval,
                                 AVVideoAverageBitRateKey: bitrate,
                                 AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31]
            ] as [String : Any]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        
        if assetWriter!.canAdd(videoWriterInput) {
            assetWriter!.add(videoWriterInput)
            
            // reader
            let assetReader = try? AVAssetReader(asset: composition!)
            
            let readerSetting: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB]
            
            // add video output
            let videoAssetTrackOutput = AVAssetReaderTrackOutput(track: composition!.tracks(withMediaType: AVMediaTypeVideo).first!, outputSettings: readerSetting)
            videoAssetTrackOutput.alwaysCopiesSampleData = false
            
            if assetReader!.canAdd(videoAssetTrackOutput) {
                assetReader!.add(videoAssetTrackOutput)
                
                if assetAudioTrack != nil {
                    // add audio output
                    let audioAssetTrackOutput = AVAssetReaderTrackOutput(track: assetAudioTrack!, outputSettings: nil)
                    audioAssetTrackOutput.alwaysCopiesSampleData = false
                    
                    if assetReader!.canAdd(audioAssetTrackOutput) {
                        assetReader!.add(audioAssetTrackOutput)
                    }
                } // end assetAudio
                
                
                assetWriter!.startWriting()
                assetWriter!.startSession(atSourceTime: kCMTimeZero)
                
                if assetReader!.startReading() {

                    let encodingGroup = DispatchGroup()
                    encodingGroup.enter()
                    
                    let targetFPS: Float = 15.0
                    let originFPS = assetVideoTrack!.nominalFrameRate
                    
                    let frameRate: Int = Int(originFPS / targetFPS)
                    var idx = 0
                    
                    videoWriterInput.requestMediaDataWhenReady(on: dispatchQueue, using: {
                        
                        while videoWriterInput.isReadyForMoreMediaData {
                            let nextSampleBuffer: CMSampleBuffer? = videoAssetTrackOutput.copyNextSampleBuffer()
                            if nextSampleBuffer != nil {
                                
                                var count: CMItemCount = 0

                                if frameRate == 0 || idx % frameRate == 0 {
                                
                                    CMSampleBufferGetSampleTimingInfoArray(nextSampleBuffer!, 0, nil, &count)
                                    var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)), count: count)
                                    CMSampleBufferGetSampleTimingInfoArray(nextSampleBuffer!, count, &info, &count)
                                    
                                    for i in 0..<count {

                                        var newTimeStamp = CMTimeMake(0, 1)
                                        
                                        if idx > 0 {
                                            
                                            let newValue = Float64(info[i].presentationTimeStamp.value) / Float64(info[i].presentationTimeStamp.timescale)
                                            
                                            newTimeStamp = CMTimeMakeWithSeconds(newValue, 600)
                                        }
                                        
//                                        CMTimeShow(info[i].presentationTimeStamp)
//                                        CMTimeShow(newTimeStamp)
                                        info[i].decodeTimeStamp = kCMTimeInvalid
                                        info[i].presentationTimeStamp = newTimeStamp
                                    }
                                    
                                    var outBuffer: CMSampleBuffer?
                                    CMSampleBufferCreateCopyWithNewTiming(nil, nextSampleBuffer!, count, &info, &outBuffer)
                                    videoWriterInput.append(outBuffer!)
                                }
                                idx = idx+1
                            }
                            else {
                             
                                videoWriterInput.markAsFinished()
                                encodingGroup.leave()
                                break
                            }
                        } //end while
                    })
                    
                    _ = encodingGroup.wait(timeout: DispatchTime.distantFuture)
                } // end start reading
                
            }
        }
        
        assetWriter!.finishWriting {

            completionHandler(true)
        }
    }
}
