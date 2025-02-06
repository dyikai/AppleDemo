import SwiftUI

struct VerticalSpeedView: View {
    let kalmanFilter = KalmanFilter.shared
    let motionService = MotionService.shared
    
    init() {
        motionService.startAltitudeUpdates()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Altitude: \(kalmanFilter.altitude)")
            
            Text("VerticalSpeed: \(kalmanFilter.verticalSpeed) m/s")
        }
    }
}
