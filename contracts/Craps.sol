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

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/* Errors */

contract Craps is VRFConsumerBaseV2 {
    /* Type declarations */
    enum GameState {
        AwaitingPlayers,
        AwaitingPlayer,
        AwaitingShooterSelection,
        AwaitingComeOut,
        AwaitingPointResult,
        GameOver,
        PaidOut
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2; // two dice

    // Craps Variables
    uint256 i_ante;
    // just starting simple w/two players
    // address player0; 
    // address player1;
    // address shooter;

    /* Events */

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        uint256 ante
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_ante = ante;
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // there are two cases when the randomness is needed
        // 1. choosing the shooter
        // 2. shooting dice
    }

    function getAnte() public view returns (uint256) {
        return i_ante;
    }

    function joinGame() public payable {
        // check the ante is correct
        // if player0 empty, initialize player0
        // if player0 init and player1 empty, initialize player1
        // if they're both initilized revert 
    }

    function chooseShooter() public returns (address) {
        // must be awaiting shooter selection
    }
}