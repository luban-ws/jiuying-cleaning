//
//  NetworkInterfaceCounters.swift
//  CleanSpaceKit
//
//  汇总非 loopback 接口的累计收发字节（`getifaddrs` / `if_data`），用于计算速率。
//

import Darwin
import Foundation

enum NetworkInterfaceCounters {
    /// 所有非 `lo*` 接口的累计入站 / 出站字节。
    static func totalBytesInOut() -> (in: UInt64, out: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }
        var inB: UInt64 = 0
        var outB: UInt64 = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let name = String(cString: p.pointee.ifa_name)
            if name.hasPrefix("lo") {
                ptr = p.pointee.ifa_next
                continue
            }
            if let data = p.pointee.ifa_data {
                let ifd = data.assumingMemoryBound(to: if_data.self).pointee
                inB &+= UInt64(ifd.ifi_ibytes)
                outB &+= UInt64(ifd.ifi_obytes)
            }
            ptr = p.pointee.ifa_next
        }
        return (inB, outB)
    }
}
