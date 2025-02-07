import Foundation
import Observation

@Observable
class KalmanFilter {
    static let shared = KalmanFilter(processNoise: 0.0005, measurementNoise: 0.03, biasProcessNoise: 0.005)
    
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
    
    var lastUpdateTime: Date?
    
    init(processNoise: Double, measurementNoise: Double, biasProcessNoise: Double) {
        self.altitude = 0
        self.bias = 0.0
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
        self.biasProcessNoise = biasProcessNoise
        
        // 初始化 3x3 协方差矩阵（初始不确定性）
        self.P = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]
    }
    
    func predict() {
        // 计算时间间隔
        let currentTime = Date()
        if let lastTime = lastUpdateTime {
            deltaTime = currentTime.timeIntervalSince(lastTime)
        } else {
            deltaTime = 1.0
        }
        lastUpdateTime = currentTime
        
        let dt = deltaTime
        
        // 状态转移：使用常数速度模型
        // altitude_new = altitude + dt * verticalSpeed
        // verticalSpeed_new = verticalSpeed
        // bias_new = bias
        altitude = altitude + dt * verticalSpeed
        
        // 状态转移矩阵 F
        // F = [ [1, dt, 0],
        //       [0,  1, 0],
        //       [0,  0, 1] ]
        //
        // 完整的协方差矩阵更新：P = F * P * Fᵀ + Q
        //
        // 首先计算 F * P
        let FP00 = P[0][0] + dt * P[1][0]
        let FP01 = P[0][1] + dt * P[1][1]
        let FP02 = P[0][2] + dt * P[1][2]
        
        let FP10 = P[1][0]
        let FP11 = P[1][1]
        let FP12 = P[1][2]
        
        let FP20 = P[2][0]
        let FP21 = P[2][1]
        let FP22 = P[2][2]
        
        // 计算 newP = (F * P) * Fᵀ
        // Fᵀ = [ [1, dt, 0],
        //        [0,  1, 0],
        //        [0,  0, 1] ]
        let newP00 = FP00 + dt * FP01
        let newP01 = FP01              // = P[0][1] + dt*P[1][1]
        let newP02 = FP02              // = P[0][2] + dt*P[1][2]
        let newP10 = FP10 + dt * FP11   // = P[1][0] + dt*P[1][1]
        let newP11 = FP11             // = P[1][1]
        let newP12 = FP12             // = P[1][2]
        let newP20 = FP20 + dt * FP21   // = P[2][0] + dt*P[2][1]
        let newP21 = FP21             // = P[2][1]
        let newP22 = FP22             // = P[2][2]
        
        // 过程噪声 Q 的构造：
        // Q = [ [dt^4/4 * processNoise, dt^3/2 * processNoise,      0],
        //       [dt^3/2 * processNoise, dt^2   * processNoise,      0],
        //       [0,                     0,                     biasProcessNoise] ]
        let q00 = (dt * dt * dt * dt / 4.0) * processNoise
        let q01 = (dt * dt * dt / 2.0) * processNoise
        let q11 = (dt * dt) * processNoise
        let q22 = biasProcessNoise
        
        // 更新协方差矩阵 P（注意保证矩阵对称）
        P[0][0] = newP00 + q00
        P[0][1] = newP01 + q01
        P[0][2] = newP02
        P[1][0] = newP10 + q01   // 对称于 P[0][1]
        P[1][1] = newP11 + q11
        P[1][2] = newP12
        P[2][0] = newP20
        P[2][1] = newP21
        P[2][2] = newP22 + q22
    }
    
    /// 更新步骤：测量模型假设测量值为 (altitude + bias)
    func update(with measurement: Double) {
        predict()
        
        // 测量残差
        let y = measurement - (altitude + bias)
        
        // 如果残差过小，则认为测量为噪声，此次不更新状态
        if abs(y) < threshold {
            return
        }
        
        // 测量矩阵 H = [1, 0, 1]
        // 创新协方差 S = H * P * Hᵀ + R，其中 H * P * Hᵀ = P[0][0] + 2*P[0][2] + P[2][2]
        let S = P[0][0] + 2 * P[0][2] + P[2][2] + measurementNoise
        
        // 卡尔曼增益 K = P * Hᵀ / S，注意 Hᵀ = [1, 0, 1]ᵀ
        let K0 = (P[0][0] + P[0][2]) / S
        let K1 = (P[1][0] + P[1][2]) / S
        let K2 = (P[2][0] + P[2][2]) / S
        
        // 更新状态向量
        altitude += K0 * y
        verticalSpeed += K1 * y
        bias += K2 * y
        
        // 更新协方差矩阵 P：采用 P = P - K*(H*P)
        // 先计算 H*P（H 是 1x3，P 是 3x3，结果为 1x3 向量）
        let HP0 = P[0][0] + P[2][0]
        let HP1 = P[0][1] + P[2][1]
        let HP2 = P[0][2] + P[2][2]
        
        // 对于每个 P[i][j] 更新为：P[i][j] = P[i][j] - K[i] * (H*P)[j]
        for i in 0..<3 {
            for j in 0..<3 {
                let K_i: Double
                switch i {
                case 0: K_i = K0
                case 1: K_i = K1
                case 2: K_i = K2
                default: K_i = 0
                }
                let HP_j: Double
                switch j {
                case 0: HP_j = HP0
                case 1: HP_j = HP1
                case 2: HP_j = HP2
                default: HP_j = 0
                }
                P[i][j] -= K_i * HP_j
            }
        }
    }
}
