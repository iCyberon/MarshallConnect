//
//  Device.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/10/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

let SPEAKERS = [
    [
        "ssid": "ActonBlack",
        "color": "Acton_Black",
        "name": "Acton Black",
        "displayModel": "Acton",
        "displayColor": "Black",
        "list_item": "list_item_acton_black",
        "list_item_small": "list_item_small_acton_black",
        "hero": "hero_acton_black",
        "connectable": true
    ],
    [
        "ssid": "ActonCream",
        "color": "Acton_Cream",
        "name": "Acton Cream",
        "displayModel": "Acton",
        "displayColor": "Cream",
        "list_item": "list_item_acton_cream",
        "list_item_small": "list_item_small_acton_cream",
        "hero": "hero_acton_cream",
        "connectable": true
    ],
    [
        "ssid": "StanmoreBlack",
        "color": "Stanmore_Black",
        "name": "Stanmore Black",
        "displayModel": "Stanmore",
        "displayColor": "Black",
        "list_item": "list_item_stanmore_black",
        "list_item_small": "list_item_stanmore_black",
        "hero": "hero_stanmore_black",
        "connectable": true
    ],
    [
        "ssid": "StanmoreCream",
        "color": "Stanmore_Cream",
        "name": "Stanmore Cream",
        "displayModel": "Stanmore",
        "displayColor": "Cream",
        "list_item": "list_item_stanmore_cream",
        "list_item_small": "list_item_small_stanmore_cream",
        "hero": "hero_stanmore_cream",
        "connectable": true
    ],
    [
        "ssid": "WoburnBlack",
        "color": "Woburn_Black",
        "name": "Woburn Black",
        "displayModel": "Woburn",
        "displayColor": "Black",
        "list_item": "list_item_woburn_black",
        "list_item_small": "list_item_small_woburn_black",
        "hero": "hero_woburn_black",
        "connectable": true
    ],
    [
        "ssid": "WoburnCream",
        "color": "Woburn_Cream",
        "name": "Woburn Cream",
        "displayModel": "Woburn",
        "displayColor": "Cream",
        "list_item": "list_item_woburn_cream",
        "list_item_small": "list_item_small_woburn_cream",
        "hero": "hero_woburn_cream",
        "connectable": true
    ]
]

enum APIResponseStatus: String {
    case FS_OK = "FS_OK"
    case FS_FAIL = "FS_FAIL"
    case FS_TIMEOUT = "FS_TIMEOUT"
    case FS_PACKET_BAD = "FS_PACKET_BAD"
    case FS_NODE_DOES_NOT_EXIST = "FS_NODE_DOES_NOT_EXIST"
    case FS_NODE_BLOCKED = "FS_NODE_BLOCKED"
}

enum PlayerStatus: String {
    case Loading = "0"
    case Changing = "1"
    case Playing = "2"
    case Paused = "3"
    case Connecting = "6"
}

enum PlayerMode: String {
    case Audsync = "0"
    case AUXIN = "1"
    case Airplay = "2"
    case Spotify = "3"
    case GoogleCast = "4"
    case Bluetooth = "5"
    case IR = "6"
    case RCA = "7"
    case Standby = "8"
    case SETUP = "9"
}

struct APIResponse: XMLIndexerDeserializable {
    let node: String
    let status: APIResponseStatus
    let value: String
    
    static func deserialize(_ node: XMLIndexer) throws -> APIResponse {
        return try APIResponse(
            node: node["node"].value(),
            status: APIResponseStatus(rawValue: node["status"].value()) ?? .FS_FAIL,
            value: node["value"].children[0].element?.text ?? ""
        )
    }
}

struct Notify: XMLIndexerDeserializable {
    let param: String
    let value: String
    
    static func deserialize(_ node: XMLIndexer) throws -> Notify {
        return try Notify(
            param: node.value(ofAttribute: "node"),
            value: node["value"].children[0].element?.text ?? ""
        )
    }
}

struct Device: XMLIndexerDeserializable {
    let UDN: String
    let colorProduct: String
    let friendlyName: String
    
    static func deserialize(_ node: XMLIndexer) throws -> Device {
        return try Device(
            UDN: node["UDN"].value(),
            colorProduct: node["colorProduct"].value(),
            friendlyName: node["friendlyName"].value()
        )
    }
}

struct Player {
    var status: PlayerStatus
    var isShuffle: Bool
    var isRepeat: Bool
    var position: Int
    var song: Song
}

struct System {
    var power: Bool
    var mode: PlayerMode
    var volume: Int
    var mute: Bool
    var bass: Int
    var treble: Int
}

struct Song {
    var name: String
    var artist: String
    var album: String
    var text: String
    var duration: Int
    var albumArt: URL?
}

extension Device {
    var image : NSImage? {
        let item = SPEAKERS.filter{$0["color"] as! String == colorProduct}.first
        return NSImage(named: item?["hero"] as! NSImage.Name)
    }
    
    var modelAndColor: String? {
        let item = SPEAKERS.filter{$0["color"] as! String == colorProduct}.first
        return item?["name"] as? String
    }
}
