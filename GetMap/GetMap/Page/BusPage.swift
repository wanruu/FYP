import Foundation
import SwiftUI

struct BusPage: View {
    @State var buses: [Bus] = []
    
    @State var showSheet: Bool = false
    @State var sheetType: Int = -1 // 0: bus list, 1: new bus
    
    // gesture
    @State var offset: Offset = Offset(x: 0, y: 0)
    @State var lastOffset: Offset = Offset(x: 0, y: 0)
    @State var scale: CGFloat = minZoomOut
    @State var lastScale: CGFloat = minZoomOut
    var gesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
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
                    lastOffset.x = offset.x
                    lastOffset.y = offset.y
                },
            DragGesture()
                .onChanged{ value in
                    offset.x = lastOffset.x + value.location.x - value.startLocation.x
                    offset.y = lastOffset.y + value.location.y - value.startLocation.y
                }
                .onEnded{ _ in
                    lastOffset.x = offset.x
                    lastOffset.y = offset.y
                }
            )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // background map
                Image("cuhk-campus-map")
                    .resizable()
                    .frame(width: 3200 * scale, height: 3200 * 25 / 20 * scale, alignment: .center)
                    .position(x: centerX + offset.x, y: centerY + offset.y)
                    .gesture(gesture)
                
                VStack(spacing: 0) {
                    Button(action: {
                        sheetType = 0
                        showSheet = true
                    }) {
                        Image(systemName: "list.bullet")
                            .resizable()
                            .frame(width: SCWidth * 0.05, height: SCWidth * 0.04)
                            .padding(SCWidth * 0.03)
                            .padding(.vertical, SCWidth * 0.005)
                    }
                    Divider().frame(width: SCWidth * 0.11)
                    Button(action: {
                        sheetType = 1
                        showSheet = true
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: SCWidth * 0.05, height: SCWidth * 0.05)
                            .padding(SCWidth * 0.03)
                    }
                }
                .background(Color.white)
                .cornerRadius(SCWidth * 0.015)
                .shadow(radius: 10)
                .offset(x: SCWidth * 0.38, y: -SCHeight * 0.5 + SCWidth * 0.44)
            }
            .onAppear {
                loadBuses()
            }
            .sheet(isPresented: $showSheet) {
                Sheets(buses: $buses, type: $sheetType)
            }
        }
    }
    private func loadBuses() {
        let url = URL(string: server + "/buses")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            do {
                buses = try JSONDecoder().decode([Bus].self, from: data)
            } catch let error {
                print(error)
            }
        }.resume()
    }
}

struct Sheets: View {
    @Binding var buses: [Bus]
    @Binding var type: Int
    var body: some View {
        if type == 0 {
            BusList(buses: $buses)
        } else if type == 1 {
            NewBusSheet(buses: $buses)
        }
    }
}

struct BusList: View {
    @Binding var buses: [Bus]
    var body: some View {
        NavigationView {
            VStack {
                List(buses) { bus in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(bus.id).font(.title2)
                            Text(bus.name_en).font(.title2)
                            Text(bus.name_ch)
                        }
                        
                        HStack {
                            if bus.serviceDay == 0 {
                                Text("Mon - Sat")
                            } else if bus.serviceDay == 1 {
                                Text("Sun & Public Holidays")
                            } else {
                                Text("Teaching days only")
                            }
                            Text(bus.serviceHour)
                        }
                        
                        HStack {
                            Text("Departs hourly at")
                            ForEach(bus.departTime) { value in
                                Text("\(value)")
                            }
                            Text("mins")
                        }
                        VStack {
                            ForEach(bus.special) { rule in
                                HStack {
                                    Text("Buses departing at \(rule.departTime) minutes will")
                                    rule.stop ? nil : Text("not")
                                    Text("stop at \(rule.busStop)")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Bus List"))
        }
    }
}

struct NewBusSheet: View {
    @Binding var buses: [Bus]
    @State var id = ""
    @State var name_en = ""
    @State var name_ch = ""
    
    @State var startHour = "00:00"
    @State var endHour = "00:00"
    
    @State var serviceDay = 0
    
    @State var departTimes: [Int] = []
    @State var departTime = ""
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Part 1: ID
                    VStack(alignment: .leading, spacing: 10) {
                        Text("RouteID").bold()
                        TextField("e.g. 1a", text: $id)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
                    }
                    // Part 2: Name
                    VStack(alignment: .leading, spacing: 10) {
                        Text("English Name").bold()
                        TextField("e.g. Train Station", text: $name_en)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Chinese Name").bold()
                        TextField("e.g. 大學站", text: $name_ch)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
                    }
                    // Part 3: Service time
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Service time").bold()
                        HStack {
                            TimeTextField(time: $startHour)
                            Text("-")
                            TimeTextField(time: $endHour)
                        }
                        HStack {
                            CheckBox(options: ["Mon - Sat", "Sun & Public Holiday", "Teaching Days Only"], checked: $serviceDay, spacing: 15)
                            Spacer()
                        }
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
                    }
                    // Part 4: Depart time
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Departs Hourly at").bold()
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack {
                                ForEach(departTimes) { time in
                                    HStack(spacing: 20) {
                                        Text(String(time))
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .onTapGesture {
                                                let index = departTimes.firstIndex(of: time)!
                                                departTimes.remove(at: index)
                                            }
                                    }
                                    .padding()
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
                                }
                            }
                        }
                        
                        HStack {
                            TextField("", text: $departTime)
                                .keyboardType(.numberPad)
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
                                .onChange(of: departTime) { _ in
                                    if departTime.count > 2 {
                                        departTime = String(departTime.prefix(2))
                                    }
                                }
                            Button(action: {
                                departTimes.append(Int(departTime)!)
                                departTime = ""
                            }) { Image(systemName: "checkmark").padding() }
                            .buttonStyle(MyButtonStyle(bgColor: CUPurple, disabled: departTime == ""))
                            .disabled(departTime == "")
                        }
                        
                    }
                }.padding()
                
                // submit button
                Button(action: {
                    createBus()
                    // clear
                    id = ""
                    name_en = ""
                    name_ch = ""
                    startHour = "00:00"
                    endHour = "00:00"
                    serviceDay = 0
                    departTimes = []
                    departTime = ""
                }) { Text("Confirm").padding() }
                .buttonStyle(MyButtonStyle(bgColor: CUPurple, disabled: false))
                .disabled(false)
                
            }
            .navigationTitle(Text("New Bus Route"))
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    private func createBus() {
        let data: [String: Any] = [
            "id": id,
            "name_en": name_en,
            "name_ch": name_ch,
            "serviceHour": startHour + "-" + endHour,
            "serviceDay": serviceDay,
            "departTime": departTimes
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        let url = URL(string: server + "/bus")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let bus = try JSONDecoder().decode(Bus.self, from: data)
                buses.append(bus)
            } catch let error {
                print(error)
            }
        }.resume()
        
    }
}

struct TimeTextField: View {
    @Binding var time: String
    
    var body: some View {
        TextField("", text: $time, onEditingChanged: { _ in
            if time.count == 5 && time[time.index(time.startIndex, offsetBy: 2)] == ":" {
                time = String(time.prefix(2)) + String(time.suffix(2))
            } else if time.count == 4 {
                time = time.prefix(2) + ":" + time.suffix(2)
            }
        })
            .keyboardType(.numberPad)
        
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.8))
        
            .onChange(of: time) { _ in
                if time.count > 4 && time[time.index(time.startIndex, offsetBy: 2)] != ":"  {
                    time = String(time.suffix(4))
                    
                }
            }
    }
}
