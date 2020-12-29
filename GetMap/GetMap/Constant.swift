//
//  GlobalVariable.swift
//  GetMap
//
//  Created by wanruuu on 5/11/2020.
//

import Foundation
import SwiftUI

// let server = "http://10.13.66.145:8000" /* lulu CUHK1x */
// let server = "http://10.13.115.254:8000" /* CUHK1x */
// let server = "http://10.6.32.127:8000" /* CUHK */
// let server = "http://169.254.161.175:8000" /* laptop */
let server = "http://42.194.159.158:8000" /* tencent server */

/* screen info */
let SCWidth = UIScreen.main.bounds.width
let SCHeight = UIScreen.main.bounds.height

/* center */
let centerX = SCWidth/2
let centerY = SCHeight/2 - 100

let centerLa = 22.419915 // +: down
let centerLg = 114.20774 // +: left

/* zoom in/out limit */
let maxZoomIn: CGFloat = 0.8
let minZoomOut: CGFloat = 0.2

/* map size: minZoomOut */
let mapWidth = 620.0
let mapHeight = 820.0

/* 1 degree of latitude & longitude: how many meters in real world? */
let laScale = 111000.0
let lgScale = 85390.0

// let colors = [Color.blue, Color.yellow, Color.green, Color.purple, Color.pink, Color.orange, Color.red]
let colors = [Color(red: 0.5203940375745528, green: 0.0654984974558428, blue: 0.5175233861166173), Color(red: 0.879121352222422, green: 0.8208925593751386, blue: 0.3178447081310599), Color(red: 0.5303030217046081, green: 0.2138584672670354, blue: 0.20562515645030588), Color(red: 0.1888657530470107, green: 0.914907190257568, blue: 0.5688922632323078), Color(red: 0.8218510861112699, green: 0.17368582135277244, blue: 0.13992689798042746), Color(red: 0.9628838161155375, green: 0.05093266294986931, blue: 0.12808708052015805), Color(red: 0.8461525849361966, green: 0.2453215634568865, blue: 0.6773752351834424), Color(red: 0.11740974291617934, green: 0.5482083740298416, blue: 0.008262059417173395), Color(red: 0.7718268200035577, green: 0.02048438510492201, blue: 0.42605392079735094), Color(red: 0.5253029503843072, green: 0.6390254199588533, blue: 0.890988875613219), Color(red: 0.23906437119825064, green: 0.6629520066209721, blue: 0.4288623573564957), Color(red: 0.4837242325828346, green: 0.6609047106664171, blue: 0.17752855303416504), Color(red: 0.701973023251315, green: 0.24712225165833812, blue: 0.8718243246537027), Color(red: 0.9243110728807029, green: 0.08087296498023189, blue: 0.578672208684651), Color(red: 0.6997522010762549, green: 0.5575925984037681, blue: 0.6700357568189853), Color(red: 0.9244767133476887, green: 0.9327399771075835, blue: 0.025146082586826823), Color(red: 0.09217693070278088, green: 0.4754398886216802, blue: 0.4225850738471426), Color(red: 0.0334557570551941, green: 0.2081914819073163, blue: 0.8966500643867491), Color(red: 0.30871151892923654, green: 0.2661525323636016, blue: 0.9193694757799429), Color(red: 0.4013771334366911, green: 0.5470434713479627, blue: 0.7464348236384984), Color(red: 0.6396259618895538, green: 0.38006673388844103, blue: 0.9380176918235272), Color(red: 0.9247778179324879, green: 0.9375619407948516, blue: 0.24812085329332612), Color(red: 0.09116871851078734, green: 0.9496811689535166, blue: 0.06835751459377082), Color(red: 0.7669736667472613, green: 0.1609103440889137, blue: 0.1998019244821272), Color(red: 0.3130611125046052, green: 0.7284975867783813, blue: 0.04519938397234968), Color(red: 0.7269777185363329, green: 0.26721344089715715, blue: 0.6670103224945391), Color(red: 0.8615093787015181, green: 0.7672972766408727, blue: 0.568852448438128), Color(red: 0.8056532402132858, green: 0.21866420040192402, blue: 0.7940074176534409), Color(red: 0.7559712375652107, green: 0.5643776553856572, blue: 0.09040671266813172), Color(red: 0.6574056433019064, green: 0.7503842602751652, blue: 0.44182666639522306), Color(red: 0.26014242238249274, green: 0.507789406611575, blue: 0.679880943905755), Color(red: 0.14767751757028003, green: 0.06745482109211531, blue: 0.2050995414971375), Color(red: 0.5042178698746388, green: 0.2745205788107433, blue: 0.6897342380711232), Color(red: 0.9891018183021918, green: 0.8142759607493498, blue: 0.015436199576385423), Color(red: 0.8727533056989851, green: 0.6723108826782966, blue: 0.9848936810814559), Color(red: 0.953060853305862, green: 0.19009287664186536, blue: 0.5383727088855806), Color(red: 0.10166384934093753, green: 0.13640290275257227, blue: 0.6155969066709956), Color(red: 0.6881304023085448, green: 0.773362018266375, blue: 0.27422838589125964), Color(red: 0.849961936057217, green: 0.7586882556081274, blue: 0.9806749861471977), Color(red: 0.18077673480614487, green: 0.7075890930835854, blue: 0.3794409024890758), Color(red: 0.9621409858313642, green: 0.5251173691370918, blue: 0.5473397659454173), Color(red: 0.030073263233168612, green: 0.9911722309388312, blue: 0.7044490541185094), Color(red: 0.09636076946953631, green: 0.3212767112889374, blue: 0.8224237351660009), Color(red: 0.5775986028879078, green: 0.006723053973318516, blue: 0.6541294641055974), Color(red: 0.10736635911286407, green: 0.5936683859081999, blue: 0.08156764905529912), Color(red: 0.18281881927738386, green: 0.663517517089398, blue: 0.5126892521242702), Color(red: 0.14082472044378302, green: 0.8805074091497703, blue: 0.2249436626483472), Color(red: 0.025635509099583453, green: 0.710714613026194, blue: 0.9493126810544574), Color(red: 0.8031455896850502, green: 0.5968051960943914, blue: 0.621107926611649), Color(red: 0.8860863353720091, green: 0.2981337393617485, blue: 0.47351066298967415), Color(red: 0.4467230596777373, green: 0.7667539665174006, blue: 0.30060444935536657), Color(red: 0.2682152554879308, green: 0.04825140482676227, blue: 0.5826420721202553), Color(red: 0.05816685242569075, green: 0.9742764601304645, blue: 0.31559382400790825), Color(red: 0.05193245008423686, green: 0.0638142781286356, blue: 0.12866774920076585), Color(red: 0.7112826442828688, green: 0.7403250325746545, blue: 0.7559238066415152), Color(red: 0.9412826541941588, green: 0.30248498080871944, blue: 0.6734812024435316), Color(red: 0.2849096388381507, green: 0.7213232425483225, blue: 0.8140502784245031), Color(red: 0.716579110806772, green: 0.03479371307890855, blue: 0.6454144690271081), Color(red: 0.06502355957215489, green: 0.8617620536639532, blue: 0.09167841471322447)]
