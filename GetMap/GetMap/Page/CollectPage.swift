// MARK: For collecting data

import Foundation
import SwiftUI

struct CollectPage: View {
    @Binding var locations: [Location]
    @Binding var trajectories: [[Coor3D]]
    
    // gesture
    @State var lastOffset = Offset(x: 0, y: 0)
    @State var offset = Offset(x: 0, y: 0)
    @State var lastScale = minZoomOut
    @State var scale = minZoomOut
    @State var isGestureChanging = false
    
    // add location window
    @State var showAddLocation = false
    
    // collect traj data
    @ObservedObject var locationGetter = LocationGetterModel()
    
    // if user point is at the center
    @State var mode: NavigationMode = .normal
    
    // if locations are being recorded
    @State var isRecording = true
    
    // uploading
    @State var showUploadAlert = false
    
    var body: some View {
        withAnimation {
            ZStack {
                Image("cuhk-campus-map")
                    .resizable()
                    .frame(width: 3200 * scale, height: 3200 * 25 / 20 * scale, alignment: .center)
                    .position(x: centerX + offset.x, y: centerY + offset.y)
                    // Gesture
                    .contentShape(Rectangle())
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                            .onChanged { value in
                                isGestureChanging = true
                                var tmpScale = lastScale * value.magnitude
                                if(tmpScale < minZoomOut) {
                                    tmpScale = minZoomOut
                                } else if(tmpScale > maxZoomIn) {
                                    tmpScale = maxZoomIn
                                }
                                scale = tmpScale
                                offset = lastOffset * tmpScale / lastScale
                            }
                            .onEnded { _ in
                                lastScale = scale
                                lastOffset = offset
                                isGestureChanging = false
                            },
                            DragGesture()
                            .onChanged{ value in
                                isGestureChanging = true
                                mode = .normal
                                offset.x = lastOffset.x + value.location.x - value.startLocation.x
                                offset.y = lastOffset.y + value.location.y - value.startLocation.y
                            }
                            .onEnded{ _ in
                                lastOffset = offset
                                isGestureChanging = false
                            }
                        )
                    )
                // trajs data from server
                TrajsView(trajectories: $trajectories, color: Color.gray, offset: $offset, scale: $scale)
                // recording trajectory
                isRecording ? UserPathsView(locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
                
                UserPoint(locationGetter: locationGetter, offset: $offset, scale: $scale)
                
                // tool bar
                showAddLocation ? nil : VStack {
                    Spacer()
                    HStack {
                        // change navigation mode
                        Button(action: {
                            if(mode == .normal) {
                                mode = .undirected
                                if(!isGestureChanging) {
                                    offset.x = CGFloat((centerLg - locationGetter.current.longitude)*lgScale*2) * scale
                                    offset.y = CGFloat((locationGetter.current.latitude - centerLa)*laScale*2) * scale
                                    lastOffset = offset
                                }
                            } else if(mode == .directed) {
                                mode = .normal
                                if(!isGestureChanging) {
                                    offset.x = CGFloat((centerLg - locationGetter.current.longitude)*lgScale*2) * scale
                                    offset.y = CGFloat((locationGetter.current.latitude - centerLa)*laScale*2) * scale
                                    lastOffset = offset
                                }
                            } else {
                                mode = .directed
                            }
                        }) {
                            mode == .normal ?
                                Image(systemName: "location")
                                .resizable()
                                .frame(width: SCWidth * 0.08, height: SCWidth * 0.08, alignment: .center) : nil
                            mode == .undirected ?
                                Image(systemName: "location.fill")
                                .resizable()
                                .frame(width: SCWidth * 0.08, height: SCWidth * 0.08, alignment: .center) : nil
                            mode == .directed ?
                                Image(systemName: "location.north.line.fill")
                                .resizable()
                                .frame(width: SCWidth * 0.055, height: SCWidth * 0.09, alignment: .center) : nil
                        }
                        .frame(width: SCWidth * 0.1, height: SCWidth * 0.1, alignment: .center)
                        .padding()
                        
                        // start/stop record trajectory
                        Button(action: {
                            isRecording ? uploadTrajs() : startRecord()
                            isRecording = !isRecording
                        }) {
                            isRecording ?
                                Image(systemName: "stop.circle")
                                .resizable()
                                .frame(width: SCWidth * 0.08, height: SCWidth * 0.08, alignment: .center) :
                                Image(systemName: "largecircle.fill.circle")
                                .resizable()
                                .frame(width: SCWidth * 0.08, height: SCWidth * 0.08, alignment: .center)
                        }
                        .frame(width: SCWidth * 0.1, height: SCWidth * 0.1, alignment: .center)
                        .padding()
                        
                        // delete recorded traj
                        Button(action: {
                            startRecord()
                        }) {
                            Image(systemName: "trash")
                            .resizable()
                            .frame(width: SCWidth * 0.08, height: SCWidth * 0.08, alignment: .center)
                        }
                        .frame(width: SCWidth * 0.1, height: SCWidth * 0.1, alignment: .center)
                        .padding()
                    }
                }
            }
        }
        // navigation bar
        .navigationTitle("Collect")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button(action: {
                showAddLocation = true
            }) {
                Image(systemName: "plus.circle").imageScale(.large).contentShape(Rectangle())
            }
        )
        .newLocationPrompt(isShowing: $showAddLocation, locations: $locations, locationGetter: locationGetter)
        // alert
        .alert(isPresented: $showUploadAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Failed to upload."),
                dismissButton: Alert.Button.default(Text("Try again")) {
                    uploadTrajs()
                }
            )
        }
    }
    private func startRecord() {
        locationGetter.trajs = []
        locationGetter.trajs.append([])
        locationGetter.trajsIndex = 0
        locationGetter.trajs[0].append(locationGetter.current)
    }
    private func uploadTrajs() {
        var trajs: [[[String: Any]]] = []
        for traj in locationGetter.trajs {
            var points: [[String: Any]] = []
            for point in traj {
                points.append(["latitude": point.latitude, "longitude": point.longitude, "altitude": point.altitude])
            }
            trajs.append(points)
        }

        let json = ["trajectories": trajs]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let url = URL(string: server + "/trajectories")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if(error != nil) {
                showUploadAlert = true
            } else {
                guard let data = data else { return }
                do {
                    let res = try JSONDecoder().decode(TrajResponse.self, from: data)
                    if(res.success) {
                        for traj in locationGetter.trajs {
                            trajectories.append(traj)
                        }
                    } else {
                        showUploadAlert = true
                    }
                } catch let error {
                    print(error)
                }
            }
        }.resume()
    }
}

