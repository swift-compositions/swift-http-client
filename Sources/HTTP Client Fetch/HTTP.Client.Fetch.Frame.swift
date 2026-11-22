public import Byte
public import HTTP
public import HTTP_Client
public import RFC_9110

extension HTTP.Client {
    public enum Fetch {}
}

extension HTTP.Client.Fetch {
    public enum Frame {}
}

extension HTTP.Client.Fetch.Frame {
    public static func request(_ request: IETF.RFC.`9110`.Message.Request<[Byte]>) -> [UInt8] {
        var text: String = request.method.rawValue
        text += "\n"
        text += request.target.reference ?? "/"
        text += "\n"
        for field in request.headers {
            let name: String = field.name.description
            let value: String = field.value.description
            text += name
            text += ": "
            text += value
            text += "\n"
        }
        text += "\n"
        var bytes: [UInt8] = Array(text.utf8)
        for byte in request.content ?? [] {
            bytes.append(byte.bitPattern)
        }
        return bytes
    }

    public static func response(_ bytes: [UInt8]) throws(HTTP.Client.Error) -> IETF.RFC.`9110`.Message.Response<[Byte]> {
        var lines: [String] = []
        var start = 0
        var index = 0
        var bodyStart: Int?
        while index < bytes.count {
            if bytes[index] == 0x0A {
                let line = String(decoding: bytes[start..<index], as: UTF8.self)
                if line.isEmpty, !lines.isEmpty {
                    bodyStart = index + 1
                    break
                }
                lines.append(line)
                start = index + 1
            }
            index += 1
        }
        guard let bodyStart, let statusLine = lines.first, let code = Int(statusLine) else {
            throw .malformed
        }
        var fields: [IETF.RFC.`9110`.Field] = []
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { throw .malformed }
            let name = String(line[..<colon])
            let value = String(line[line.index(after: colon)...].drop(while: { $0 == " " }))
            do throws(IETF.RFC.`9110`.Field.Error) {
                fields.append(try IETF.RFC.`9110`.Field(name: name, value: value))
            } catch {
                throw .malformed
            }
        }
        let body = bytes[bodyStart...].map { Byte(bitPattern: $0) }
        return IETF.RFC.`9110`.Message.Response(
            status: IETF.RFC.`9110`.Status(code),
            headers: IETF.RFC.`9110`.Message.Headers(fields),
            content: body.isEmpty ? nil : body
        )
    }
}
