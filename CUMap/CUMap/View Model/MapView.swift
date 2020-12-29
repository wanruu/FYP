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
            offset == lastOffset ? Animation.easeInOut(duration: 5)//0.4)
            .repeatCount(1, autoreverses: false) : nil
        )
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
                PlanMapView(plan: plan, opacity: 1, offset: $offset, scale: $scale)
            }
        }
    }
}

struct DrawPoint {
    var type: Int
    var x: CGFloat
    var y: CGFloat
}
extension DrawPoint: Identifiable {
    var id: String {
        "\(type)-\(x)-\(y)"
    }
}

struct PlanMapView: View {
    @State var plan: Plan
    @State var opacity: Double
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    
    var body: some View {
        // calculate points list to draw
        let DIST: CGFloat = (innerRadius * 1.5) * maxZoomIn / scale
        var points: [DrawPoint] = []

        var lastX = CGFloat((plan.routes[0].points[0].longitude - centerLg) * lgScale * 2)
        var lastY = CGFloat((centerLa - plan.routes[0].points[0].latitude) * laScale * 2)
        
        var distSoFar: CGFloat = 0
        
        for route in plan.routes {
            for point in route.points {
                let thisX = CGFloat((point.longitude - centerLg) * lgScale * 2)
                let thisY = CGFloat((centerLa - point.latitude) * laScale * 2)
                
                let dist = pow((lastX - thisX) * (lastX - thisX) + (lastY - thisY) * (lastY - thisY), 0.5)
                if distSoFar + dist < DIST {
                    distSoFar += dist
                } else {
                    distSoFar = 0
                    points.append(DrawPoint(type: route.type, x: thisX, y: thisY))
                }
                lastX = thisX
                lastY = thisY
            }
        }
        
        return
            ForEach(points) { point in
                Circle()
                    .frame(width: innerRadius, height: innerRadius, alignment: .center)
                    .foregroundColor(point.type == 0 ? CUPurple : CUYellow)
                    .position(x: centerX + point.x * scale + offset.x, y: centerY + point.y * scale + offset.y)
            }
    }
}
