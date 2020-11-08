/* MARK: draw clustered path unit */

/* Input: a path unit & color */

import Foundation
import SwiftUI

struct ClusteredPathView: View {
    @State var pathUnit: PathUnit
    @ObservedObject var locationGetter: LocationGetterModel
    @Binding var offset: Offset
    @Binding var scale: CGFloat
    @State var color: Color
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(
                x: centerX + CGFloat((pathUnit.start_point.coordinate.longitude - locationGetter.current.coordinate.longitude)*85390*2) * scale + offset.x,
                y: centerY + CGFloat((locationGetter.current.coordinate.latitude - pathUnit.start_point.coordinate.latitude)*111000*2) * scale + offset.y
            ))
            
            path.addLine(to: CGPoint(
                x: centerX + CGFloat((pathUnit.end_point.coordinate.longitude - locationGetter.current.coordinate.longitude)*85390*2) * scale + offset.x,
                y: centerY + CGFloat((locationGetter.current.coordinate.latitude - pathUnit.end_point.coordinate.latitude)*111000*2) * scale + offset.y
            ))
        }.stroke(color, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
    }
}
