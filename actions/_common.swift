
import Glibc
import SwiftyJSON

// add randomElement() to the Array type
extension Array {
    func randomElement() -> Element {
        // note, seed rand() before use with: srand(UInt32(time(nil)))
        let index = Int(rand()) % count
        return self[index]
    }
}

/// Add fromBase64() and toBase64() to the String type
extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

// Format the response correctly.
// If it's a web action we can return the code and set headers. If it isn't,
// then we can only return the data.
//
// We determine if it's a web action call by looking for the "__ow_meta_verb"
// key in the input data
func createResponse(_ body: [String: Any], code: Int) -> [String:Any]
{
    let env = ProcessInfo.processInfo.environment
    guard let whiskInput = env["WHISK_INPUT"] else {
        // No WHISK_INPUT, assume a normal action
        return body
    }

    if whiskInput.range(of:"__ow_meta_verb") != nil {
        // This is a web action as the arguments contain the "__ow_meta_verb" key

        let json = WhiskJsonUtils.dictionaryToJsonString(jsonDict: body) ?? ""
        return [
            "body": json.toBase64(),
            "code": code,
            "headers": [
                "Content-Type": "application/json",
            ],
        ]
    }

    // This is not a web action
    if code >= 400 && body["error"] == nil {
        // we need to set the "error" key in the array
        // so that OpenWhisk knows that something's gone wrong
        return ["error": code]
    }
    return body
}
