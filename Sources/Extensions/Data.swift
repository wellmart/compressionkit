//
//  CompressionKit
//
//  Copyright (c) 2020 Wellington Marthas
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Compression
import Adrenaline

public extension Data {
    @inlinable
    func compressed() -> Data? {
        guard !isEmpty else {
            return self
        }
        
        if #available(iOS 13, *) {
            do {
                return try (self as NSData).compressed(using: .lzfse) as Data
            }
            catch {
                FirstChanceError.notify(error)
                return nil
            }
        }
        
        return perform(compression_encode_buffer, bufferSize: count)
    }
    
    @inlinable
    func decompressed() -> Data? {
        guard !isEmpty else {
            return self
        }
        
        if #available(iOS 13, *) {
            do {
                return try (self as NSData).decompressed(using: .lzfse) as Data
            }
            catch {
                FirstChanceError.notify(error)
                return nil
            }
        }
        
        let bufferSize = count * 8
        
        for i in 1...4 {
            if let data = perform(compression_decode_buffer, bufferSize: bufferSize * i) {
                return data
            }
        }
        
        return nil
    }
}

extension Data {
    @usableFromInline
    func perform(_ action: (UnsafeMutablePointer<UInt8>, Int, UnsafePointer<UInt8>, Int, UnsafeMutableRawPointer?, compression_algorithm) -> Int, bufferSize: Int) -> Data? {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var length = 0
        
        defer {
            buffer.deallocate()
        }
        
        withUnsafeBytes { bytes in
            guard let unsafePointer = bytes.bindMemory(to: UInt8.self).baseAddress else {
                return
            }
            
            length = action(buffer, bufferSize, unsafePointer, count, nil, COMPRESSION_LZFSE)
        }
        
        guard length > 0 else {
            return nil
        }
        
        return Data(bytes: buffer, count: length)
    }
}
