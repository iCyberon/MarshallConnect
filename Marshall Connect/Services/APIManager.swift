//
//  NetworkManager.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/10/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

class APIManager : NSObject {
    private let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    private let url : URL!
    
    // MARK: -
    init(ipAddress: String) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = ipAddress
        self.url = urlComponents.url!
    }
    
    // MARK: - Methods
    func fetchDeviceInfo(callback: @escaping (Error?, Device?) -> Void) {
        self.GET(path: "dd.xml", params: nil, callback: { (error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }
            
            guard let device : Device = try? xml!["root"]["device"].value() else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }
            
            callback(nil, device)
        })
    }
    
    func fetchPosition(callback: @escaping (Int?) -> Void) {
        self.GET(path: "fsapi/GET/netRemote.play.position", params: ["pin": "1234"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(nil)
            }
            
            guard let status: APIResponseStatus = APIResponseStatus(rawValue: (try! xml!["fsapiResponse"]["status"].value())) else {
                return callback(nil)
            }
            
            guard status == .FS_OK else {
                return callback(nil)
            }
            
            guard let value = xml!["fsapiResponse"]["value"].children[0].element?.text, let position = Int(value) else {
                return callback(nil)
            }
            
            callback(position)
        })
    }
    
    func fetchPlayState(callback: @escaping (Error?, Player?) -> Void) {
        let nodes = [
            "1234",
            "netremote.play.status",
            "netremote.play.info.name",
            "netremote.play.info.text",
            "netremote.play.info.artist",
            "netremote.play.info.album",
            "netremote.play.info.graphicuri",
            "netremote.play.info.duration",
            "netremote.play.position",
            "netremote.play.shuffle",
            "netremote.play.repeat"
        ]

        self.GET(path: "fsapi/GET_MULTIPLE", params: ["pin": nodes.joined(separator: "&node=")], callback: {(error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }

            guard let responses: [APIResponse] = try? xml!["fsapiGetMultipleResponse"]["fsapiResponse"].value() else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }

            let song = Song.init(
                name: (responses.filter{$0.node == "netremote.play.info.name"}.first?.value)!,
                artist: (responses.filter{$0.node == "netremote.play.info.artist"}.first?.value)!,
                album: (responses.filter{$0.node == "netremote.play.info.album"}.first?.value)!,
                text: (responses.filter{$0.node == "netremote.play.info.text"}.first?.value)!,
                duration: Int(responses.filter{$0.node == "netremote.play.info.duration"}.first?.value ?? "0")!,
                albumArt: URL.init(string: (responses.filter{$0.node == "netremote.play.info.graphicuri"}.first?.value)!)
            )
            
            let player = Player.init(
                status: PlayerStatus(rawValue: (responses.filter{$0.node == "netremote.play.status"}.first?.value)!)!,
                isShuffle: Int(responses.filter{$0.node == "netremote.play.shuffle"}.first?.value ?? "0")!.boolValue,
                isRepeat: Int(responses.filter{$0.node == "netremote.play.repeat"}.first?.value ?? "0")!.boolValue,
                position: Int(responses.filter{$0.node == "netremote.play.position"}.first?.value ?? "0")!,
                song: song
            )

            callback(nil, player)
        })
    }
    
    func fetchSystemState(callback: @escaping (Error?, System?) -> Void) {
        let nodes = [
            "1234",
            "netremote.sys.power",
            "netremote.sys.mode",
            "netremote.sys.audio.volume",
            "netremote.sys.audio.mute",
            "netRemote.sys.audio.eqcustom.param0",
            "netRemote.sys.audio.eqcustom.param1"
        ]
        
        self.GET(path: "fsapi/GET_MULTIPLE", params: ["pin": nodes.joined(separator: "&node=")], callback: {(error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }
            
            guard let responses: [APIResponse] = try? xml!["fsapiGetMultipleResponse"]["fsapiResponse"].value() else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }
            
            
            let system = System.init(
                power: Int(responses.filter{$0.node == "netremote.sys.power"}.first?.value ?? "0")!.boolValue,
                mode: PlayerMode(rawValue: (responses.filter{$0.node == "netremote.sys.mode"}.first?.value)!)!,
                volume: Int(responses.filter{$0.node == "netremote.sys.audio.volume"}.first?.value ?? "0")!,
                mute: Int(responses.filter{$0.node == "netremote.sys.audio.mute"}.first?.value ?? "0")!.boolValue,
                bass: Int(responses.filter{$0.node == "netRemote.sys.audio.eqcustom.param0"}.first?.value ?? "0")!,
                treble: Int(responses.filter{$0.node == "netRemote.sys.audio.eqcustom.param1"}.first?.value ?? "0")!
            )
            
            callback(nil, system)
        })
    }
    
    func connect(callback: @escaping (Error?, String?) -> Void) {
        self.GET(path: "fsapi/CREATE_SESSION", params: ["pin": "1234"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }
            
            guard let sessionToken : String = try? xml!["fsapiResponse"]["sessionId"].value() else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
            }
            
            callback(nil, sessionToken)
        })
    }
    
    func disconnect(callback: @escaping (Error?) -> Void) {
        self.GET(path: "fsapi/DELETE_SESSION", params: ["pin": "1234"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(NSError(domain: "", code: 0, userInfo: nil))
            }

            callback(nil)
        })
    }
    
    func setPosition(_ position: Int) {
        self.GET(path: "fsapi/SET/netRemote.play.position", params: ["pin": "1234", "value": String(position)], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func mute() {
        self.GET(path: "fsapi/SET/netRemote.sys.audio.mute", params: ["pin": "1234", "value": "1"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func unmute() {
        self.GET(path: "fsapi/SET/netRemote.sys.audio.mute", params: ["pin": "1234", "value": "0"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func pause() {
        self.GET(path: "fsapi/SET/netRemote.play.control", params: ["pin": "1234", "value": "2"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func forward() {
        self.GET(path: "fsapi/SET/netRemote.play.control", params: ["pin": "1234", "value": "3"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func rewind() {
        self.GET(path: "fsapi/SET/netRemote.play.control", params: ["pin": "1234", "value": "4"], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    // MARK: - System ⇢ Audio
    func setVolume(_ volume: Int) {
        self.GET(path: "fsapi/SET/netRemote.sys.audio.volume", params: ["pin": "1234", "value": String(volume)], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func setBass(_ volume: Int) {
        self.GET(path: "fsapi/SET/netRemote.sys.audio.eqcustom.param0", params: ["pin": "1234", "value": String(volume)], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func setTreble(_ volume: Int) {
        self.GET(path: "fsapi/SET/netRemote.sys.audio.eqcustom.param1", params: ["pin": "1234", "value": String(volume)], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
        })
    }
    
    func listen(sid: String, callback: @escaping (Error?, Bool, Notify?) -> Void) {
        self.GET(path: "fsapi/GET_NOTIFIES", params: ["pin": "1234", "sid": sid], callback: { (error: Error?, xml: XMLIndexer?) -> Void in
            guard error == nil && xml != nil else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), false, nil)
            }
            
            guard let status: APIResponseStatus = APIResponseStatus(rawValue: (try! xml!["fsapiResponse"]["status"].value())) else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), false, nil)
            }
            
            guard status == .FS_OK else {
                if (status == .FS_TIMEOUT) {
                    return callback(nil, true, nil) // All Good
                }

                return callback(NSError(domain: "", code: 0, userInfo: nil), false, nil)
            }
            
            guard let notify: Notify = try? xml!["fsapiResponse"]["notify"].value() else {
                return callback(NSError(domain: "", code: 0, userInfo: nil), false, nil)
            }
            
            callback(nil, false, notify)
        })
    }
    
    // MARK: - Helper Methods
    private func GET(path: String, params: [String:String]?, callback: @escaping (Error?, XMLIndexer?) -> Void) {
        guard var requestUrl = URL(string: path, relativeTo: self.url) else {
            return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
        }

        if let params = params, params.count > 0 {
            requestUrl = requestUrl.appendingQueryParameters(params)
        }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil && data != nil) {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let xml = SWXMLHash.parse(data!)
                    callback(nil, xml)
                } else {
                    return callback(NSError(domain: "", code: 0, userInfo: nil), nil)
                }
            } else {
                callback(error, nil)
            }
        })
        task.resume()
    }
}

// MARK: - Extensions
protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    /**
     This computed property returns a query parameters string from the given NSDictionary. For
     example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
     string will be @"day=Tuesday&month=January".
     @return The computed parameters string.
     */
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
}

extension URL {
    /**
     Creates a new URL by adding the given query parameters.
     @param parametersDictionary The query parameter dictionary to add.
     @return A new URL.
     */
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}

extension Int {
    var boolValue: Bool { return self != 0 }
}
