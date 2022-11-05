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
        AWAITING_COME_OUT,
        AWAITING_POINT_RESULT,
        GAME_OVER
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
    address private s_non_shooter;
    address payable private s_winner;
    uint8 private s_die1;
    uint8 private s_die2;
    uint8 private s_dice_sum;
    uint8 private s_point;

    /* Events */
    event PlayerJoined(address indexed player);
    event ShooterRequested(uint256 indexed requestId);
    event ShooterSelected(address indexed shooter);
    event NonShooterSelected(address indexed non_shooter);
    event ComeOutRequested(uint256 indexed requestId);
    event WinnerSelected(address indexed winner);

    modifier onlyShooters {
        require(
            msg.sender == s_shooter,
            "Only shooters."
        );
        _;
    }

    modifier onlyWinner {
        require(
            msg.sender == s_winner,
            "Only winner."
        );
        _;
    }

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

    function calculateDieValue(uint256 randomWord) internal pure returns (uint8) {
        uint256 value = randomWord % 6 + 1;
        return uint8(value);
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
                s_non_shooter = s_player2;
            } else {
                s_shooter = s_player2;
                s_non_shooter = s_player1;
            }
            s_gameState = GameState.AWAITING_COME_OUT;
            emit ShooterSelected(s_shooter);
            emit NonShooterSelected(s_non_shooter);
            return;
        }
        if (s_gameState == GameState.AWAITING_COME_OUT) {
            s_die1 = calculateDieValue(randomWords[0]);
            s_die2 = calculateDieValue(randomWords[1]);
            s_dice_sum = getDiceSum();
            if (s_dice_sum == 7 || s_dice_sum == 11) {
                // shooter wins
                // todo: refactor these, code reused 3 times
                s_winner = payable(s_shooter);
                s_gameState = GameState.GAME_OVER;
                emit WinnerSelected(s_winner);
            } else if (s_dice_sum == 2 || s_dice_sum == 3 || s_dice_sum == 12) {
                // shooter loses
                s_winner = payable(s_non_shooter);
                s_gameState = GameState.GAME_OVER;
                emit WinnerSelected(s_winner);
            } else {
                // point defined, roll again
                s_point = s_dice_sum;
                s_gameState = GameState.AWAITING_POINT_RESULT;
            }
        }
        if (s_gameState == GameState.AWAITING_POINT_RESULT) {
            s_die1 = calculateDieValue(randomWords[0]);
            s_die2 = calculateDieValue(randomWords[1]);
            s_dice_sum = getDiceSum();
            if (s_dice_sum == s_point) {
                s_winner = payable(s_shooter);
                s_gameState = GameState.GAME_OVER;
                emit WinnerSelected(s_winner);
            }
        }
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

    /// @notice Returns s_non_shooter's address
    function getNonShooter() public view returns (address) {
        return s_non_shooter;
    }

    /// @notice Returns die1
    function getDie1() public view returns (uint8) {
        return s_die1;
    }

    /// @notice Returns die2
    function getDie2() public view returns (uint8) {
        return s_die2;
    }

    /// @notice Returns die2
    function getDiceSum() public view returns (uint8) {
        uint8 sum = s_die1 + s_die2;
        return sum;
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

    /// @notice Allows anyone to randomly select the shooter
    /// @dev Makes a request to the ChainLink VRF Coordinator.
    /// When that request is filled, the shooter will be selected.
    function selectShooter() public {
        if (s_gameState != GameState.TWO_PLAYERS) {
            revert Craps__IncorrectGameState(s_gameState);
        }
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

    // TODO: refactor into a single roll function
    
    /// @notice Allows the shooter to roll the comeout
    /// @dev Makes a request to the ChainLink VRF Coordinator.
    /// When that request is filled, the roll will be made.
    function rollTheComeOut() public onlyShooters {
        if (s_gameState != GameState.AWAITING_COME_OUT) {
            revert Craps__IncorrectGameState(s_gameState);
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // keyhash 
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS, 
            i_callbackGasLimit, 
            2
        );
        emit ComeOutRequested(requestId);
    }

    /// @notice Allows the shooter to roll after the comeout
    /// @dev Makes a request to the ChainLink VRF Coordinator.
    /// When that request is filled, the roll will be made.
    function roll() public onlyShooters {
        if (s_gameState != GameState.AWAITING_POINT_RESULT) {
            revert Craps__IncorrectGameState(s_gameState);
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // keyhash 
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS, 
            i_callbackGasLimit, 
            2
        );
        emit ComeOutRequested(requestId);
    }

    /// @notice Allows the winner to withdraw the money.
    function withdraw() public onlyWinner {
        uint amount = address(this).balance;
        (bool success, ) = s_winner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}