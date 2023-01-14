// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Game {
    modifier onlyManager() {
        require(msg.sender == manager, "Unauthorized - only Manager allowed");
        _;
    }

    event NewPlayerAdded(
        address indexed playerAddress,
        uint256 indexed timeOfJoining
    );

    event GameEnded(address indexed winnerAddress, uint256 indexed winnerScore);

    address payable manager;

    bool public gameOngoing;

    uint256 defaultCoolDown = 30 seconds;

    uint256 public lastHighScore = 0;
    address public lastWinner = address(0);

    uint256 public currHighScore = 0;
    address public currentlyWinning = address(0);

    // uint public freeLives = 3;

    // uint public lifePrice = 5;

    constructor() {
        manager = payable(msg.sender);
    }

    struct Player {
        address playerAddress;
        // uint tokenBalance;
        uint256 score;
        uint256 gamesPlayed;
        bool isPartOf;
        uint256 lastPlayed;
    }

    Player[] allPlayers;
    mapping(address => Player) getPlayer;

    function startGame() public onlyManager {
        gameOngoing = true;
    }

    function enter() public {
        // manager can not take part
        require(msg.sender != manager, "Manager should not enter");

        // game must be ongoing
        require(gameOngoing, "Game must be ongoing");

        // not already participated
        require(getPlayer[msg.sender].isPartOf != true, "Already Participated");

        // has token balance
        // require(getPlayer[msg.sender].tokenBalance > 0, "No tokens available - Buy Some");

        // adding player
        getPlayer[msg.sender] = Player(
            msg.sender,
            0,
            0,
            true,
            block.timestamp - defaultCoolDown
        );

        // pushing to all players
        allPlayers.push(
            Player(msg.sender, 0, 0, true, block.timestamp - defaultCoolDown)
        );

        // emitting event
        emit NewPlayerAdded(msg.sender, block.timestamp);
    }

    function play() public {
        // game must be ongoing
        require(gameOngoing, "Game must be ongoing");

        // not already participated
        require(getPlayer[msg.sender].isPartOf == true, "Participate First");

        // check for cooldown
        require(
            block.timestamp - getPlayer[msg.sender].lastPlayed >=
                defaultCoolDown,
            "Wait for some time to play again"
        );

        // adding score
        getPlayer[msg.sender].score += 5;

        // updating lastPlayed
        getPlayer[msg.sender].lastPlayed = block.timestamp;

        // 1 token used
        // getPlayer[msg.sender].tokenBalance -= 1;

        // setting highscore and winner
        if (currHighScore < getPlayer[msg.sender].score) {
            currHighScore = getPlayer[msg.sender].score;
            currentlyWinning = msg.sender;
        }

        // resetting current highscore and winner
        currHighScore = 0;
        currentlyWinning = address(0);
    }

    // function buyLives(uint _amount) public  {
    //     //
    // }

    function end() public onlyManager {
        // game must be ongoing
        require(gameOngoing, "Game is already ended");

        // ending game
        gameOngoing = false;

        // setting all time highscore
        if (lastHighScore < currHighScore) {
            lastHighScore = currHighScore;
            lastWinner = currentlyWinning;
        }

        // emitting event
        emit GameEnded(currentlyWinning, currHighScore);
    }

    function getMyScore() public view returns (uint256) {
        return getPlayer[msg.sender].score;
    }
}
