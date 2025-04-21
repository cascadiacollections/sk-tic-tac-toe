//
//  TicTacToeTests.swift
//  TicTacToeTests
//
//  Created by Kevin T. Coughlin on 10/29/24.
//

import Testing
@testable import tictactoe // Make sure this matches your app's target name

@Suite
final class GameLogicTests {

    // Helper to make a sequence of moves without checking individual outcomes (for setting up state)
    private func makeMoves(_ logic: GameLogic, moves: [(Int, Int)]) {
        moves.forEach { (row, col) in
            // We typically expect moves to succeed in these sequences for setting up state,
            // but we ignore the outcome here to just apply the board state.
            // If you needed to test the outcomes *within* the sequence,
            // you would add #expect calls here.
            _ = logic.makeMove(row: row, col: col)
        }
    }

    // Helper to check win (Optional, could just use #expect directly)
    private func expectWin(for player: GameLogic.Player, logic: GameLogic, message: Comment) {
        #expect(logic.gameState == .won(player), message)
    }

    // Helper to check draw (Optional, could just use #expect directly)
    private func expectDraw(logic: GameLogic, message: Comment) {
        #expect(logic.gameState == .draw, message)
    }

    // MARK: - Initialization Tests

    @Test("Initial Game State Test (3x3)")
    func testInitialGameState3x3() {
        // Use guard let to unwrap the failable initializer.
        // Explicitly fail the test if it returns nil.
        guard let logic = GameLogic(boardSize: 3) else {
            #expect(false, "GameLogic should initialize successfully with size 3")
            return // Stop the test if init fails
        }

        #expect(logic.gameState == .ongoing, "Expected game to be in an ongoing state at start")
        #expect(logic.currentPlayer == .x, "Expected the first player to be X")
        for r in 0..<logic.boardSize {
            for c in 0..<logic.boardSize {
                #expect(logic.getPlayerAt(row: r, col: c) == nil, "Expected cell (\(r), \(c)) to be empty initially")
            }
        }
         #expect(logic.getWinningPatternCoordinates() == nil, "Expected no winning pattern initially")
    }

    @Test("Initial Game State Test (4x4)")
    func testInitialGameState4x4() {
        guard let logic = GameLogic(boardSize: 4) else {
            #expect(false, "GameLogic should initialize successfully with size 4")
            return
        }

        #expect(logic.gameState == .ongoing, "Expected game to be in an ongoing state at start on 4x4")
        #expect(logic.currentPlayer == .x, "Expected the first player to be X on 4x4")
    }

    @Test("Initialization Fails for Invalid Size Zero")
    func testInitInvalidSizeZeroFails() {
        let logic = GameLogic(boardSize: 0) // Expecting nil
        #expect(logic == nil, "GameLogic should not initialize with size 0")
    }

    @Test("Initialization Fails for Invalid Negative Size")
    func testInitInvalidNegativeSizeFails() {
        let logic = GameLogic(boardSize: -1) // Expecting nil
        #expect(logic == nil, "GameLogic should not initialize with a negative size")
    }

    // MARK: - Move & Turn Tests

    @Test("Turn Switching Test")
    func testTurnSwitching() {
        guard let logic = GameLogic(boardSize: 3) else {
            #expect(false, "GameLogic should initialize successfully")
            return
        }

        let move1Outcome = logic.makeMove(row: 0, col: 0) // X moves
        #expect(move1Outcome == .success, "First move should be successful")
        #expect(logic.currentPlayer == .o, "Expected turn to switch to O after X's move")

        let move2Outcome = logic.makeMove(row: 1, col: 1) // O moves
         #expect(move2Outcome == .success, "Second move should be successful")
        #expect(logic.currentPlayer == .x, "Expected turn to switch back to X after O's move")
    }

    @Test("Invalid Move on Taken Position")
    func testInvalidMoveOnTakenPosition() {
        guard let logic = GameLogic(boardSize: 3) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }

        let firstMoveOutcome = logic.makeMove(row: 0, col: 0)
        #expect(firstMoveOutcome == .success, "First move should be successful")