struct NewLocationPrompt<Presenting>: View where Presenting: View {
    @Binding var isShowing: Bool
    @Binding var locations: [Location]
    @ObservedObject var locationGetter: LocationGetterModel
    
    @State var locationName: String = ""
    @State var locationType: String = ""
    
    let presenting: Presenting
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                presenting.disabled(isShowing)
                VStack {
                    Text("New Location").bold().padding()
                    TextField("Name", text: $locationName).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)
                    TextField("Type", text: $locationType).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)
                    Divider()
                    HStack {
                        Button(action: {
                            withAnimation {
                                addLocation()
                                hideKeyboard()
                                isShowing.toggle()
                            }
                        }) {
                            Text("Confirm")
                        }
                        .padding(.horizontal, SCWidth * 0.08)
                        .disabled(locationName == "" || locationType == "")
                        
                        Divider()
                        Button(action: {
                            withAnimation {
                                isShowing.toggle()
                                hideKeyboard()
                                locationName = ""
                                locationType = ""
                            }
                        }) {
                            Text("Cancel")
                        }.padding(.horizontal, SCWidth * 0.08)
                    }
                    .frame(
                        width: SCWidth * 0.7,
                        height: SCHeight * 0.055
                    )
                }
                .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                .frame(
                    width: SCWidth * 0.7,
                    height: SCHeight * 0.7
                )
                .cornerRadius(50)
                .opacity(self.isShowing ? 1 : 0)
                .offset(x: 0, y: -SCHeight * 0.1)
                
            }
        }
    }
    private func addLocation() {
        // data
        let latitude = locationGetter.current.latitude
        let longitude = locationGetter.current.longitude
        let altitude = locationGetter.current.altitude
        let type = Int(locationType)!
        let dataStr = "name_en=" + String(locationName) + "&latitude=" + String(latitude)  + "&longitude=" + String(longitude) + "&altitude=" + String(altitude) + "&type=" + String(type)
        
        let url = URL(string: server + "/location")!
        var request = URLRequest(url: url)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = dataStr.data(using: String.Encoding.utf8)

        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if(error != nil) {
                print("error")
            } else {
                guard let data = data else { return }
                do {
                    let res = try JSONDecoder().decode(LocResponse.self, from: data)
                    if(res.success) {
                        let newLocation = Location(name_en: locationName, latitude: latitude, longitude: longitude, altitude: altitude, type: type)
                        locations.append(newLocation)
                        locationName = ""
                        locationType = ""
                    } else {
                        print("error")
                    }
                } catch let error {
                    print(error)
                }
            }
        }.resume()
    }
}

extension View {
    func newLocationPrompt(isShowing: Binding<Bool>, locations: Binding<[Location]>, locationGetter: LocationGetterModel) -> some View {
        withAnimation {
            NewLocationPrompt(isShowing: isShowing, locations: locations, locationGetter: locationGetter, presenting: self)
        }
    }
}
