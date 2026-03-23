import Foundation
import Supabase
import Auth

/// Central manager for all Supabase interactions.
/// Provides access to Auth, Database, Storage, and Realtime.
@MainActor
final class SupabaseManager: ObservableObject, Sendable {

    // MARK: - Singleton

    static let shared = SupabaseManager()

    // MARK: - Supabase Client

    let client: SupabaseClient

    // MARK: - Published State

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: Auth.User?

    // MARK: - Initialization

    private init() {
        // Initialize Supabase client with configuration
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainAuthStorage(),
                    flowType: .pkce
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    headers: ["x-app-version": Config.appVersion]
                )
            )
        )

        // Setup auth state listener
        setupAuthStateListener()
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .initialSession, .signedIn:
                        self.currentUser = session?.user
                        self.isAuthenticated = session != nil
                    case .signedOut:
                        self.currentUser = nil
                        self.isAuthenticated = false
                    case .userUpdated:
                        self.currentUser = session?.user
                    case .tokenRefreshed, .mfaChallengeVerified, .userDeleted:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Auth Methods

    /// Sign in with Apple credential
    func signInWithApple(idToken: String, nonce: String) async throws -> Auth.User {
        let response = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return response.user
    }

    /// Send magic link to email
    func sendMagicLink(to email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "rumo://auth/callback")
        )
    }

    /// Verify magic link callback
    func verifyMagicLink(url: URL) async throws -> Auth.User {
        let session = try await client.auth.session(from: url)
        return session.user
    }

    /// Sign out current user
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Delete current user account
    func deleteAccount() async throws {
        // Call edge function to delete user data
        try await client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(
                body: ["confirm": true]
            )
        )
        try await client.auth.signOut()
    }

    /// Refresh session if needed
    func refreshSessionIfNeeded() async throws {
        _ = try await client.auth.session
    }
}

// MARK: - Database Operations

extension SupabaseManager {

    /// Generic fetch from a table
    func fetch<T: Decodable>(
        from table: String,
        filter: ((PostgrestFilterBuilder) -> PostgrestFilterBuilder)? = nil
    ) async throws -> [T] {
        var query = client.from(table).select()

        if let filter = filter {
            query = filter(query)
        }

        return try await query.execute().value
    }

    /// Generic insert to a table
    func insert<T: Encodable>(
        _ item: T,
        to table: String
    ) async throws {
        try await client.from(table)
            .insert(item)
            .execute()
    }

    /// Generic update in a table
    func update<T: Encodable>(
        _ item: T,
        in table: String,
        matching id: UUID
    ) async throws {
        try await client.from(table)
            .update(item)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Generic upsert to a table
    func upsert<T: Encodable>(
        _ item: T,
        to table: String
    ) async throws {
        try await client.from(table)
            .upsert(item)
            .execute()
    }

    /// Soft delete from a table
    func softDelete(
        from table: String,
        id: UUID
    ) async throws {
        try await client.from(table)
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Storage Operations

extension SupabaseManager {

    /// Upload file to storage
    func uploadFile(
        bucket: String,
        path: String,
        data: Data,
        contentType: String
    ) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: contentType)
            )

        return try client.storage.from(bucket).getPublicURL(path: path).absoluteString
    }

    /// Download file from storage
    func downloadFile(
        bucket: String,
        path: String
    ) async throws -> Data {
        try await client.storage
            .from(bucket)
            .download(path: path)
    }

    /// Delete file from storage
    func deleteFile(
        bucket: String,
        path: String
    ) async throws {
        try await client.storage
            .from(bucket)
            .remove(paths: [path])
    }
}

// MARK: - Realtime

extension SupabaseManager {

    /// Subscribe to changes on a table
    func subscribeToChanges(
        table: String,
        schema: String = "public",
        filter: String? = nil,
        callback: @escaping (RealtimeMessage) -> Void
    ) -> RealtimeChannelV2 {
        let channel = client.realtimeV2.channel("public:\(table)")

        Task {
            await channel.onPostgresChange(
                AnyAction.self,
                schema: schema,
                table: table,
                filter: filter
            ) { change in
                let message = RealtimeMessage(
                    action: String(describing: type(of: change)),
                    table: table,
                    record: nil,
                    oldRecord: nil
                )
                callback(message)
            }

            await channel.subscribe()
        }

        return channel
    }

    /// Unsubscribe from a channel
    func unsubscribe(_ channel: RealtimeChannelV2) async {
        await channel.unsubscribe()
    }
}

// MARK: - Edge Functions

extension SupabaseManager {

    /// Call weekly review edge function
    func generateWeeklyReview(payload: WeeklyReviewPayload) async throws -> WeeklyReviewResponse {
        return try await client.functions.invoke(
            "weekly-review",
            options: FunctionInvokeOptions(body: payload)
        )
    }

    /// Generate embedding for journal entry
    func generateEmbedding(text: String) async throws -> [Float] {
        struct EmbeddingRequest: Encodable {
            let text: String
        }

        struct EmbeddingResponse: Decodable {
            let embedding: [Float]
        }

        let response: EmbeddingResponse = try await client.functions.invoke(
            "generate-embedding",
            options: FunctionInvokeOptions(body: EmbeddingRequest(text: text))
        )

        return response.embedding
    }
}

// MARK: - Supporting Types

struct WeeklyReviewPayload: Encodable {
    let weekStart: String
    let habitCompletion: [String: Float]
    let taskStats: TaskWeekStats
    let moodByDay: [Int]
    let sentimentByDay: [Float]
    let topicsFrequency: [String: Int]
    let journalDaysCount: Int
    let streaks: [String: Int]
}

struct TaskWeekStats: Codable {
    let created: Int
    let completed: Int
    let overdue: Int
}

struct WeeklyReviewResponse: Decodable {
    let headline: String
    let highlights: [String]
    let patterns: [String]
    let suggestions: [String]
    let prompt: String
}

// MARK: - Realtime Message

struct RealtimeMessage {
    let action: String
    let table: String
    let record: [String: Any]?
    let oldRecord: [String: Any]?
}

// MARK: - Keychain Auth Storage

/// Custom auth storage using Keychain for secure token persistence
final class KeychainAuthStorage: AuthLocalStorage, @unchecked Sendable {
    private let keychain = KeychainManager.shared
    private let key = "supabase_session"

    func store(key: String, value: Data) throws {
        try keychain.set(value, for: self.key + "_" + key)
    }

    func retrieve(key: String) throws -> Data? {
        try keychain.getData(for: self.key + "_" + key)
    }

    func remove(key: String) throws {
        try keychain.delete(for: self.key + "_" + key)
    }
}
