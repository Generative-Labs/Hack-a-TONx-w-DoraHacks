//
//  PingManager.swift
//  
//
//  Created by X Tommy on 2023/1/2.
//

import Foundation
import Combine

enum WebSocketPingEvent {
    ///
    case sendPing
    ///
    case disconnectOnNoPongReceived
}

class WebSocketPingManager {
    
    /// The time interval to ping connection to keep it alive.
    static let pingTimeInterval: TimeInterval = 60
    
    /// The time interval for pong timeout.
    static let pongTimeoutTimeInterval: TimeInterval = 20
    
    private let timerType: Timer.Type
    private let timerQueue: DispatchQueue
    
    private var pingTimerControl: RepeatingTimerControl?
    
    private var pongTimeoutTimer: TimerControl?
    
    ///
    public var eventPublisher: AnyPublisher<WebSocketPingEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private let eventSubject = PassthroughSubject<WebSocketPingEvent, Never>()
    
    deinit {
        cancelPongTimeoutTimer()
    }
    
    /// Creates a ping controller.
    /// - Parameters:
    ///   - timerType: a timer type.
    ///   - timerQueue: a timer dispatch queue.
    init(timerType: Timer.Type, timerQueue: DispatchQueue) {
        self.timerType = timerType
        self.timerQueue = timerQueue
    }
    
    /// `WebSocket` should call this when the connection state did change.
    func connectionStateDidChange(_ connectionStatus: ConnectionStatus) {
        cancelPongTimeoutTimer()
        schedulePingTimerIfNeeded()
        
        if connectionStatus.isConnected {
            Log.print("Resume WebSocket Ping timer")
            pingTimerControl?.resume()
        } else {
            pingTimerControl?.suspend()
        }
    }
    
    // MARK: - Ping
    
    private func sendPing() {
        schedulePongTimeoutTimer()

        Log.print("WebSocket Ping")
        eventSubject.send(.sendPing)
    }
    
    func pongReceived() {
        Log.print("WebSocket Pong")
        cancelPongTimeoutTimer()
    }
    
    // MARK: Timers
    
    private func schedulePingTimerIfNeeded() {
        guard pingTimerControl == nil else { return }
        pingTimerControl = timerType.scheduleRepeating(timeInterval: WebSocketPingManager.pingTimeInterval, queue: timerQueue) { [weak self] in
            self?.sendPing()
        }
    }
    
    private func schedulePongTimeoutTimer() {
        cancelPongTimeoutTimer()
        // Start pong timeout timer.
        pongTimeoutTimer = timerType.schedule(timeInterval: WebSocketPingManager.pongTimeoutTimeInterval, queue: timerQueue) { [weak self] in
            print("WebSocket Pong timeout. Reconnect")
            self?.eventSubject.send(.disconnectOnNoPongReceived)
        }
    }
    
    private func cancelPongTimeoutTimer() {
        pongTimeoutTimer?.cancel()
        pongTimeoutTimer = nil
    }
}
