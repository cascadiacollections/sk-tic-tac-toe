import Foundation
import os

// MARK: - PersistedGame

/// A persisted, in-progress game: the logical snapshot plus the session scores
/// that belong to the scene that owned it.
public struct PersistedGame: Codable, Sendable, Equatable {
    public let snapshot: GameSnapshot
    public let xWins: Int
    public let oWins: Int
    public let draws: Int

    public init(snapshot: GameSnapshot, xWins: Int, oWins: Int, draws: Int) {
        self.snapshot = snapshot
        self.xWins = xWins
        self.oWins = oWins
        self.draws = draws
    }

    /// True when the snapshot represents an in-progress game that should be
    /// restored on relaunch (bypassing the main menu).
    public var isInProgress: Bool {
        snapshot.gameState == .ongoing
    }
}

// MARK: - GamePersistence

/// Lightweight `UserDefaults`-backed persistence for an in-progress game.
///
/// The app saves after every move and clears on game over / return-to-menu.
/// On relaunch, a non-nil `load()` signals the view controller to skip the
/// main menu and jump straight back into the ongoing game.
public enum GamePersistence {

    public static let storageKey = "com.cascadiacollections.tictactoe.persistedGame.v1"

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "GamePersistence"
    )

    private static let defaults: UserDefaults = .standard

    /// Saves the given persisted game. No-op if encoding fails.
    public static func save(_ game: PersistedGame) {
        do {
            let data = try JSONEncoder().encode(game)
            defaults.set(data, forKey: storageKey)
            log.debug("Persisted game saved (\(data.count) bytes)")
        } catch {
            log.error("Failed to encode persisted game: \(error.localizedDescription)")
        }
    }

    /// Loads a previously persisted in-progress game, if any.
    ///
    /// Returns `nil` if nothing was saved, the payload is corrupt, or the
    /// saved game is no longer in progress (won / drawn).
    public static func load() -> PersistedGame? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        do {
            let game = try JSONDecoder().decode(PersistedGame.self, from: data)
            guard game.isInProgress else {
                log.debug("Stored game is not in progress — ignoring")
                clear()
                return nil
            }
            return game
        } catch {
            log.error("Failed to decode persisted game: \(error.localizedDescription)")
            clear()
            return nil
        }
    }

    /// Removes any previously saved game.
    public static func clear() {
        defaults.removeObject(forKey: storageKey)
        log.debug("Persisted game cleared")
    }
}
