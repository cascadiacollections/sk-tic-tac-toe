//
//  GamePersistence.swift
//  tictactoe Shared
//
//  Created by Kevin T. Coughlin on 5/1/26.
//

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

// MARK: - LifetimeStats

/// Cumulative wins / draws counted across every game ever played on the
/// device. Kept separate from the per-scene session scores.
public struct LifetimeStats: Codable, Sendable, Equatable {
    public var xWins: Int
    public var oWins: Int
    public var draws: Int

    public init(xWins: Int = 0, oWins: Int = 0, draws: Int = 0) {
        self.xWins = xWins
        self.oWins = oWins
        self.draws = draws
    }

    public var totalGames: Int { xWins + oWins + draws }
}

// MARK: - StatsStore

/// `UserDefaults`-backed persistence for lifetime game stats.
@MainActor
public enum StatsStore {
    public static let storageKey = "com.cascadiacollections.tictactoe.lifetimeStats.v1"

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "StatsStore"
    )

    private static let defaults: UserDefaults = .standard

    /// Loads the stored lifetime stats, or an empty record if none exist.
    public static func load() -> LifetimeStats {
        guard let data = defaults.data(forKey: storageKey) else {
            return .init()
        }
        do {
            return try JSONDecoder().decode(LifetimeStats.self, from: data)
        } catch {
            log.error("Failed to decode lifetime stats: \(error.localizedDescription)")
            return .init()
        }
    }

    public static func save(_ stats: LifetimeStats) {
        do {
            let data = try JSONEncoder().encode(stats)
            defaults.set(data, forKey: storageKey)
        } catch {
            log.error("Failed to encode lifetime stats: \(error.localizedDescription)")
        }
    }

    public static func recordWin(for player: Player) {
        var stats = load()
        if player == .x { stats.xWins += 1 } else { stats.oWins += 1 }
        save(stats)
    }

    public static func recordDraw() {
        var stats = load()
        stats.draws += 1
        save(stats)
    }

    /// Rolls back a previously-recorded outcome (used when a winning/draw move
    /// is undone). Counters never go below zero.
    public static func rollBack(_ state: GameState) {
        var stats = load()
        switch state {
        case .won(.x): stats.xWins = max(0, stats.xWins - 1)
        case .won(.o): stats.oWins = max(0, stats.oWins - 1)
        case .draw:    stats.draws = max(0, stats.draws - 1)
        case .ongoing: return
        }
        save(stats)
    }

    public static func reset() {
        defaults.removeObject(forKey: storageKey)
        log.info("Lifetime stats cleared")
    }
}

// MARK: - GamePersistence

/// Lightweight `UserDefaults`-backed persistence for an in-progress game.
///
/// The app saves after every move and clears on game over / return-to-menu.
/// On relaunch, a non-nil `load()` signals the view controller to skip the
/// main menu and jump straight back into the ongoing game.
@MainActor
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
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }
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
