// starting w/just two players
// Create a game (set the ante)
// Second player should be able to join the game (pay the ante)
// Randomly select the shooter
// Shooter rolls the 'come out'
// shooter wins on: 7 || 11
// shooter loses on: 2 || 3 || 12
// other? point is defined and the shooter continues to roll until point || 7
// shooter wins on point
// shooter loses on 7 out

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Craps {
    uint256 private immutable i_ante;
    // just starting simple w/two players
    address player1; 
    address player2;
    enum GameState {
        AwaitingPlayers,
        AwaitingPlayer,
        AwaitingShooterSelection,
        AwaitingComeOut,
        AwaitingPointResult,
        GameOver,
        PaidOut
    }
    address shooter;

    constructor(uint256 ante) {
        i_ante = ante;
    }

    function getAnte() public view returns (uint256) {
        return i_ante;
    }

    function joinGame() public payable {
        // check the ante is correct
        // if player1 empty, initialize player1
        // if player1 init and player 2 empty, initialize player2
        // if they're both initilized revert 
    }

    function chooseShooter() public returns (address) {
        // must be awaiting shooter selection
    }
}