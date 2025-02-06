import Foundation

actor TemperatureLogger {
    let label: String
    var measurements: [Int]
    private(set) var max: Int


    init(label: String, measurement: Int) {
        self.label = label
        self.measurements = [measurement]
        self.max = measurement
        
        Task {
            await self.convertFahrenheitToCelsius()
        }
    }
}

extension TemperatureLogger: CustomStringConvertible {
    nonisolated var description: String {
        "The label of the logger is \(label)."
    }
    
    func convertFahrenheitToCelsius() {
        measurements = measurements.map { measurement in
            (measurement - 32) * 5 / 9
        }
        
        Task {
            max = 0
            print("task  -- \(max)")
        }
        
        max = 1
        print("main  -- \(max)")
    }
}

Task {
    await MainActor.run {
        print(Thread.current)
    }
}
try await Task.sleep(for: .seconds(1))
