/*
    Search Area:
        ------------------------------------
            [ Form                  ] 􀄬
            [ To                    ]
            | 􀝈 ? mins | 􀝢 ? mins  |
        ------------------------------------
 
    Search List:
        ------------------------------------
            􀯶  [ From                ]  􀆄
            􀋒 Your Location
            􀝓 ???
            􀝈 ???
        ------------------------------------
*/

/*
    􀄬: arrow.up.arrow.down
    􀝈: bus
    􀝢: figure.walk
    􀯶: chevron.backward
    􀆄: xmark
    􀋒: location.fill
    􀝓: building.2.fill
*/


import Foundation
import SwiftUI

let INF: Double = 9999999

enum TransMode {
    case bus
    case foot
}

// To control which page to show
struct SearchView: View {
    @State var locations: [Location]
    @State var routes: [Route]
    @Binding var plans: [Plan]
    @Binding var planIndex: Int
    @ObservedObject var locationGetter: LocationGetterModel
    
    @State var startName = ""
    @State var endName = ""
    @State var startId = ""
    @State var endId = ""
    
    @Binding var mode: TransMode
    
    // height of plan view
    @Binding var lastHeight: CGFloat
    @Binding var height: CGFloat
    
    @State var showStartList = false
    @State var showEndList = false
    
    var body: some View {
        GeometryReader { geometry in
            if showStartList {
                // Page 1: search starting point
                SearchList(locations: locations, placeholder: "From", locationName: $startName, locationId: $startId, keyword: startName, showList: $showStartList)
            } else if showEndList {
                // Page 2: search ending point
                SearchList(locations: locations, placeholder: "To", locationName: $endName, locationId: $endId, keyword: endName, showList: $showEndList)
            } else {
                // Page 3: search box
                SearchArea(locations: locations, routes: routes, plans: $plans, planIndex: $planIndex, locationGetter: locationGetter, startName: startName, endName: endName, startId: startId, endId: endId, mode: $mode, showStartList: $showStartList, showEndList: $showEndList)
                    .offset(y: height > UIScreen.main.bounds.height * 0.1 ? (UIScreen.main.bounds.height * 0.1 - height) * 2 : 0)
                    .onAppear {
                        if startId != "" && endId != "" {
                            lastHeight = UIScreen.main.bounds.height * 0.1
                            height = UIScreen.main.bounds.height * 0.1
                        }
                    }
            }
        }
    }
}

// Search bar: to do route planning
struct SearchArea: View {
    @State var locations: [Location]
    @State var routes: [Route]
    @Binding var plans: [Plan]
    @Binding var planIndex: Int
    @ObservedObject var locationGetter: LocationGetterModel
    
    @State var startName: String
    @State var endName: String
    @State var startId: String
    @State var endId: String
    
    @Binding var mode: TransMode
    
    @Binding var showStartList: Bool
    @Binding var showEndList: Bool

    // animation for 􀄬
    @State var angle = 0.0
    
