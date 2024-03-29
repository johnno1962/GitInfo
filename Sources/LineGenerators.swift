//
//  LineGenerators.swift
//  refactord
//
//  Created by John Holdsworth on 19/12/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/siteify/siteify/LineGenerators.swift#7 $
//
//  Repo: https://github.com/johnno1962/Refactorator
//

import Foundation

class TaskGenerator: FileGenerator {

    let task: Process

    convenience init(command: String, directory: String? = nil, lineSeparator: String? = nil) {
        self.init(launchPath: "/bin/bash", arguments: ["-c", "exec \(command)"], directory: directory, lineSeparator: lineSeparator)
    }

    convenience init(launchPath: String, arguments: [String] = [], directory: String? = nil, lineSeparator: String? = nil) {

        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.currentDirectoryPath = directory ?? "."

        self.init(task: task, lineSeparator: lineSeparator)
    }

    init(task: Process, lineSeparator: String? = nil) {

        self.task = task

        let pipe = Pipe()
        task.standardOutput = pipe.fileHandleForWriting
        task.launch()

        pipe.fileHandleForWriting.closeFile()
        super.init(fileHandle: pipe.fileHandleForReading, lineSeparator: lineSeparator)
    }

    deinit {
        task.terminate()
    }

}

class FileGenerator: IteratorProtocol {

    let lineTerminator: Int32
    let fileHandle: FileHandle
    let readBuffer = NSMutableData()

    convenience init?(path: String, lineSeparator: String? = nil) {
        guard let fileHandle = FileHandle(forReadingAtPath: path ) else { return nil }
        self.init(fileHandle: fileHandle, lineSeparator: lineSeparator)
    }

    init(fileHandle: FileHandle, lineSeparator: String? = nil) {
        self.lineTerminator = Int32((lineSeparator ?? "\n").utf8.first!)
        self.fileHandle = fileHandle
    }

    func allOutput() -> String? {
        return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
    }

    func next() -> String? {
        while true {
            if let endOfLine = memchr(readBuffer.bytes, lineTerminator, readBuffer.length) {
                let endOfLine = endOfLine.assumingMemoryBound(to: Int8.self)
                endOfLine[0] = 0

                let start = readBuffer.bytes.assumingMemoryBound(to: Int8.self)
                let line = String(cString: start)

                let consumed = NSMakeRange(0, UnsafePointer<Int8>(endOfLine) + 1 - start)
                readBuffer.replaceBytes(in: consumed, withBytes: nil, length:0)

                return line
            }

            let bytesRead = fileHandle.availableData
            if bytesRead.count <= 0 {
                if readBuffer.length != 0 {
                    let last = String.fromData(data: readBuffer)
                    readBuffer.length = 0
                    return last
                } else {
                    break
                }
            }

            readBuffer.append(bytesRead)
        }
        return nil
    }

    var sequence: AnySequence<String> {
        return AnySequence({self})
    }

    deinit {
        fileHandle.closeFile()
    }
}

extension String {

    static func fromData(data: NSData, encoding: String.Encoding = .utf8) -> String? {
        return NSString(data: data as Data, encoding: encoding.rawValue) as String?
    }

}
