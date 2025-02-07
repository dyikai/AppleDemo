import CoreMotion
import Foundation

class MotionService {
    static let shared = MotionService()
    
    private let kalmanFilter = KalmanFilter.shared
    private let altimeter = CMAltimeter()
    private let manager = CMMotionManager()
    var lastUpdateTime: Date?
}

// MARK: - Accelerometer
extension MotionService {
    func accelerometerUpdates() async -> AsyncThrowingStream<CMAccelerometerData, any Error> {
        AsyncThrowingStream { continuation in
            guard manager.isAccelerometerAvailable else {
                continuation.finish()
                return
            }
            
            manager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
                if let error = error {
                    continuation.finish(throwing: error)
                } else if let accelerometerData = accelerometerData {
                    continuation.yield(accelerometerData)
                }
            }
            
            continuation.onTermination = { @Sendable [self] _ in
                manager.stopAccelerometerUpdates()
            }
        }
    }
}

// MARK: - Barometer
extension MotionService {
    func startAltitudeUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            return
        }
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] altitudeData, error in
            if let error = error {
                print("error = \(error)")
            } else if let altitudeData = altitudeData {
                self?.handleBarometerData(altitudeData)
            }
        }
    }
    
    func stopAltitudeUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
    }
    
    func handleBarometerData(_ data: CMAltitudeData) {
        let measuredAltitude = data.relativeAltitude.doubleValue
        
        kalmanFilter.update(with: measuredAltitude)
        
        let printStr = String(format: "\(Date()) - Updating Barometer Data - Estimated Height: %.3f m, Vertical Speed: %.3f m/s, Baro: %.2f hpa", kalmanFilter.altitude, kalmanFilter.verticalSpeed, data.pressure.doubleValue * 10)
        debugPrint(printStr)
    }
}
