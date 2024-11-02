//
//  TicTacToeTests.swift
//  TicTacToeTests
//
//  Created by Kevin T. Coughlin on 10/29/24.
//

import Testing
@testable import tictactoe

@Suite
final class GameLogicTests {
    
    private func makeMoves(_ logic: GameLogic, moves: [(Int, Int)]) {
        moves.forEach { (row, col) in
            _ = logic.makeMove(row: row, col: col)
        }
    }
    
    private func expectWin(for player: GameLogic.Player, logic: GameLogic, message: Comment) {
        #expect(logic.gameState == .won(player), message)
    }
    
    private func expectDraw(logic: GameLogic, message: Comment) {
        #expect(logic.gameState == .draw, message)
    }

    @Test("Initial Game State Test")
    func testInitialGameState() {
        let logic = GameLogic(boardSize: 3)
        #expect(logic.gameState == .ongoing, "Expected game to be in an ongoing state at start")
        #expect(logic.currentPlayer == .x, "Expected the first player to be X")
    }

    @Test("Turn Switching Test")
    func testTurnSwitching() {
        let logic = GameLogic(boardSize: 3)
        
        _ = logic.makeMove(row: 0, col: 0)
        #expect(logic.currentPlayer == .o, "Expected turn to switch to O after X's move")
        
        _ = logic.makeMove(row: 1, col: 1)
        #expect(logic.currentPlayer == .x, "Expected turn to switch back to X after O's move")
    }

    @Test("Invalid Move on Taken Position")
    func testInvalidMoveOnTakenPosition() {
        let logic = GameLogic(boardSize: 3)
        
        _ = logic.makeMove(row: 0, col: 0)
        let invalidMove = logic.makeMove(row: 0, col: 0)
        #expect(invalidMove == false, "Expected move on taken position to be invalid")
    }

    @Test("Win Condition Test for Player X", arguments: [
        ([(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)], GameLogic.GameState.won(.x)),
        ([(2, 0), (1, 1), (2, 1), (1, 2), (2, 2)], GameLogic.GameState.won(.x))
    ])
    func testWinCondition(moves: [(Int, Int)], expectedState: GameLogic.GameState) {
        let logic = GameLogic(boardSize: 3)
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, "Expected \(expectedState) for the given move sequence")
    }

    @Test("Draw Condition Test on 3x3 Board", arguments: [
        ([(0, 0), (0, 1), (0, 2), (1, 1), (1, 0), (2, 0), (1, 2), (2, 2), (2, 1)], GameLogic.GameState.draw)
    ])
    func testDrawConditionOn3x3Board(moves: [(Int, Int)], expectedState: GameLogic.GameState) {
        let logic = GameLogic(boardSize: 3)
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, "Expected \(expectedState) on a 3x3 board filled without a win")
    }

    @Test("No Move After Game Ends", arguments: [
        ([(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)], false)
    ])
    func testNoMoveAfterGameEnds(moves: [(Int, Int)], moveAfterEndExpected: Bool) {
        let logic = GameLogic(boardSize: 3)
        makeMoves(logic, moves: moves)
        
        let moveAfterWin = logic.makeMove(row: 2, col: 2)
        #expect(moveAfterWin == moveAfterEndExpected, "Expected no moves allowed after game ends")
    }

    @Test("Win Condition on 4x4 Board", arguments: [
        ([(0, 0), (1, 1), (0, 1), (1, 2), (0, 2), (1, 0), (0, 3)], GameLogic.GameState.won(.x))
    ])
    func testWinConditionOnFourByFourBoard(moves: [(Int, Int)], expectedState: GameLogic.GameState) {
        let logic = GameLogic(boardSize: 4)
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, "Expected \(expectedState) with a winning line on a 4x4 board")
    }

    @Test("Draw Condition on 4x4 Board", arguments: [
        ([
            (0, 0), (0, 1), (0, 2), (0, 3),
            (1, 1), (1, 0), (1, 3), (1, 2),
            (2, 2), (2, 3), (2, 1), (2, 0),
            (3, 3), (3, 2), (3, 0), (3, 1)
        ], GameLogic.GameState.draw)
    ])
    func testDrawConditionOnFourByFourBoard(moves: [(Int, Int)], expectedState: GameLogic.GameState) {
        let logic = GameLogic(boardSize: 4)
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, "Expected \(expectedState) on a 4x4 board filled without a win")
    }

    @Test("Smallest Possible Board - 1x1", arguments: [
        ([(0, 0)], GameLogic.GameState.won(.x))
    ])
    func testSmallestPossibleBoard(moves: [(Int, Int)], expectedState: GameLogic.GameState) {
        let logic = GameLogic(boardSize: 1)
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, "Expected \(expectedState) immediately on a 1x1 board")
    }
}
