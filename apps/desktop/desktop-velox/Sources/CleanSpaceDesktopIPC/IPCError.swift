//
//  IPCError.swift
//  CleanSpaceDesktopIPC
//

import Foundation

public enum IPCError: Error, Equatable {
    case badRequest(String)
    case notFound(String)

    public var message: String {
        switch self {
        case .badRequest(let msg), .notFound(let msg): return msg
        }
    }
}
