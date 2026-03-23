import Foundation
import Network
import Combine

/// Monitors network connectivity and provides reactive updates.
@MainActor
final class NetworkMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published State

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    // MARK: - Connection Type

    enum ConnectionType: String, Sendable {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    // MARK: - Private Properties

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue

    // MARK: - Initialization

    private init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "com.rumo.networkmonitor", qos: .utility)

        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Starts monitoring network changes
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops monitoring network changes
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }

    /// Waits for network connectivity with timeout
    func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        if isConnected { return true }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            // Setup timeout
            let timeoutTask = Task {
                try? await Task.sleep(for: .seconds(timeout))
                cancellable?.cancel()
                continuation.resume(returning: false)
            }

            // Watch for connection
            cancellable = $isConnected
                .filter { $0 }
                .first()
                .sink { _ in
                    timeoutTask.cancel()
                    continuation.resume(returning: true)
                }
        }
    }

    // MARK: - Private Methods

    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case decodingError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return String(localized: "error.network.noConnection")
        case .timeout:
            return String(localized: "error.network.timeout")
        case .serverError(let code):
            return String(localized: "error.network.server \(code)")
        case .decodingError:
            return String(localized: "error.network.decoding")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
