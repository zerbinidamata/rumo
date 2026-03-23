import Foundation

/// Convenience protocol combining Identifiable with UUID as ID type.
/// Most Rumo models use this pattern.
protocol UUIDIdentifiable: Identifiable where ID == UUID {
    var id: UUID { get }
}

extension UUIDIdentifiable {
    /// Generates a new unique identifier
    static func newID() -> UUID {
        UUID()
    }
}
