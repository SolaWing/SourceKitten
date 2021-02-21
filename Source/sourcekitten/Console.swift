import ArgumentParser
import Foundation
import SourceKittenFramework

struct Console: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "run swiftkittend as a interactive console, so can send multiple yaml request")
    mutating func run() throws {
        var finished = false
        loop: while !finished { // swiftlint:disable:this all
            autoreleasepool {
                do {
                    switch Command.getFromStdIn() {
                    case .exit: finished = true
                    case let .yaml(input, output):
                        let content = try String(contentsOfFile: input)
                        let request = Request.yamlRequest(yaml: content)
                        let response = try request.send()
                        let json = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                        if let output = output {
                            try json.write(to: URL(fileURLWithPath: output))
                            print("write response to \(output)")
                        } else {
                            stdout.write(json)
                            stdout.write("\n")
                        }
                    default: break
                    }
                } catch {
                    print(error, to: &stderr)
                }
            }
        }
    }
    enum Command {
        case none, exit
        case yaml(String, String?)
        static func getFromStdIn() -> Command {
            stderr.write("YamlPath [outputPath]: ")
            guard let line = stdin.readLine() else { return .exit }
            let parts = line.split(separator: " ")
            if parts.isEmpty { return .none }
            if parts.count < 2 { return .yaml(String(parts[0]), nil) }
            return .yaml(String(parts[0]), String(parts[1]))
        }
    }
}
