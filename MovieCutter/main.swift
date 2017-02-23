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
let startTime = IntOption(shortFlag: "s", longFlag: "starttime", required: false,
                          helpMessage: "star time in seconds, if the value is less than 0, then calculate duration form the end")
let durationTime = IntOption(shortFlag: "d", longFlag: "duration", required: false,
                          helpMessage: "duration time in seconds")

let help = BoolOption(shortFlag: "h", longFlag: "help",
                      helpMessage: "Prints a help message.")

cli.addOptions(inFile, outFile, startTime, durationTime, help)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

print("inFile is \(inFile.value!)")
print("outFile is \(outFile.value!)")
print("startTime is \(startTime.value!)")
print("durationTime is \(durationTime.value!)")

let movieCutter = MovieCutter(inFile.value!)

print("movieLength is \(movieCutter.movieLength())")

let sema = DispatchSemaphore(value: 0)

var processFinished = false

movieCutter.cropMovie(output: outFile.value!, startTime: Float(startTime.value!), durationTime: Float(durationTime.value!)) { (finished) in
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



