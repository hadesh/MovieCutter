//
//  main.swift
//  MovieCutter
//
//  Created by hanxiaoming on 17/2/23.
//  Copyright © 2017年 Amap. All rights reserved.
//

import Foundation

let cli = CommandLine()

let inFile = StringOption(shortFlag: "i", longFlag: "input",
                         helpMessage: "input movie path")
let outFile = StringOption(shortFlag: "o", longFlag: "output",
                         helpMessage: "output movie path")
let startTime = DoubleOption(shortFlag: "s", longFlag: "starttime", required: false,
                          helpMessage: "star time in seconds, if the value is less than 0, then calculate duration form the end")
let durationTime = DoubleOption(shortFlag: "d", longFlag: "duration", required: false,
                          helpMessage: "duration time in seconds")

let cropWidth = DoubleOption(shortFlag: "w", longFlag: "width", required: false,
                             helpMessage: "crop width")
let cropHeight = DoubleOption(shortFlag: "h", longFlag: "height", required: false,
                                helpMessage: "crop height")

let fps = IntOption(shortFlag: "f", longFlag: "fps", required: false,
                              helpMessage: "fps, default is 30")

let help = BoolOption(shortFlag: "h", longFlag: "help",
                      helpMessage: "Prints a help message.")

cli.addOptions(inFile, outFile, startTime, durationTime, help)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

var input = inFile.value

if input == nil {
    input = "/Users/hanxiaoming/Desktop/Result/iOS-cluster-marker.mp4"
}

var output = outFile.value

if output == nil {
    output = "/Users/hanxiaoming/Desktop/Result/aaaa.mp4"
}

var start = startTime.value

if start == nil {
    start = 10
}
var duration = durationTime.value

if duration == nil {
    duration = 20
}

var width = cropWidth.value

if width == nil {
    width = 512
}
var height = cropHeight.value

if height == nil {
    height = 920
}

var f = fps.value

if f == nil {
    f = 10
}


let movieCutter = MovieCutter(input)

print("movieLength is \(movieCutter.movieLength())")

let sema = DispatchSemaphore(value: 0)

var processFinished = false

// 先trim后crop
movieCutter.trimMovie(startTime: start!, durationTime: duration!)
movieCutter.cropMovie(width: width!, height: height!, fps: f!)

movieCutter.exportMovie(output: output!) { (finished) in
    processFinished = finished
    sema.signal()
}

sema.wait();

if processFinished {
    print("*** Suceess ***")
    exit(EXIT_SUCCESS)
}
else {
    print("*** Failure ***")
    exit(EXIT_FAILURE)
}



