//
//  AcceleratorView.swift
//  iOSDemo
//
//  Created by 邓壹恺 on 2025-01-07.
//

import SwiftUI
import Combine
import Foundation
import CoreMotion

struct AcceleratorView: View {
    
    let viewData = ViewData()
    
    var body: some View {
        VStack(spacing: 10) {
            Text(viewData.content)
            
            Text("\(viewData.delta)")
        }
    }
}

@Observable
class ViewData {
    private var cancellables: Set<AnyCancellable> = []
    var content: String = "Hello world"
    
    var delta: Double = 0
    
    private let motionData = MotionData()
    
    init() {
        startObservation()
    }
    
    func startObservation() {
        motionData.subject
            .eraseToAnyPublisher()
            .scan((CMAcceleration(), CMAcceleration()), { tuple, currentValue in
                return (tuple.1, currentValue)
            })
            .map { [weak self] prev, curr in
                debugPrint("prev = \(prev) \ncurr = \(curr)\n")
                
                let delta = sqrt(pow(curr.x - prev.x, 2) +
                                 pow(curr.y - prev.y, 2) +
                                 pow(curr.z - prev.z, 2))
                
                self?.delta = delta
                
                if delta < 0.05 {
                    return true
                }
                
                return false
            }
            .removeDuplicates()
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] inMotion in
                if inMotion {
                    self?.content = "Pause"
                } else {
                    self?.content = "Running"
                }
            }
            .store(in: &cancellables)
    }
}


class MotionData {
    private let manager = CMMotionManager()
    
    let subject = PassthroughSubject<CMAcceleration, Never>()
    
    init() {
        startAccelerator()
    }
    
    func startAccelerator() {
        Task {
            for try await sample in await MotionService.shared.accelerometerUpdates() {
                self.subject.send(sample.acceleration)
            }
        }
    }
}
