/*
    MainPage.
    ---------------------
    |    Search View    |
    ---------------------
    |                   |
    |     Map View      |
    |                   |
    ---------------------
    |  Plans Text View  |
    ---------------------
 
 */

import Foundation
import SwiftUI

// MARK: - MapPage
struct MainPage: View {
    @State var locations: [Location]
    @State var routes: [Route]
    @ObservedObject var locationGetter: LocationGetterModel
    
    // search result
    @State var plans: [Plan] = []
    @State var mode: TransMode = .bus
    
    // height of plan view
    @State var lastHeight: CGFloat = 0
    @State var height: CGFloat = 0
    
    var body: some View {
        ZStack {
            MapView(plans: $plans, locationGetter: locationGetter, lastHeight: $lastHeight, height: $height)
            
            SearchView(locations: locations, routes: routes, plans: $plans, locationGetter: locationGetter, mode: $mode, lastHeight: $lastHeight, height: $height)
            
            PlansView(locations: locations, plans: $plans, lastHeight: $lastHeight, height: $height)
        }
    }
}