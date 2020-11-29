/* MARK: display map */

import Foundation
import SwiftUI
import CoreLocation


struct MapView: View {
    @ObservedObject var locationGetter: LocationGetterModel
    @Binding var trajectories: [[Coor3D]]
    @Binding var locations: [Location]
    
    /* display control */
    @Binding var showCurrentLocation: Bool
    @Binding var showRawPaths: Bool
    @Binding var showLocations: Bool
    @Binding var showRepresentPaths: Bool
    
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    /* generated by algorithm */
    @Binding var pathUnits: [PathUnit]
    @Binding var representPaths: [[CLLocation]]

    
    var body: some View {
        ZStack(alignment: .bottom) {
            /* user paths */
            UserPathsView(locationGetter: locationGetter, offset: $offset, scale: $scale)
            
            /* raw trajectories */
            showRawPaths ? TrajsView(trajectories: $trajectories, locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
            
            /* Representative path */
            showRepresentPaths ?
                RepresentPathsView(representPaths: representPaths, locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
            
            /* current location point */
            showCurrentLocation ?
                UserPoint(locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
            
            /* location point */
            showLocations ?
                ForEach(0..<locations.count) { i in
                    LocationPoint(location: locations[i], locationGetter: locationGetter, offset: $offset, scale: $scale)
                } : nil
        }
    }
}

struct TrajsView: View {
    @Binding var trajectories: [[Coor3D]]
    @ObservedObject var locationGetter: LocationGetterModel
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    var body: some View {
        Path { p in
            for i in 0..<trajectories.count {
                for j in 0..<trajectories[i].count {
                    let point = CGPoint(
                        x: centerX + CGFloat((trajectories[i][j].longitude - locationGetter.current.coordinate.longitude)*lgScale*2) * scale + offset.x,
                        y: centerY + CGFloat((locationGetter.current.coordinate.latitude - trajectories[i][j].latitude)*laScale*2) * scale + offset.y
                    )
                    if(j == 0) {
                        p.move(to: point)
                    } else {
                        p.addLine(to: point)
                    }
                }
            }
        }.stroke(Color.gray, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
    }
}