    var body: some View {
        // find min time for both mode
        var footTime = INF
        var busTime = INF
        for plan in plans {
            if plan.type == 0 && plan.time < footTime {
                footTime = plan.time
            }
            if plan.type == 1 && plan.time < busTime {
                busTime = plan.time
            }
        }
        
        return
            VStack(spacing: 20) {
                // search box
                HStack {
                    VStack(spacing: 12) {
                        TextField("From", text: $startName)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 0.8))
                            .onTapGesture { showStartList = true }
                        TextField("To", text: $endName)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 0.8))
                            .onTapGesture { showEndList = true }
                    }
                    Image(systemName: "arrow.up.arrow.down")
                        .imageScale(.large)
                        .rotationEffect(.degrees(angle))
                        .animation(Animation.easeInOut(duration: 0.1))
                        .padding(.leading)
                        .onTapGesture {
                            angle = 180 - angle
                            // swap
                            var tmp = startName
                            startName = endName
                            endName = tmp
                            tmp = startId
                            startId = endId
                            endId = tmp
                            RP()
                        }
                }
                // select mode
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        HStack {
                            Image(systemName: "bus").foregroundColor(Color.black.opacity(0.7))
                            if startId != "" && endId != "" {
                                busTime == INF ? Text("—") : Text("\(Int(busTime / 60)) min")
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(mode == .bus ? CUPurple.opacity(0.2) : nil)
                        .cornerRadius(20)
                        .onTapGesture { mode = .bus }
                        
                        HStack {
                            Image(systemName: "figure.walk").foregroundColor(Color.black.opacity(0.7))
                            if startId != "" && endId != "" {
                                footTime == INF ? Text("—") : Text("\(Int(footTime) / 60) min")
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(mode == .foot ? CUPurple.opacity(0.2) : nil)
                        .cornerRadius(20)
                        .onTapGesture { mode = .foot }
                    }
                }
            }
            // size and color
            .padding()
            .frame(width: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? UIScreen.main.bounds.height * 0.28 : UIScreen.main.bounds.height * 0.5, alignment: .bottom)
            .background(Color.white)
            .clipped()
            .shadow(radius: 4)
            .ignoresSafeArea(.all, edges: .top)
            .onAppear() {
                RP()
            }
    }
    private func RP() {
        plans = []
        let plan1 = RPMinDist(locations: locations, routes: routes, startId: startId, endId: endId)
        if plan1 != nil {
            plans.append(plan1!)
        }
        /*let plan2 = RPMinTime(locations: locations, routes: routes, startId: startId, endId: endId)
        if plan2 != nil {
            plans.append(plan2!)
        }*/
        
        planIndex = 0
    }
    
    /* private func dij() {
        if startId == "" || endId == "" {
            return
        }
        // TODO: deal with current location
        
        
        // Step 1: clean up result
        plans = []
        
        // Step 2: initialize minDist & vertex set & queue
        let startIndex = indexOf(id: startId)
        let endIndex = indexOf(id: endId)
        
        var minDist = [Plan](repeating: Plan(startId: startId, endId: endId, routes: [], dist: INF, time: INF, type: 0), count: locations.count) // distance from start location to every location
        var checked = [Bool](repeating: false, count: locations.count)
        minDist[startIndex].dist = 0
        minDist[startIndex].time = 0
        
        // Step 3: start
        while checked.filter({$0 == true}).count != checked.count { // not all have been checked
            // find the index of min dist who hasn't been checked
            var cur = -1
            var min = INF + 1.0
            for i in 0..<checked.count {
                if !checked[i] && minDist[i].dist < min {
                    cur = i
                    min = minDist[i].dist
                }
            }
            
            for route in routes {
                if route.startId == locations[cur].id {
                    let next = indexOf(id: route.endId)
                    if minDist[next].dist > minDist[cur].dist + route.dist { // update
                        minDist[next].dist = minDist[cur].dist + route.dist
                        minDist[next].routes = minDist[cur].routes + [route]
                        let time = route.type == 0 ? route.dist / footSpeed : route.dist / busSpeed
                        minDist[next].time = minDist[cur].time + time
                    }
                } else if route.endId == locations[cur].id {
                    let next = indexOf(id: route.startId)
                    if minDist[next].dist > minDist[cur].dist + route.dist { // update
                        var points = route.points
                        points.reverse()
                        minDist[next].dist = minDist[cur].dist + route.dist
                        minDist[next].routes = minDist[cur].routes + [Route(id: route.id, startId: route.endId, endId: route.startId, points: points, dist: route.dist, type: route.type)]
                        let time = route.type == 0 ? route.dist / footSpeed : route.dist / busSpeed
                        minDist[next].time = minDist[cur].time + time
                    }
                }
            }
            checked[cur] = true
        }
        
        // Step 4: find the result
        if minDist[endIndex].routes.count > 1 {
            plans.append(minDist[endIndex])
        }
    }
    
    private func indexOf(id: String) -> Int {
        for i in 0..<locations.count {
            if locations[i].id == id {
                return i
            }
        }
        return -1
    }*/
    
}

struct SearchList: View {
    @State var locations: [Location]
    
    var placeholder: String
    @Binding var locationName: String
    @Binding var locationId: String
    @State var keyword: String
    
