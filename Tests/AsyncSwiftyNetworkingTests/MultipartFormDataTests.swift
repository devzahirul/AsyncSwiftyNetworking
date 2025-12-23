import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - MultipartFormData Tests

@Suite("MultipartFormData Tests")
struct MultipartFormDataTests {
    
    // MARK: - Initialization Tests
    
    @Test("MultipartFormData initializes with default boundary")
    func testDefaultBoundary() {
        let formData = MultipartFormData()
        let contentType = formData.contentType
        
        #expect(contentType.starts(with: "multipart/form-data; boundary="))
    }
    
    @Test("MultipartFormData initializes with custom boundary")
    func testCustomBoundary() {
        let formData = MultipartFormData(boundary: "custom-boundary-123")
        let contentType = formData.contentType
        
        #expect(contentType == "multipart/form-data; boundary=custom-boundary-123")
    }
    
    // MARK: - Text Field Tests
    
    @Test("addTextField adds field with correct format")
    func testAddTextField() {
        let formData = MultipartFormData(boundary: "test-boundary")
        formData.addTextField(name: "username", value: "john_doe")
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("--test-boundary"))
        #expect(string.contains("Content-Disposition: form-data; name=\"username\""))
        #expect(string.contains("john_doe"))
        #expect(string.contains("--test-boundary--"))
    }
    
    @Test("Multiple text fields are added correctly")
    func testMultipleTextFields() {
        let formData = MultipartFormData(boundary: "test-boundary")
        formData.addTextField(name: "field1", value: "value1")
        formData.addTextField(name: "field2", value: "value2")
        formData.addTextField(name: "field3", value: "value3")
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("name=\"field1\""))
        #expect(string.contains("value1"))
        #expect(string.contains("name=\"field2\""))
        #expect(string.contains("value2"))
        #expect(string.contains("name=\"field3\""))
        #expect(string.contains("value3"))
    }
    
    @Test("Text field with special characters")
    func testTextFieldWithSpecialCharacters() {
        let formData = MultipartFormData(boundary: "test-boundary")
        formData.addTextField(name: "comment", value: "Hello! こんにちは 🎉")
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("Hello! こんにちは 🎉"))
    }
    
    // MARK: - File Tests
    
    @Test("addFile adds file with correct format")
    func testAddFile() {
        let formData = MultipartFormData(boundary: "test-boundary")
        let fileData = MultipartFormData.FileData(
            data: "file content".data(using: .utf8)!,
            name: "avatar",
            fileName: "photo.jpg",
            mimeType: "image/jpeg"
        )
        formData.addFile(fileData)
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("--test-boundary"))
        #expect(string.contains("Content-Disposition: form-data; name=\"avatar\"; filename=\"photo.jpg\""))
        #expect(string.contains("Content-Type: image/jpeg"))
        #expect(string.contains("file content"))
    }
    
    @Test("addFiles adds multiple files")
    func testAddFiles() {
        let formData = MultipartFormData(boundary: "test-boundary")
        let files = [
            MultipartFormData.FileData(
                data: "file1".data(using: .utf8)!,
                name: "files",
                fileName: "doc1.pdf",
                mimeType: "application/pdf"
            ),
            MultipartFormData.FileData(
                data: "file2".data(using: .utf8)!,
                name: "files",
                fileName: "doc2.pdf",
                mimeType: "application/pdf"
            )
        ]
        formData.addFiles(files)
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("filename=\"doc1.pdf\""))
        #expect(string.contains("filename=\"doc2.pdf\""))
        #expect(string.contains("file1"))
        #expect(string.contains("file2"))
    }
    
    // MARK: - Mixed Content Tests
    
    @Test("Mixed text fields and files")
    func testMixedContent() {
        let formData = MultipartFormData(boundary: "test-boundary")
        formData.addTextField(name: "title", value: "My Upload")
        formData.addFile(MultipartFormData.FileData(
            data: "binary data".data(using: .utf8)!,
            name: "file",
            fileName: "test.bin",
            mimeType: "application/octet-stream"
        ))
        formData.addTextField(name: "description", value: "A test file")
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("name=\"title\""))
        #expect(string.contains("My Upload"))
        #expect(string.contains("filename=\"test.bin\""))
        #expect(string.contains("name=\"description\""))
        #expect(string.contains("A test file"))
        
        // Check proper ending
        #expect(string.hasSuffix("--test-boundary--\r\n"))
    }
    
    // MARK: - FileData Tests
    
    @Test("FileData initialization")
    func testFileDataInit() {
        let data = "test".data(using: .utf8)!
        let fileData = MultipartFormData.FileData(
            data: data,
            name: "file",
            fileName: "test.txt",
            mimeType: "text/plain"
        )
        
        #expect(fileData.data == data)
        #expect(fileData.name == "file")
        #expect(fileData.fileName == "test.txt")
        #expect(fileData.mimeType == "text/plain")
    }
    
    // MARK: - Boundary Tests
    
    @Test("Finalized data ends with closing boundary")
    func testClosingBoundary() {
        let formData = MultipartFormData(boundary: "my-boundary")
        formData.addTextField(name: "test", value: "value")
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string.contains("--my-boundary--"))
    }
    
    @Test("Empty form data only has closing boundary")
    func testEmptyFormData() {
        let formData = MultipartFormData(boundary: "empty-boundary")
        
        let data = formData.finalize()
        let string = String(data: data, encoding: .utf8)!
        
        #expect(string == "--empty-boundary--\r\n")
    }
}
