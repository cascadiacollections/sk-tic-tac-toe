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

    @Test("Initial Game State Test")
    func testInitialGameState() {
        let logic = GameLogic(boardSize: 3)
        #expect(logic.gameState == .ongoing, "Expected game to be in an ongoing state at start")
        #expect(logic.currentPlayer == .x, "Expected the first player to be X")
    }

    @Test("Move Updates State", arguments: [(0, 0), (1, 1)])
    func testMakeMoveUpdatesState(row: Int, col: Int) {
        let logic = GameLogic(boardSize: 3)
        let moveResult = logic.makeMove(row: row, col: col)
        #expect(moveResult == true, "Expected move to be successful")
        #expect(logic.currentPlayer == .o, "Expected current player to switch to O after X's move")
    }

    @Test("Win Condition Test", arguments: [
        [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)],
        [(2, 0), (1, 1), (2, 1), (1, 2), (2, 2)]
    ])
    func testWinCondition(moves: [(Int, Int)]) {
        let logic = GameLogic(boardSize: 3)
        
        moves.enumerated().forEach { index, move in
            let (row, col) = move
            _ = logic.makeMove(row: row, col: col)
            if index == moves.count - 1 {  // Last move for the win
                #expect(logic.gameState == .won(.x), "Expected X to win on final move")
            }
        }
    }

    @Test("Draw Condition Test")
    func testDrawCondition() {
        let logic = GameLogic(boardSize: 3)
        
        let moves = [(0, 0), (0, 1), (0, 2),
                     (1, 1), (1, 0), (2, 0),
                     (1, 2), (2, 2), (2, 1)]
        
        moves.forEach { (row, col) in
            _ = logic.makeMove(row: row, col: col)
        }
        
        #expect(logic.gameState == .draw, "Expected game to end in a draw")
    }
}