    @Binding var showList: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .frame(minWidth: geometry.size.width, maxWidth: .infinity, minHeight: geometry.size.height, maxHeight: .infinity, alignment: .center)
                    .ignoresSafeArea(.all)
                VStack(spacing: 0) {
                    // text field
                    VStack(spacing: 0) {
                        HStack(spacing: 20) {
                            Image(systemName: "chevron.backward")
                                .imageScale(.large)
                                .onTapGesture { showList = false }
                            TextField(placeholder, text: $keyword)
                            if keyword != "" {
                                Image(systemName: "xmark")
                                    .imageScale(.large)
                                    .onTapGesture { keyword = "" }
                            }
                        }
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray, lineWidth: 0.8))
                        .padding()
                        // shadow
                        Rectangle()
                            .foregroundColor(.white)
                            .frame(width: UIScreen.main.bounds.width, height: 2)
                            .shadow(color: Color.gray.opacity(0.3), radius: 2, x: 0, y: 2)
                    }.padding(.bottom, 6)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // current location
                            Button(action: {
                                locationName = "Your Location"
                                locationId = "current"
                                showList = false
                            }) {
                                HStack(spacing: 20) {
                                    Image(systemName: "location.fill")
                                        .imageScale(.large)
                                        .foregroundColor(Color.blue)
                                        
                                    Text("Your Location")
                                    Spacer()
                                }.padding(.horizontal)
                            }.buttonStyle(MyButtonStyle())
                            Divider()
                                .padding(.horizontal)
                            // other locations
                            ForEach(locations) { location in
                                if keyword == "" || location.name_en.lowercased().contains(keyword.lowercased()) {
                                    SearchOption(name: $locationName, id: $locationId, location: location, showList: $showList)
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
}

struct SearchOption: View {
    @Binding var name: String
    @Binding var id: String
    @State var location: Location
    @Binding var showList: Bool
    
    var body: some View {
        Button(action: {
            name = location.name_en
            id = location.id
            showList = false
        }) {
            HStack(spacing: 20) {
                if location.type == 0 {
                    Image(systemName: "building.2.fill")
                        .imageScale(.large)
                        .foregroundColor(CUPurple)
                } else if location.type == 1 {
                    Image(systemName: "bus")
                        .imageScale(.large)
                        .foregroundColor(CUYellow)
                }
                Text(location.name_en)
                Spacer()
            }.padding(.horizontal)
        }.buttonStyle(MyButtonStyle())
    }
}

func RPMinDist(locations: [Location], routes: [Route], startId: String, endId: String) -> Plan? {
    // Step 1: preprocessing

    // avoid exception
    if startId == "" || endId == "" {
        return nil
    }
    let startIndex = indexOf(id: startId, locations: locations)
    let endIndex = indexOf(id: endId, locations: locations)
    if startIndex == -1 || endIndex == -1 {
        return nil
    }
    
    // Step 2: initialize minDist & vertex set & queue
    var plans = [Plan](repeating: Plan(startId: startId, endId: endId, routes: [], dist: INF, time: INF, type: 0), count: locations.count)
    var checked = [Bool](repeating: false, count: locations.count)
    plans[startIndex].dist = 0
    plans[startIndex].time = 0
    
    // Step 3: start
    while checked.filter({$0 == true}).count != checked.count { // not all have been checked
        // find the index of min dist who hasn't been checked
        var cur = -1
        var min = INF + 1.0
        for i in 0..<checked.count {
            if !checked[i] && plans[i].dist < min {
                cur = i
                min = plans[i].dist
            }
        }
        
        for route in routes {
            if route.startId == locations[cur].id {
                let next = indexOf(id: route.endId, locations: locations)
                if plans[next].dist > plans[cur].dist + route.dist { // update
                    plans[next].dist = plans[cur].dist + route.dist
                    plans[next].routes = plans[cur].routes + [route]
                    let time = route.type == 0 ? route.dist / footSpeed : route.dist / busSpeed
                    plans[next].time = plans[cur].time + time
                }
            } else if route.endId == locations[cur].id {
                let next = indexOf(id: route.startId, locations: locations)
                if plans[next].dist > plans[cur].dist + route.dist { // update
                    var points = route.points
                    points.reverse()
                    plans[next].dist = plans[cur].dist + route.dist
                    plans[next].routes = plans[cur].routes + [Route(_id: route.id, startId: route.endId, endId: route.startId, points: points, dist: route.dist, type: route.type)]
                    let time = route.type == 0 ? route.dist / footSpeed : route.dist / busSpeed
                    plans[next].time = plans[cur].time + time
                }
            }
        }
        checked[cur] = true
    }
    // Step 4: find the result
    if plans[endIndex].routes.count > 1 {
        return plans[endIndex]
    }
    
    return nil
}

func RPMinTime(locations: [Location], routes: [Route], startId: String, endId: String) -> Plan? {
    // Step 1: preprocessing

    // avoid exception
    if startId == "" || endId == "" {
        return nil
    }
    let startIndex = indexOf(id: startId, locations: locations)
    let endIndex = indexOf(id: endId, locations: locations)
    if startIndex == -1 || endIndex == -1 {
        return nil
    }
    
    // Step 2: initialize minTime & vertex set & queue
    var plans = [Plan](repeating: Plan(startId: startId, endId: endId, routes: [], dist: INF, time: INF, type: 0), count: locations.count)
    var checked = [Bool](repeating: false, count: locations.count)
    plans[startIndex].dist = 0
    plans[startIndex].time = 0
    
    // Step 3: start
    while checked.filter({$0 == true}).count != checked.count { // not all have been checked
        // find the index of min dist who hasn't been checked
        var cur = -1
        var min = INF + 1.0
        for i in 0..<checked.count {
            if !checked[i] && plans[i].time < min {
                cur = i
                min = plans[i].time
            }
        }
        
        for route in routes {
            let time = route.type == 0 ? route.dist / footSpeed : route.dist / busSpeed

            if route.startId == locations[cur].id {
                let next = indexOf(id: route.endId, locations: locations)
                if plans[next].time > plans[cur].time + time { // update
                    plans[next].time = plans[cur].time + time
                    plans[next].dist = plans[cur].dist + route.dist
                    plans[next].routes = plans[cur].routes + [route]
                }
            } else if route.endId == locations[cur].id {
                let next = indexOf(id: route.startId, locations: locations)
                if plans[next].time > plans[cur].time + time { // update
                    plans[next].time = plans[cur].time + time
                    plans[next].dist = plans[cur].dist + route.dist
                    
                    var points = route.points
                    points.reverse()
                    plans[next].routes = plans[cur].routes + [Route(_id: route.id, startId: route.endId, endId: route.startId, points: points, dist: route.dist, type: route.type)]
                }
            }
        }
        checked[cur] = true
    }
    // Step 4: find the result
    if plans[endIndex].routes.count > 1 {
        return plans[endIndex]
    }
    
    return nil
}

func indexOf(id: String, locations: [Location]) -> Int {
    for i in 0..<locations.count {
        if locations[i].id == id {
            return i
        }
    }
    return -1
}
