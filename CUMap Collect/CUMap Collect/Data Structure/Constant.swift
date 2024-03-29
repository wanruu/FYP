import Foundation
import SwiftUI
import MapKit

let BUS_COLORS: [String: Color] = [
    "1A": Color(red: 227/255, green: 222/255, blue: 0),
    "1B": Color(red: 227/255, green: 222/255, blue: 0),
    "2": Color(red: 255/255, green: 102/255, blue: 204/255),
    "3": Color(red: 155/255, green: 187/255, blue: 89/255),
    "4": Color(red: 247/255, green: 150/255, blue: 70/255),
    "5": Color(red: 182/255, green: 221/255, blue: 232/255),
    "6A": Color(red: 118/255, green: 146/255, blue: 60/255),
    "6B": Color(red: 124/255, green: 168/255, blue: 222/255),
    "7": Color(red: 192/255, green: 192/255, blue: 192/255),
    "8": Color(red: 255/255, green: 192/255, blue: 67/255),
    "light": Color(red: 151/255, green: 81/255, blue: 150/255)
]

let server = "http://10.13.16.219:8000" // CUHK1x
// let server = "http://42.194.159.158:8000" // tencent

// CUHK Color
let CU_PURPLE = Color(red: 117/255, green: 15/255, blue: 109/255)
let CU_YELLOW = Color(red: 221/255, green: 163/255, blue: 0)
let CU_PALE_YELLOW = Color(red: 244/255, green: 223/255, blue: 176/255)

let CENTER_LAT: Double = 22.420235823827056
let CENTER_LNG: Double = 114.20697508836815
let CENTER_COOR2D = CLLocationCoordinate2D(latitude: CENTER_LAT, longitude: CENTER_LNG)

let LARGE_SPAN = MKCoordinateSpan(latitudeDelta: 0.025535897620393655, longitudeDelta: 0.01494943394902748) // whole cuhk
let SMALL_SPAN = MKCoordinateSpan(latitudeDelta: 0.004325250474217057, longitudeDelta: 0.0025322589048073496) // one location

let LAT_SCALE: Double = 111000
let LNG_SCALE: Double = 85390

let SC_WIDTH = UIScreen.main.bounds.width
