//
//  ContentView.swift
//  GetMap
//
//  Created by wanruuu on 24/10/2020.
//

import SwiftUI
import CoreData
import Foundation

struct ContentView: View {
    /* core data */
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [], animation: .default)
    var rawPaths: FetchedResults<RawPath>
    
    /* from server */
    @State var locations: [Location] = []
    
    var body: some View {
        MainPage(rawPaths: rawPaths, locations: $locations)
            .onAppear {
                loadLocationData()
            }
    }
    
    // MARK: - Request to Server
    private func loadLocationData() {
        let url = URL(string: server + "/locations")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            do {
                let res = try JSONDecoder().decode(Response.self, from: data)
                if(res.success) {
                    locations =  res.data
                }
            } catch let error {
                print(error)
            }
        }.resume()
    }
    private func uploadRawPath(locations: [CLLocation]) {
        /* data */
        var items: [[String: Any]] = []
        for location in locations {
            let item: [String: Any] = ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude, "altitude": location.altitude]
            items.append(item)
        }
        let json: [String: Any] = ["points": items]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let url = URL(string: server + "/trajectory")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if(error != nil) {
                print("error")
            } else {
                guard let data = data else { return }
                do {
                    let res = try JSONDecoder().decode(Response.self, from: data)
                    if(res.success) {
                        print("success")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct Response: Codable {
    let operation: String
    let target: String
    let success: Bool
    let data: [Location]
}
