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
import "hardhat/console.sol";

contract Craps is VRFConsumerBaseV2 {
    /* Type declarations */
    enum GameState {
        OPEN,
        ONE_PLAYER,
        TWO_PLAYERS,
        SELECTING_SHOOTER,
        AWAITING_COME_OUT
    }

    /* Errors */
    error Craps__PlayerAlreadyJoined(address existingPlayer);
    error Craps__GameFull();
    error Craps__IncorrectAnte(uint256 correctAnte);
    error Craps__IncorrectGameState(GameState gameState);

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2; // two dice
    uint256[] public s_randomWords;

    // Craps Variables
    GameState private s_gameState;
    uint256 private immutable i_ante;
    address private s_player1; 
    address private s_player2;
    address private s_shooter;

    /* Events */
    event PlayerJoined(address indexed player);
    event ShooterRequested(uint256 indexed requestId);
    event ShooterSelected(address indexed shooter);

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
        s_gameState = GameState.OPEN;
    }

    /// @dev This is the function that Chainlink VRF node
    /// calls to roll the dice.
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        if (s_gameState == GameState.SELECTING_SHOOTER) {
            uint256 selection = randomWords[0] % 2;
            if (selection == 0) {
                s_shooter = s_player1;
            } else {
                s_shooter = s_player2;
            }
            s_gameState = GameState.AWAITING_COME_OUT;
            emit ShooterSelected(s_shooter);
        }
        // 2. shooting dice
    }

    /* Getters */

    /// @notice Returns the game's current state
    /// @dev the state options are defined at the top of the 
    /// contract under, "Type declarations"
    function getGameState() public view returns (GameState) {
        return s_gameState;
    }

    /// @notice Returns ether ante set on contract deploy
    function getAnte() public view returns (uint256) {
        return i_ante;
    }

    /// @notice Returns s_player1's address
    function getPlayer1() public view returns (address) {
        return s_player1;
    }

    /// @notice Returns s_player2's address
    function getPlayer2() public view returns (address) {
        return s_player2;
    }

    /// @notice Returns s_shooter's address
    function getShooter() public view returns (address) {
        return s_shooter;
    }

    /* Game functions */

    /// @notice Allows up to two unique players (with the correct 
    /// ante) to join.
    /// @dev emits PlayerJoined on success and reverts when the
    /// game is full, the player is trying to join again, or a 
    /// player provides an incorrect ante
    function joinGame() public payable {
        if (msg.sender == s_player1 || msg.sender == s_player2) {
            revert Craps__PlayerAlreadyJoined(msg.sender);
        } else if (s_gameState == GameState.TWO_PLAYERS) {
            revert Craps__GameFull();
        } else if (msg.value != i_ante) {
            revert Craps__IncorrectAnte(i_ante);
        } else if (s_player1 == address(0)) {
            s_player1 = msg.sender;
            s_gameState = GameState.ONE_PLAYER;
            emit PlayerJoined(msg.sender);
        } else if (s_player2 == address(0)) {
            s_player2 = msg.sender;
            s_gameState = GameState.TWO_PLAYERS;
            emit PlayerJoined(msg.sender);
        }
    }

    function selectShooter() public {
        if (s_gameState != GameState.TWO_PLAYERS) {
            revert Craps__IncorrectGameState(s_gameState);
        }
        // todo: chainlink vrf logic
        // todo: test this logic
        s_gameState = GameState.SELECTING_SHOOTER;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // keyhash 
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS, 
            i_callbackGasLimit, 
            1
        );
        emit ShooterRequested(requestId);

    }
}