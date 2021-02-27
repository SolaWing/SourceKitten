//
//  Daemon.swift
//  sourcekitten
//
//  Created by SolaWing on 2018/7/22.
//  Copyright © 2018年 SourceKitten. All rights reserved.
//

import ArgumentParser
import Foundation
import SourceKittenFramework

let stdin = StreamReader(FileHandle.standardInput)
let stdout = FileHandle.standardOutput
var stderr = FileHandle.standardError

let lock = NSLock()

func log(_ content: String) {
   // print(error, to: &stderr)
}

struct Daemon: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "run swiftkittend with input pipe")

    @Flag(help: "Enable notification")
    var enableNotification: Bool = false
    @Flag var verbose: Bool = false

    func run() throws {
        if verbose {
            enableLog = true
        }
        var package: RequestPackage? {
            return autoreleasepool {
                do {
                    let p = try getPackage()
                    return p
                } catch {
                    print(error, to: &stderr)
                }
                return nil
            }
        }
        var finished = false

        var notificationSubscribe: Any?
        defer {
            if let notificationSubscribe = notificationSubscribe {
                NotificationCenter.default.removeObserver(notificationSubscribe)
            }
        }
        if enableNotification {
            sourcekitNotificationEnabled = true
            notificationSubscribe = NotificationCenter.default.addObserver(forName: .sourcekit, object: nil, queue: nil) { notification in
                self.response(id: nil, result: notification.object, error: nil)
            }
        }
        loop: while !finished, let p = package { // swiftlint:disable:this all
            autoreleasepool {
                switch p.content["method"] as? String {
                case "yaml":
                    print("yaml request", to: &stderr)
                    self.handleYamlRequest(package: p)
                case "end":
                    print("will end", to: &stderr)
                    finished = true
                default:
                    return // ignore other method
                }
            }
        }
        print("end", to: &stderr)
    }

    func handleYamlRequest(package p: RequestPackage) {
        if let content = p.content["params"] as? String {
            let rid = p.content["id"] // 有id的是请求，没id的是不要回应的通知
            let request = Request.yamlRequest(yaml: content)
            do {
                let v = try request.send()
                if let rid = rid { response(id: rid, result: v, error: nil) }
            } catch {
                if let rid = rid { response(id: rid, result: nil, error: error.localizedDescription) }
            }
        } else {
            response(id: p.content["id"], result: nil, error: "Invalid yaml request")
        }
    }

    func getPackage() throws -> RequestPackage {
        var headers = RequestHeader()
        while let s = stdin.readLine() {
            if s.isEmpty { break }
            if let m = requestHeaderRegex.firstMatch(in: s, options: [], range: NSRange(location: 0, length: s.count)),
                let r1 = Range(m.range(at: 1), in: s),
                let r2 = Range(m.range(at: 2), in: s) {
                headers[String(s[r1])] = String(s[r2])
            }
        }
        if let s = headers["Content-Length"], let content_length = Int(s) {
            if content_length < 10 || content_length > (8 << 20) {
                throw DaemonError.invalidContentLength(content_length)
            }
            let d = stdin.readData(ofLength: content_length)
            if let content = try JSONSerialization.jsonObject(with: d, options: []) as? [String: Any] {
                return RequestPackage(header: headers, content: content)
            } else {
                throw DaemonError.invalidRequestHeader
            }
        } else {
            throw DaemonError.invalidRequestHeader
        }
    }

    private func response(id: Any?, result: Any?, error: String?) {

        var r = [String: Any]()
        if let id = id {
            r["id"] = id
        }
        if let c = result {
            r["result"] = c
        }
        if let e = error {
            r["error"] = e
        }

        let d = try! JSONSerialization.data(withJSONObject: r, options: [])

        log("will repsonse: \(r)")

        lock.lock(); defer { lock.unlock() }
        stdout.write("Content-Length:\(d.count)\r\n\r\n")
        stdout.write(d)
    }
}

typealias RequestHeader = [String: String]
let requestHeaderRegex = try! NSRegularExpression(pattern: "(\\S+)\\s*:\\s*(\\S+)")
struct RequestPackage {
    let header: RequestHeader
    let content: [String: Any]
}

enum DaemonError: Error {
    case invalidRequestHeader
    case invalidContentLength(Int)
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        self.write(string.data(using: String.Encoding.utf8)!)
    }
}

class StreamReader {
    let handler: FileHandle
    var buffer = Data(capacity: 0x10)
    init(_ handler: FileHandle) {
        self.handler = handler
    }

    func readLine(strippingNewline: Bool = true) -> String? {

        var used = Data()
        var newData = buffer
        repeat {
            if let index = newData.firstIndex(of: 10) {
                used.append(newData[...index])

                buffer = newData[(index + 1)...]
                break
            } else {
                used.append(newData)
                newData = handler.availableData
                if newData.isEmpty {
                    buffer = newData
                    break
                }
            }
        } while true

        if used.isEmpty {
            return nil
        } else {
            let s = String(data: used, encoding: .utf8)!
            if strippingNewline {
                return s.trimmingCharacters(in: .newlines)
            }
            return s
        }
    }

    func readData(ofLength len: Int) -> Data {
        let c = buffer.count
        if len <= c {
            let d = buffer[ ..<(buffer.startIndex.advanced(by: len)) ]
            buffer.removeFirst(len)
            return d
        } else {
            var d = buffer
            d.append(handler.readData(ofLength: len - c))
            buffer.removeAll()
            return d
        }
    }
}
