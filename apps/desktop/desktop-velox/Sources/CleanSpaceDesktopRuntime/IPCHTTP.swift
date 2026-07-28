//
//  IPCHTTP.swift
//  CleanSpaceDesktopRuntime
//

import CleanSpaceDesktopIPC
import Foundation
import VeloxRuntimeWry

public enum IPCHTTP {
    public static func handleInvoke(request: VeloxRuntimeWry.CustomProtocol.Request) -> VeloxRuntimeWry.CustomProtocol.Response? {
        guard let url = URL(string: request.url) else {
            return errorResponse(message: "Invalid URL")
        }

        let command = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var args: [String: Any] = [:]
        if !request.body.isEmpty,
           let json = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any] {
            args = json
        }

        do {
            let body: Data
            if Thread.isMainThread {
                body = try IPCHeavyWork.run {
                    try IPCCommandRouter.handle(command: command, args: args)
                }
            } else {
                body = try IPCCommandRouter.handle(command: command, args: args)
            }
            return VeloxRuntimeWry.CustomProtocol.Response(
                status: 200,
                headers: ["Content-Type": "application/json", "Access-Control-Allow-Origin": "*"],
                mimeType: "application/json",
                body: body
            )
        } catch let error as IPCError {
            return errorResponse(message: error.message)
        } catch {
            return errorResponse(message: error.localizedDescription)
        }
    }

    public static func errorResponse(message: String) -> VeloxRuntimeWry.CustomProtocol.Response {
        let error: [String: Any] = ["error": message]
        let jsonData = (try? JSONSerialization.data(withJSONObject: error)) ?? Data()
        return VeloxRuntimeWry.CustomProtocol.Response(
            status: 400,
            headers: ["Content-Type": "application/json", "Access-Control-Allow-Origin": "*"],
            mimeType: "application/json",
            body: jsonData
        )
    }
}