        // Attempt the same move again
        let invalidMoveOutcome = logic.makeMove(row: 0, col: 0)
        // Use the specific failure enum case from GameLogic.MoveOutcome
        #expect(invalidMoveOutcome == .failure_positionTaken, "Expected move on taken position to return .failure_positionTaken")
        #expect(logic.getPlayerAt(row: 0, col: 0) == .x, "The player at (0,0) should still be X") // Verify state didn't change
    }

     @Test("Invalid Move Out of Bounds")
     func testInvalidMoveOutOfBounds() {
         guard let logic = GameLogic(boardSize: 3) else {
              #expect(false, "GameLogic should initialize successfully")
             return
         }

         let outcomeNegativeRow = logic.makeMove(row: -1, col: 0)
         #expect(outcomeNegativeRow == .failure_invalidCoordinates, "Expected out of bounds move (negative row) to fail")

         let outcomeTooLargeCol = logic.makeMove(row: 0, col: logic.boardSize)
          #expect(outcomeTooLargeCol == .failure_invalidCoordinates, "Expected out of bounds move (col too large) to fail")

         #expect(logic.gameState == .ongoing, "Game state should remain ongoing after invalid moves")
         #expect(logic.currentPlayer == .x, "Current player should not change after invalid moves")
     }


    @Test("No Move After Game Ends")
    func testNoMoveAfterGameEnds() {
        guard let logic = GameLogic(boardSize: 3) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }

        // Setup a win for X
        makeMoves(logic, moves: [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)])
        #expect(logic.gameState == .won(.x), "Game should be won by X after winning moves")

        // Attempt a move after the game is over
        let moveAfterWinOutcome = logic.makeMove(row: 2, col: 2)

        // Use the specific failure enum case
        #expect(moveAfterWinOutcome == .failure_gameAlreadyOver, "Expected move after game win to return .failure_gameAlreadyOver")
         #expect(logic.getPlayerAt(row: 2, col: 2) == nil, "Cell should remain empty after failed move on game over")
    }


    // MARK: - Win Condition Test Arguments (Moved outside @Test and made static)

    // Make these static properties so they can be referenced by @Test
    private static let xWinArguments: [(moves: [(Int, Int)], expectedState: GameLogic.GameState, message: Comment)] = [
        // Row Wins
        (moves: [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)], expectedState: .won(.x), message: "X wins Row 0"),
        (moves: [(1, 0), (0, 0), (1, 1), (0, 1), (1, 2)], expectedState: .won(.x), message: "X wins Row 1"),
        (moves: [(2, 0), (0, 0), (2, 1), (0, 1), (2, 2)], expectedState: .won(.x), message: "X wins Row 2"),

        // Column Wins
        (moves: [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0)], expectedState: .won(.x), message: "X wins Column 0"),
        (moves: [(0, 1), (0, 0), (1, 1), (1, 0), (2, 1)], expectedState: .won(.x), message: "X wins Column 1"),
        (moves: [(0, 2), (0, 0), (1, 2), (1, 0), (2, 2)], expectedState: .won(.x), message: "X wins Column 2"),

        // Diagonal Wins
        (moves: [(0, 0), (0, 1), (1, 1), (0, 2), (2, 2)], expectedState: .won(.x), message: "X wins Diagonal \\"),
        (moves: [(0, 2), (0, 0), (1, 1), (1, 0), (2, 0)], expectedState: .won(.x), message: "X wins Diagonal /")
    ]

    // Make this a static property so it can be referenced by @Test
    private static let oWinArguments: [(moves: [(Int, Int)], expectedState: GameLogic.GameState, message: Comment)] = [
        // Row Wins (Need dummy X moves to make it O's turn for the winning move)
        (moves: [(1, 0), (0, 0), (1, 1), (0, 1), (2, 2), (0, 2)], expectedState: .won(.o), message: "O wins Row 0"), // Added a dummy X move (2,2)
        (moves: [(0, 0), (1, 0), (0, 1), (1, 1), (2, 2), (1, 2)], expectedState: .won(.o), message: "O wins Row 1"),
        (moves: [(0, 0), (2, 0), (0, 1), (2, 1), (1, 1), (2, 2)], expectedState: .won(.o), message: "O wins Row 2"),

        // Column Wins
        (moves: [(0, 1), (0, 0), (1, 1), (1, 0), (2, 2), (2, 0)], expectedState: .won(.o), message: "O wins Column 0"),
        (moves: [(0, 0), (0, 1), (1, 0), (1, 1), (2, 2), (2, 1)], expectedState: .won(.o), message: "O wins Column 1"),
        (moves: [(0, 0), (0, 2), (1, 0), (1, 2), (1, 1), (2, 2)], expectedState: .won(.o), message: "O wins Column 2"),

        // Diagonal Wins
        (moves: [(0, 1), (0, 0), (0, 2), (1, 1), (1, 0), (2, 2)], expectedState: .won(.o), message: "O wins Diagonal \\"),
        (moves: [(0, 0), (0, 2), (1, 0), (1, 1), (2, 2), (2, 0)], expectedState: .won(.o), message: "O wins Diagonal /")
    ]


    // MARK: - Win Condition Tests

    @Test("Win Condition Test for Player X (Rows, Cols, Diags)", arguments: xWinArguments) // Reference the static variable
    func testWinConditionX(moves: [(Int, Int)], expectedState: GameLogic.GameState, message: Comment) {
        guard let logic = GameLogic(boardSize: 3) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, message)
    }

    @Test("Win Condition Test for Player O (Rows, Cols, Diags)", arguments: oWinArguments) // Reference the static variable
    func testWinConditionO(moves: [(Int, Int)], expectedState: GameLogic.GameState, message: Comment) {
        // Use the fully qualified type name GameLogic.GameState (already done in previous fix)
        guard let logic = GameLogic(boardSize: 3) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == expectedState, message)
    }


    // MARK: - Draw Condition Test

    @Test("Draw Condition Test on 3x3 Board")
    func testDrawConditionOn3x3Board() {
        guard let logic = GameLogic(boardSize: 3) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }
        // This sequence fills the board without a win
        let drawMoves: [(Int, Int)] = [
            (0, 0), (0, 1), // X O
            (0, 2), (1, 1), // X O
            (1, 0), (2, 0), // X O
            (1, 2), (2, 2), // X O
            (2, 1)          // X
        ] // Board: X O X / O X O / O X X -> Correct sequence for draw

        makeMoves(logic, moves: drawMoves)
        #expect(logic.gameState == .draw, "Expected Draw on a 3x3 board filled without a win")
         // Verify the board is full
         let totalSquares = logic.boardSize * logic.boardSize
         var occupiedCount = 0
         for r in 0..<logic.boardSize {
             for c in 0..<logic.boardSize {
                 if logic.getPlayerAt(row: r, col: c) != nil {
                     occupiedCount += 1
                 }
             }
         }
         #expect(occupiedCount == totalSquares, "Expected all cells to be occupied in a draw")
         #expect(logic.getWinningPatternCoordinates() == nil, "Expected no winning pattern in a draw")
    }


    // MARK: - Larger Board Tests

    // Argument for 4x4 draw test (moved outside @Test and made static)
     // Make this a static property
    private static let fourByFourDrawArgument: (moves: [(Int, Int)], expectedState: GameLogic.GameState) = (
        moves: [
             (0,0), (0,1), (0,2), (0,3),
             (1,1), (1,0), (1,3), (1,2),
             (2,2), (2,3), (2,1), (2,0),
             (3,3), (3,2), (3,0), (3,1)
         ], // This is one possible draw sequence
        expectedState: .draw
    )


    @Test("Win Condition on 4x4 Board (Row)")
    func testWinConditionFourByFourRow() {
        guard let logic = GameLogic(boardSize: 4) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }
        let moves: [(Int, Int)] = [
            (0, 0), (1, 0), // X O
            (0, 1), (1, 1), // X O
            (0, 2), (1, 2), // X O
            (0, 3)          // X wins row 0
        ]
        makeMoves(logic, moves: moves)
        #expect(logic.gameState == .won(.x), "Expected X to win on 4x4 row 0")
        // Optional: Verify winning coordinates
        let expectedCoords: [(row: Int, col: Int)] = [(0,0), (0,1), (0,2), (0,3)]
         let winningCoords = logic.getWinningPatternCoordinates()
         #expect(winningCoords != nil, "Winning pattern should not be nil on win")
         #expect(Set(winningCoords!.map { "\($0.row),\($0.col)" }) == Set(expectedCoords.map { "\($0.row),\($0.col)" }), "Winning coordinates should match row 0")
         #expect(winningCoords!.count == logic.boardSize, "Winning coordinates count should match board size")
    }

     @Test("Win Condition on 4x4 Board (Diagonal)")
     func testWinConditionFourByFourDiagonal() {
         guard let logic = GameLogic(boardSize: 4) else {
              #expect(false, "GameLogic should initialize successfully")
             return
         }
         let moves: [(Int, Int)] = [
             (0, 0), (0, 1), // X O
             (1, 1), (0, 2), // X O
             (2, 2), (0, 3), // X O
             (3, 3)          // X wins diag \
         ]
         makeMoves(logic, moves: moves)
         #expect(logic.gameState == .won(.x), "Expected X to win on 4x4 diagonal \\")
          // Optional: Verify winning coordinates
         let expectedCoords: [(row: Int, col: Int)] = [(0,0), (1,1), (2,2), (3,3)]
          let winningCoords = logic.getWinningPatternCoordinates()
          #expect(winningCoords != nil, "Winning pattern should not be nil on win")
          #expect(Set(winningCoords!.map { "\($0.row),\($0.col)" }) == Set(expectedCoords.map { "\($0.row),\($0.col)" }), "Winning coordinates should match diagonal \\")
           #expect(winningCoords!.count == logic.boardSize, "Winning coordinates count should match board size")
     }

    // MARK: - Smallest Board Test

    @Test("Smallest Possible Board - 1x1")
    func testSmallestPossibleBoard() {
        guard let logic = GameLogic(boardSize: 1) else {
             #expect(false, "GameLogic should initialize successfully with size 1")
            return
        }
        // On a 1x1 board, the first move wins immediately
        let outcome = logic.makeMove(row: 0, col: 0)

        #expect(outcome == .success, "Move on 1x1 board should be successful")
        #expect(logic.gameState == .won(.x), "Expected X to win immediately on a 1x1 board")
         let winningCoords = logic.getWinningPatternCoordinates()
         #expect(winningCoords?.count == 1, "Expected 1 winning coordinate on 1x1 win")
         #expect(winningCoords?.first?.row == 0 && winningCoords?.first?.col == 0, "Expected winning coordinate to be (0,0)")
    }

    // MARK: - Reset Test

    @Test("Reset Game Test")
    func testReset() {
        guard let logic = GameLogic(boardSize: 3) else {
             #expect(false, "GameLogic should initialize successfully")
            return
        }

        // Make some moves
        let move1Outcome = logic.makeMove(row: 0, col: 0) // X
        let move2Outcome = logic.makeMove(row: 1, col: 1) // O
        let move3Outcome = logic.makeMove(row: 0, col: 1) // X
         #expect(move1Outcome == .success && move2Outcome == .success && move3Outcome == .success, "Initial moves should be successful")

        #expect(logic.currentPlayer == .o, "Expected player to be O before reset")
        #expect(logic.getPlayerAt(row: 0, col: 0) == .x, "Expected (0,0) to be X before reset")
        #expect(logic.getPlayerAt(row: 1, col: 1) == .o, "Expected (1,1) to be O before reset")
        #expect(logic.getPlayerAt(row: 0, col: 1) == .x, "Expected (0,1) to be X before reset")
         #expect(logic.gameState == .ongoing, "Expected game to be ongoing before reset")

        logic.reset() // Perform reset

        // Verify state is back to initial
        #expect(logic.gameState == .ongoing, "Expected game state to be ongoing after reset")
        #expect(logic.currentPlayer == .x, "Expected current player to be X after reset")
        for r in 0..<logic.boardSize {
            for c in 0..<logic.boardSize {
                #expect(logic.getPlayerAt(row: r, col: c) == nil, "Expected cell (\(r), \(c)) to be empty after reset")
            }
        }
         #expect(logic.getWinningPatternCoordinates() == nil, "Expected no winning pattern after reset")
    }

     // MARK: - Getters Test

    @Test("GetPlayerAt and GetWinningPatternCoordinates Tests")
    func testGetters() {
         guard let logic = GameLogic(boardSize: 3) else {
              #expect(false, "GameLogic should initialize successfully")
             return
         }

         #expect(logic.getPlayerAt(row: 0, col: 0) == nil, "Cell (0,0) should be empty initially")
         // Test invalid coordinates for getPlayerAt
         let outOfBoundsPlayer1 = logic.getPlayerAt(row: -1, col: 0)
         #expect(outOfBoundsPlayer1 == nil, "getPlayerAt for out of bounds (negative row) should return nil")
         let outOfBoundsPlayer2 = logic.getPlayerAt(row: logic.boardSize, col: 0)
         #expect(outOfBoundsPlayer2 == nil, "getPlayerAt for out of bounds (row too large) should return nil")


        _ = logic.makeMove(row: 1, col: 1) // X moves
        #expect(logic.getPlayerAt(row: 1, col: 1) == .x, "Cell (1,1) should be X after move")

        _ = logic.makeMove(row: 0, col: 0) // O moves
        #expect(logic.getPlayerAt(row: 0, col: 0) == .o, "Cell (0,0) should be O after move")

        #expect(logic.getWinningPatternCoordinates() == nil, "Winning pattern should be nil when game ongoing")

         // Setup a win for X
        _ = logic.makeMove(row: 1, col: 2) // X
        _ = logic.makeMove(row: 2, col: 0) // O
        let winMoveOutcome = logic.makeMove(row: 1, col: 0) // X wins row 1
        #expect(winMoveOutcome == .success, "Winning move should be successful")
        #expect(logic.gameState == .won(.x), "Game should be won for winning pattern test")

         let winningCoords = logic.getWinningPatternCoordinates()
         #expect(winningCoords != nil, "Winning pattern should not be nil when game is won")
         // The winning coordinates are sorted by their linear index (row*size + col) in GameLogic
         let expectedCoords: [(row: Int, col: Int)] = [(1,0), (1,1), (1,2)]
         #expect(Set(winningCoords!.map { "\($0.row),\($0.col)" }) == Set(expectedCoords.map { "\($0.row),\($0.col)" }), "Winning coordinates should match row 1")
         #expect(winningCoords!.count == logic.boardSize, "Winning coordinates count should match board size")

         // Setup a win for O (different pattern)
         guard let logicO = GameLogic(boardSize: 3) else {
              #expect(false, "GameLogic should initialize successfully for O win test")
             return
         }
         _ = logicO.makeMove(row: 0, col: 0) // X
         _ = logicO.makeMove(row: 0, col: 2) // O
         _ = logicO.makeMove(row: 1, col: 0) // X
         _ = logicO.makeMove(row: 1, col: 1) // O
         _ = logicO.makeMove(row: 2, col: 2) // X
         let oWinOutcome = logicO.makeMove(row: 2, col: 0) // O wins diag /
         #expect(oWinOutcome == .success, "O winning move should be successful")
         #expect(logicO.gameState == .won(.o), "Game should be won by O for winning pattern test")
         let oWinningCoords = logicO.getWinningPatternCoordinates()
         // Expected coords for anti-diagonal (sorted by linear index)
         let expectedOCoords: [(row: Int, col: Int)] = [(0,2), (1,1), (2,0)]
         #expect(oWinningCoords != nil, "O's Winning pattern should not be nil")
          #expect(Set(oWinningCoords!.map { "\($0.row),\($0.col)" }) == Set(expectedOCoords.map { "\($0.row),\($0.col)" }), "O's winning coordinates should match diagonal /")
          #expect(oWinningCoords!.count == logicO.boardSize, "O's Winning coordinates count should match board size")
    }
}
