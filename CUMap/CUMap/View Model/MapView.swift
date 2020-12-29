/*
    Map View.
    - User Current Location
    - Search Result: plans
 */

import Foundation
import SwiftUI

struct MapView: View {
    @Binding var plans: [Plan]
    @ObservedObject var locationGetter: LocationGetterModel
    
    @Binding var lastHeight: CGFloat
    @Binding var height: CGFloat
    
    /* gesture */
    @State var lastOffset = Offset(x: 0, y: 0)
    @State var offset = Offset(x: 0, y: 0)
    @State var lastScale = initialZoom
    @State var scale = initialZoom
    
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
                    lastOffset = offset
                },
            DragGesture()
                .onChanged{ value in
                    offset.x = lastOffset.x + value.location.x - value.startLocation.x
                    offset.y = lastOffset.y + value.location.y - value.startLocation.y
                }
                .onEnded{ _ in
                    lastOffset = offset
                }
        )
    }
    
    var body: some View {
        // TODO: calculate offset to ensure plan is at center of map
        ZStack {
            Image("cuhk-campus-map")
                .resizable()
                .frame(width: 3200 * scale, height: 3200 * 25 / 20 * scale, alignment: .center)
                .position(x: centerX + offset.x, y: centerY + offset.y)
                    
            PlansMapView(plans: $plans, offset: $offset, scale: $scale)
            
            UserPoint(locationGetter: locationGetter, offset: $offset, scale: $scale)

        }
        // animation
        .offset(y: lastHeight == largeH ? 0 : -lastHeight + smallH)
        .animation(
            offset == lastOffset ? Animation.easeInOut(duration: 0.4)
            .repeatCount(1, autoreverses: false) : nil
        )
        .clipShape(Rectangle())
        // gesture
        .gesture(gesture)
    }
}

struct PlansMapView: View {
    @Binding var plans: [Plan]
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(plans) { plan in
                ForEach(plan.routes) { route in
                    // Display a route
                    Path { path in
                        for i in 0..<route.points.count {
                            let point = CGPoint(
                                x: centerX + CGFloat((route.points[i].longitude - centerLg) * lgScale * 2) * scale + offset.x,
                                y: centerY + CGFloat((centerLa - route.points[i].latitude) * laScale * 2) * scale + offset.y
                            )
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }.stroke(route.type == 0 ? CUPurple : CUYellow, style: StrokeStyle(lineWidth: 5, lineJoin: .round))
                }
            }
        }
    }
}