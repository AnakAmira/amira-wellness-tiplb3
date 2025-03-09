//
//  NetworkMonitor.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Network // Latest
import Combine // Latest

// Internal imports
import Logger
import AppConstants

/// Represents the possible network connectivity states
enum NetworkStatus {
    case connected
    case disconnected
}

/// A singleton class that monitors network connectivity status and publishes changes
class NetworkMonitor {
    /// Shared instance of NetworkMonitor
    static let shared = NetworkMonitor()
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.amirawellness.networkMonitor")
    private var isMonitoring = false
    private var currentStatus: NetworkStatus = .disconnected
    
    private let statusSubject = PassthroughSubject<NetworkStatus, Never>()
    
    // MARK: - Public Properties
    
    /// Publisher for network status changes
    public var statusPublisher: AnyPublisher<NetworkStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Configure the path monitor to process network status changes
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity changes
    func startMonitoring() {
        // Check if already monitoring to avoid duplicate monitoring
        guard !isMonitoring else { return }
        
        // Start the NWPathMonitor
        monitor.start(queue: monitorQueue)
        isMonitoring = true
        Logger.shared.logNetwork("Network monitoring started", level: .info)
    }
    
    /// Stops monitoring network connectivity changes
    func stopMonitoring() {
        // Check if currently monitoring
        guard isMonitoring else { return }
        
        // Cancel the NWPathMonitor
        monitor.cancel()
        isMonitoring = false
        Logger.shared.logNetwork("Network monitoring stopped", level: .info)
    }
    
    /// Returns whether the device currently has network connectivity
    /// - Returns: True if connected to the internet, false otherwise
    func isConnected() -> Bool {
        return currentStatus == .connected
    }
    
    /// Returns the current network connection type
    /// - Returns: Description of the connection type (WiFi, Cellular, etc.)
    func getConnectionType() -> String {
        // Check the monitor.currentPath.interfaceType
        if let interfaceType = monitor.currentPath.availableInterfaces.first?.type {
            switch interfaceType {
            case .wifi:
                return "WiFi"
            case .cellular:
                return "Cellular"
            case .wiredEthernet:
                return "Wired"
            case .loopback:
                return "Loopback"
            case .other:
                return "Other"
            @unknown default:
                return "Unknown"
            }
        }
        return "Unknown"
    }
    
    /// Determines if the current connection is considered expensive (e.g., cellular data)
    /// - Returns: True if the connection is expensive, false otherwise
    func isExpensiveConnection() -> Bool {
        // Check monitor.currentPath.isExpensive property
        return monitor.currentPath.isExpensive
    }
    
    /// Determines if the current connection has constraints (e.g., low data mode)
    /// - Returns: True if the connection is constrained, false otherwise
    func isConstrained() -> Bool {
        // Check monitor.currentPath.isConstrained property
        return monitor.currentPath.isConstrained
    }
    
    // MARK: - Private Methods
    
    /// Processes network path updates and publishes status changes
    /// - Parameter path: The updated network path
    private func handlePathUpdate(_ path: NWPath) {
        // Determine if the path has internet connectivity using path.status
        let newStatus: NetworkStatus = (path.status == .satisfied) ? .connected : .disconnected
        
        // Check if the status has changed from the current status
        if newStatus != currentStatus {
            // Update currentStatus and publish the new status
            currentStatus = newStatus
            statusSubject.send(currentStatus)
            
            // Log the network status change with appropriate details
            let statusText = (currentStatus == .connected) ? "Connected" : "Disconnected"
            let connectionType = currentStatus == .connected ? getConnectionType() : "None"
            let expensiveText = currentStatus == .connected && isExpensiveConnection() ? "expensive" : "not expensive"
            let constrainedText = currentStatus == .connected && isConstrained() ? "constrained" : "not constrained"
            
            // Include connection type and constraints in the log
            Logger.shared.logNetwork(
                "Network status changed: \(statusText), Type: \(connectionType), Connection is \(expensiveText) and \(constrainedText)",
                level: .info
            )
        }
    }
}