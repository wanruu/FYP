/* MARK: display map */

import Foundation
import SwiftUI

// MARK: - overall map, containning raw trajectories, processed path, user location, locations, user path
struct MapView: View {
    @Binding var locations: [Location]
    @Binding var trajectories: [[Coor3D]]
    @Binding var representatives: [[Coor3D]]
    @ObservedObject var locationGetter: LocationGetterModel
    
    @Binding var showCurrentLocation: Bool
    @Binding var showRawPaths: Bool
    @Binding var showLocations: Bool
    @Binding var showRepresentPaths: Bool
    
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    var body: some View {
        ZStack(alignment: .bottom) {
            /* user paths */
            UserPathsView(locationGetter: locationGetter, offset: $offset, scale: $scale)
            
            /* raw trajectories */
            showRawPaths ? TrajsView(trajectories: $trajectories, locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
            
            /* Representative path */
            showRepresentPaths ? RepresentPathsView(representatives: $representatives, locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
            
            /* user location */
            showCurrentLocation ? UserPoint(locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
            
            /* location point */
            showLocations ? LocationsView(locations: $locations, locationGetter: locationGetter, offset: $offset, scale: $scale) : nil
        }
    }
}

// MARK: - display raw trajectories
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

// MARK: - display representative trajectory
struct RepresentPathsView: View {
    @Binding var representatives: [[Coor3D]]
    @ObservedObject var locationGetter: LocationGetterModel
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    var body: some View {
        Path { p in
            for i in 0..<representatives.count {
                for j in 0..<representatives[i].count {
                    let point = CGPoint(
                        x: centerX + CGFloat((representatives[i][j].longitude - locationGetter.current.coordinate.longitude)*lgScale*2) * scale + offset.x,
                        y: centerY + CGFloat((locationGetter.current.coordinate.latitude - representatives[i][j].latitude)*laScale*2) * scale + offset.y
                    )
                    if(j == 0) {
                        p.move(to: point)
                    } else {
                        p.addLine(to: point)
                    }
                }
            }
        }.stroke(Color.pink.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
    }
}

// MARK: - display locations
struct LocationsView: View {
    @Binding var locations: [Location]
    @ObservedObject var locationGetter: LocationGetterModel
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    var body: some View {
        ForEach(locations) { location in
            let x = centerX + CGFloat((location.longitude - locationGetter.current.coordinate.longitude)*lgScale*2) * scale + offset.x
            let y = centerY + CGFloat((locationGetter.current.coordinate.latitude - location.latitude)*laScale*2) * scale + offset.y
            Text(location.name_en).position(x: x, y: y)
        }
    }
}

// MARK: - display user path
struct UserPathsView: View {
    @ObservedObject var locationGetter: LocationGetterModel
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    var body: some View {
        Path { p in
            /* draw paths of point list */
            for path in locationGetter.paths {
                for location in path {
                    let point = CGPoint(
                        x: centerX + CGFloat((location.coordinate.longitude - locationGetter.current.coordinate.longitude)*lgScale*2) * scale + offset.x,
                        y: centerY + CGFloat((locationGetter.current.coordinate.latitude - location.coordinate.latitude)*laScale*2) * scale + offset.y
                    )
                    if(location == path[0]) {
                        p.move(to: point)
                    } else {
                        p.addLine(to: point)
                    }
                }
            }
        }.stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
    }
}
