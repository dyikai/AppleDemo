import Foundation
import Observation

@Observable
class KalmanFilter {
    static let shared = KalmanFilter(processNoise: 0.0005, measurementNoise: 0.01, biasProcessNoise: 0.005)
    
    var altitude: Double
    var verticalSpeed: Double = 0
    var baro: Double = 0
    var bias: Double
    var P: [[Double]]

    var processNoise: Double
    var measurementNoise: Double
    var biasProcessNoise: Double
    var deltaTime: TimeInterval = 1
    let threshold: Double = 0.01
    
    var lastAltitude: Double?
    var lastUpdateTime: Date?
    
    init(processNoise: Double, measurementNoise: Double, biasProcessNoise: Double) {
        self.altitude = -2
        self.bias = 0.0
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
        self.biasProcessNoise = biasProcessNoise
        
        // 初始化 3x3 协方差矩阵
        self.P = [
            [1.0, 0.0],
            [0.0, 1.0],
        ]
    }
    
    func predict() {
        altitude += deltaTime * verticalSpeed
        
        // 状态转移矩阵 F 为单位矩阵，所以状态不变。
        // 过程噪声矩阵 Q：
        // Q = [ [processNoise,      0],
        //       [         0, biasProcessNoise] ]
        P[0][0] += processNoise
        P[1][1] += biasProcessNoise
        // 注：若需要考虑状态之间的耦合，可对 off-diagonal 分量进行相应更新
    }
    
    /// 更新步骤：测量模型假设测量值为 (altitude + bias)
    func update(with measurement: Double) {
        let currentTime = Date()
        
        // 计算当前时间与上一次更新时间的时间间隔（若无则取 1.0 秒）
        if let lastTime = lastUpdateTime {
            deltaTime = currentTime.timeIntervalSince(lastTime)
        } else {
            deltaTime = 1.0
        }
        
        predict()
        
        // 测量残差
        let y = measurement - (altitude + bias)
        
        // 如果残差过小，则认为测量为噪声，此次不更新状态
        if abs(y) < threshold {
            return
        }
        
        // 观测矩阵 H = [1, 1]
        // 计算残差方差 S = H * P * Hᵀ + R
        // 其中 H * P * Hᵀ = P[0][0] + 2*P[0][1] + P[1][1]
        let S = P[0][0] + 2 * P[0][1] + P[1][1] + measurementNoise
        
        // 卡尔曼增益 K = P * Hᵀ / S
        let K0 = (P[0][0] + P[0][1]) / S
        let K1 = (P[1][0] + P[1][1]) / S  // 注意：P[1][0] 与 P[0][1] 相等
        
        // 更新状态
        altitude += K0 * y
        bias += K1 * y
        
        // 更新协方差矩阵 P
        // 简单更新公式：P = (I - K * H) * P
        // 这里只更新主对角线，off-diagonals 可根据需要进一步更新
        P[0][0] = (1 - K0) * P[0][0]
        P[1][1] = (1 - K1) * P[1][1]
        
        // 计算垂直速度：利用两次更新的高度差和时间间隔（可选平滑处理）
        if let lastAlt = lastAltitude, deltaTime > 0 {
            verticalSpeed = (altitude - lastAlt) / deltaTime
        }
        
        // 更新辅助变量
        lastAltitude = altitude
        lastUpdateTime = currentTime
    }
}
