import Foundation

/// Helper class to build multipart/form-data request bodies.
public final class MultipartFormData {
    
    public struct FileData {
        public let data: Data
        public let name: String
        public let fileName: String
        public let mimeType: String
        
        public init(data: Data, name: String, fileName: String, mimeType: String) {
            self.data = data
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
    
    private let boundary: String
    private var bodyData = Data()
    
    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }
    
    public var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }
    
    // MARK: - Add Fields
    
    /// Adds a text field to the form data.
    public func addTextField(name: String, value: String) {
        bodyData.append("--\(boundary)\r\n")
        bodyData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        bodyData.append("\(value)\r\n")
    }
    
    /// Adds a file to the form data.
    public func addFile(_ file: FileData) {
        bodyData.append("--\(boundary)\r\n")
        bodyData.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n")
        bodyData.append("Content-Type: \(file.mimeType)\r\n\r\n")
        bodyData.append(file.data)
        bodyData.append("\r\n")
    }
    
    /// Adds multiple files to the form data.
    public func addFiles(_ files: [FileData]) {
        files.forEach { addFile($0) }
    }
    
    /// Finalizes and returns the body data.
    public func finalize() -> Data {
        var finalData = bodyData
        finalData.append("--\(boundary)--\r\n")
        return finalData
    }
}

// MARK: - Data Extension

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
