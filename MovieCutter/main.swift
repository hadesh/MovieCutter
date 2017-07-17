//
//  main.swift
//  MovieCutter
//
//  Created by hanxiaoming on 17/2/23.
//  Copyright © 2017年 Amap. All rights reserved.
//

import Foundation

let cli = CommandLine()

let inFile = StringOption(shortFlag: "i", longFlag: "input", required: true,
                         helpMessage: "input movie path.")
let outFile = StringOption(shortFlag: "o", longFlag: "output", required: true,
                         helpMessage: "output movie path.")
let startTime = DoubleOption(shortFlag: "s", longFlag: "starttime", required: false,
                          helpMessage: "star time in seconds, if the value is less than 0, then calculate duration form the end.")
let durationTime = DoubleOption(shortFlag: "d", longFlag: "duration", required: false,
                          helpMessage: "duration time in seconds. negative value for the entire duration.")

let cropWidth = DoubleOption(shortFlag: "W", longFlag: "width", required: false,
                             helpMessage: "crop width. default is 512.")
let cropHeight = DoubleOption(shortFlag: "H", longFlag: "height", required: false,
                                helpMessage: "crop height. default is 920.")

let compressRatio = DoubleOption(shortFlag: "r", longFlag: "ratio", required: false,
                              helpMessage: "compress ration, [0,1], default is 0.425")

let help = BoolOption(shortFlag: "h", longFlag: "help",
                      helpMessage: "Prints a help message.")

cli.addOptions(inFile, outFile, startTime, durationTime, cropWidth, cropHeight, compressRatio, help)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

if help.value {
    cli.printUsage()
    exit(EX_USAGE)
}

var input = inFile.value

if input == nil {
    input = ""
}

var output = outFile.value

if output == nil {
    output = ""
}

var start = startTime.value

if start == nil {
    start = -1
}
var duration = durationTime.value

if duration == nil {
    duration = -1
}

var width = cropWidth.value

if width == nil {
    width = 512
}
var height = cropHeight.value

if height == nil {
    height = 920
}

var ratio = compressRatio.value

if ratio == nil {
    ratio = 0.425
}


let movieCutter = MovieCutter(input)

print("**********")
print("name is \(URL(fileURLWithPath: input!).lastPathComponent)")
print("lenght is \(movieCutter.movieLength())")
print("size is \(width!)*\(height!)")
print("ratio is \(ratio!)")
print("**********")

let sema = DispatchSemaphore(value: 0)

var processFinished = false

// 先trim后crop
movieCutter.trimMovie(startTime: start!, durationTime: duration!)
movieCutter.exportMovieWithCompression(output: output!, width: width!, height: height!, compressRatio: ratio!) { (finished) in
        processFinished = finished
        sema.signal()
}

//movieCutter.trimMovie(startTime: start!, durationTime: duration!)
//movieCutter.cropMovie(width: width!, height: height!, fps: 15)
//
//movieCutter.exportMovie(output: output!) { (finished) in
//    processFinished = finished
//    sema.signal()
//}

sema.wait();

if processFinished {
    print("*** Suceess ***")
    exit(EXIT_SUCCESS)
}
else {
    print("*** Failure ***")
    exit(EXIT_FAILURE)
}



