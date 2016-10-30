//
// I2CBus.swift
//
// Created by Steve Knodl on 10/22/2016
// Copyright (c) 2016 Steve Knodl. All Rights reserved
//

import Glibc
import Ci2c

public enum I2CBusError : Error {
    case open(Int32)
    case close(Int32)
    case closeNoFileOpen
    case io(Int32)
}

public class I2CBus {
    
    private(set) var fd: Int32 = -1
    private(set) var busNumber: Int = -1
    private(set) var address: Int32? = nil
    private(set) var isPecEnabled: Bool = false
    
    public init(busNumber: Int) throws {
        self.fd = Glibc.open("/dev/i2c-\(busNumber)", O_RDWR)
        guard fd != -1 else { throw I2CBusError.open(errno) }
        self.busNumber = busNumber
    }
    
    deinit {
        let _ = Glibc.close(fd) 
    }
    
    public func setPEC(enabled: Bool) throws {
        guard isPecEnabled != enabled else { return }
        if ioctl(fd, UInt(I2C_PEC), enabled ? 1 : 0) != 0 {
            throw I2CBusError.io(errno)
        }
        isPecEnabled = enabled
    }
    
    public func rawWrite(address: Int32, bytes: [UInt8]) throws {
        try setBusAddress(newAddress: address)
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
	for (index, dataByte) in bytes.enumerated() {
            data[index] = dataByte
	}
        let result = write(fd, data, bytes.count)
        if result != bytes.count {
            throw I2CBusError.io(errno)
        }
    }
    
    public func rawRead(address: Int32, byteCount: Int) throws -> [UInt8] {
        try setBusAddress(newAddress: address)
	let readData = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        if read(fd, readData, byteCount) != byteCount {
            throw I2CBusError.io(errno)
        }
        let buffer = UnsafeBufferPointer(start: readData, count: byteCount)
        return Array(buffer)
    }

    private func setBusAddress(newAddress: Int32) throws {
        if let address = address {
            guard address != newAddress else { return }
            self.address = newAddress
        } else {
            address = newAddress
        }
        if ioctl(fd, UInt(I2C_SLAVE), address!) != 0 {
            throw I2CBusError.io(errno)
        }
    }
}
