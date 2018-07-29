//
//  Daemon.swift
//  sourcekitten
//
//  Created by SolaWing on 2018/7/22.
//  Copyright © 2018年 SourceKitten. All rights reserved.
//

import ArgumentParser
import Foundation
import Result
import SourceKittenFramework

private let stdin = StreamReader(FileHandle.standardInput)
private let stdout = FileHandle.standardOutput
private var stderr = FileHandle.standardError

func log(_ content: String) {
//    print(error, to: &stderr)
}

/*
struct DaemonCommand: ParsableCommand {
    let verb = "daemon"
    let function = "run swiftkittend with input pipe"

    func run(_ options: NoOptions<SourceKittenError>) -> Result<(), SourceKittenError> {
        var package: RequestPackage? {
            do {
                let p = try getPackage()
                return p
            } catch {
                print(error, to: &stderr)
            }
            return nil
        }
        loop: while let p = package {
            switch p.content["method"] as? String {
            case "yaml":
                print("yaml request", to: &stderr)
                if let content = p.content["params"] as? String, let rid = p.content["id"] {
                    let request = Request.yamlRequest(yaml: content)
                    do {
                        response(id: rid, result: toJSON(toNSDictionary(try request.send())), error: nil)
                    } catch {
                        response(id: rid, result: nil, error: error.localizedDescription)
                    }
                    continue
                }
                response(id: p.content["id"], result: nil, error: "Invalid yaml request")
            case "end":
                print("will end", to: &stderr)
//                response(content: "[]", error: nil)
                break loop
            default:
                continue // ignore other method
            }
        }
        print("end", to: &stderr)
        return .success(())
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

    private func response(id: Any?, result: String?, error: String?) {
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

    public func readLine(strippingNewline: Bool = true) -> String? {

        var used = Data()
        var newData = buffer
        repeat {
            if let index = newData.index(of: 10) {
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

    public func readData(ofLength len: Int) -> Data {
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
*/
