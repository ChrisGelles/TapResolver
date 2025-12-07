//
//  FileLogger.swift
//  TapResolver
//
//  Hybrid logging: prints to console AND saves to file for later export.
//

import Foundation

// MARK: - Global print() Override

// This shadows Swift's built-in print() within this module.
// All existing print() calls automatically route through here.

/// Replacement for Swift's print() that also logs to file.
/// Call sites don't need to change - this is picked up automatically.
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { String(describing: $0) }.joined(separator: separator)
    
    // 1. Send to Xcode console (original behavior)
    Swift.print(output, terminator: terminator)
    
    // 2. Send to file (new behavior)
    // Strip the terminator for file logging since log() adds its own newline
    if !output.isEmpty {
        FileLogger.shared.logRaw(output)
    }
}

/// Global logging function - use instead of print() for important diagnostics.
/// Writes to both Xcode console (when connected) and a persistent log file.
public func tapLog(_ message: String, file: String = #file, line: Int = #line) {
    let filename = (file as NSString).lastPathComponent
    let prefix = "[\(filename):\(line)]"
    let fullMessage = "\(prefix) \(message)"
    
    // Use Swift.print() to avoid double logging (our print() override would also log)
    Swift.print(fullMessage)
    FileLogger.shared.log(fullMessage)
}

/// Singleton file logger that persists console output to disk.
public final class FileLogger {
    public static let shared = FileLogger()
    
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.tapresolver.filelogger", qos: .utility)
    private let dateFormatter: DateFormatter
    private let maxFileSize: Int = 5 * 1024 * 1024  // 5 MB max before rotation
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("tapresolver_console.log")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Write session header
        let header = "\n" + String(repeating: "=", count: 80) + "\n"
            + "📱 TapResolver Log Session Started\n"
            + "   Date: \(dateFormatter.string(from: Date()))\n"
            + String(repeating: "=", count: 80) + "\n\n"
        
        appendToFile(header)
        
        // Check file size and rotate if needed
        rotateIfNeeded()
    }
    
    /// Log a message to the file with timestamp (called by tapLog)
    func log(_ message: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let timestamp = self.dateFormatter.string(from: Date())
            let line = "[\(timestamp)] \(message)\n"
            self.appendToFile(line)
        }
    }
    
    /// Log raw text to file without timestamp (used by print() override)
    func logRaw(_ message: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.appendToFile(message + "\n")
        }
    }
    
    /// Get the URL of the log file for sharing
    public var logFileURL: URL { fileURL }
    
    /// Generate a shareable filename with timestamp (local time)
    /// Format: TapRez-Console-20251207-1246.log
    public func generateExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        formatter.timeZone = .current  // Local time, not GMT
        let timestamp = formatter.string(from: Date())
        return "TapRez-Console-\(timestamp).log"
    }
    
    /// Get a URL with the formatted export filename (for sharing)
    public var exportFileURL: URL {
        let tempDir = FileManager.default.temporaryDirectory
        let exportName = generateExportFilename()
        let exportURL = tempDir.appendingPathComponent(exportName)
        
        // Copy current log to temp location with nice filename
        try? FileManager.default.removeItem(at: exportURL)
        try? FileManager.default.copyItem(at: fileURL, to: exportURL)
        
        return exportURL
    }
    
    /// Get the contents of the log file as a string
    public func getLogContents() -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            return "Error reading log file: \(error.localizedDescription)"
        }
    }
    
    /// Get the size of the log file in bytes
    public func getLogFileSize() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Clear the log file and start fresh with new header
    public func clearLog() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let header = "\n" + String(repeating: "=", count: 80) + "\n"
                + "📱 TapResolver Log Cleared & Restarted\n"
                + "   Date: \(self.dateFormatter.string(from: Date()))\n"
                + String(repeating: "=", count: 80) + "\n\n"
            try? header.write(to: self.fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    // MARK: - Private
    
    private func appendToFile(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: fileURL)
        }
    }
    
    private func rotateIfNeeded() {
        let size = getLogFileSize()
        if size > maxFileSize {
            // Archive old log
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let archiveURL = docs.appendingPathComponent("tapresolver_console_old.log")
            
            try? FileManager.default.removeItem(at: archiveURL)
            try? FileManager.default.moveItem(at: fileURL, to: archiveURL)
            
            let header = "📱 Log rotated (previous log archived) at \(dateFormatter.string(from: Date()))\n\n"
            try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}
