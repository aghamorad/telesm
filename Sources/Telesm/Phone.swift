import Foundation

struct Spot: Identifiable, Hashable {
    let id: String
    let city: String
    let detail: String
    let latitude: Double
    let longitude: Double

    static let newYork = Spot(id: "nyc", city: "New York City", detail: "Times Square",
                              latitude: 40.7580, longitude: -73.9855)
    static let london = Spot(id: "uk", city: "London", detail: "United Kingdom",
                             latitude: 51.5074, longitude: -0.1278)
    static let oxford = Spot(id: "oxford", city: "St Antony's College", detail: "Oxford, UK",
                             latitude: 51.76389, longitude: -1.2625)
}

struct Device: Identifiable, Hashable {
    let udid: String
    let name: String
    let isUSB: Bool
    var id: String { udid }
}

struct RunResult {
    let ok: Bool
    let output: String
}

enum Phone {
    private static let candidates = [
        "/Users/Morad/.local/bin/pymobiledevice3",
        "/opt/homebrew/bin/pymobiledevice3",
        "/usr/local/bin/pymobiledevice3",
    ]

    static var executable: String? {
        candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func run(_ args: [String], timeout: TimeInterval = 120) -> RunResult {
        guard let exe = executable else {
            return RunResult(ok: false, output: "pymobiledevice3 not found. Install it with: pipx install pymobiledevice3")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: exe)
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/Users/Morad/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PYTHONUNBUFFERED"] = "1"
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        var collected = Data()
        let lock = NSLock()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            lock.lock(); collected.append(chunk); lock.unlock()
        }

        do {
            try process.run()
        } catch {
            return RunResult(ok: false, output: "Could not start pymobiledevice3: \(error.localizedDescription)")
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            usleep(120_000)
        }
        if process.isRunning {
            process.terminate()
            pipe.fileHandleForReading.readabilityHandler = nil
            return RunResult(ok: false, output: "Timed out after \(Int(timeout))s. Is the iPhone plugged in and unlocked?")
        }

        process.waitUntilExit()
        usleep(120_000)
        pipe.fileHandleForReading.readabilityHandler = nil
        collected.append(pipe.fileHandleForReading.readDataToEndOfFile())

        let text = String(data: collected, encoding: .utf8) ?? ""
        return RunResult(ok: process.terminationStatus == 0, output: text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func devices() -> [Device] {
        let result = run(["usbmux", "list"], timeout: 30)
        guard
            let start = result.output.firstIndex(of: "["),
            let end = result.output.lastIndex(of: "]"),
            start < end,
            let data = String(result.output[start...end]).data(using: .utf8),
            let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }

        return rows.compactMap { row in
            guard let udid = (row["Identifier"] as? String) ?? (row["UniqueDeviceID"] as? String) else { return nil }
            let connection = (row["ConnectionType"] as? String) ?? ""
            return Device(
                udid: udid,
                name: (row["DeviceName"] as? String) ?? "iPhone",
                isUSB: connection.localizedCaseInsensitiveContains("usb")
            )
        }
    }

    static func set(_ spot: Spot, device: Device?) -> RunResult {
        var args = ["developer", "dvt", "simulate-location", "set"]
        if let device { args += ["--udid", device.udid] }
        args += ["--userspace", "--", String(format: "%.4f", spot.latitude), String(format: "%.4f", spot.longitude)]
        return run(args)
    }

    static func clear(device: Device?) -> RunResult {
        var args = ["developer", "dvt", "simulate-location", "clear"]
        if let device { args += ["--udid", device.udid] }
        args += ["--userspace"]
        return run(args)
    }

    static func readable(_ result: RunResult, fallback: String) -> String {
        let trimmed = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let lines = trimmed.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let last = lines.last, last.count > 160 { return String(last.prefix(160)) + "…" }
        return lines.last.map { String($0) } ?? fallback
    }
}
