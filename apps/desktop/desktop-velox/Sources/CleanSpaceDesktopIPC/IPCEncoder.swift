//
//  IPCEncoder.swift
//  CleanSpaceDesktopIPC
//

import Foundation
import CleanSpaceKit

public enum IPCEncoder {
    private struct ResultEnvelope<T: Encodable>: Encodable {
        let result: T
    }

    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(ResultEnvelope(result: value))
    }

    public static func decode<T: Decodable>(_ type: T.Type, from dict: [String: Any]) -> T? {
        guard JSONSerialization.isValidJSONObject(dict),
              let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

public enum IPCArgumentParser {
    public static func workspaceScope(from value: Any?) -> WorkspaceScope {
        guard let raw = value as? String, let scope = WorkspaceScope(rawValue: raw) else {
            return .rules
        }
        return scope
    }

    public static func stringArray(_ value: Any?) -> [String]? {
        value as? [String]
    }

    public static func requiredString(_ value: Any?, field: String) throws -> String {
        guard let string = value as? String, !string.isEmpty else {
            throw IPCError.badRequest("\(field) required")
        }
        return string
    }

    public static func optionalInt64(_ value: Any?) -> Int64? {
        if let n = value as? Int64 { return n }
        if let n = value as? Int { return Int64(n) }
        if let n = value as? Double { return Int64(n) }
        if let n = value as? NSNumber { return n.int64Value }
        return nil
    }
}
