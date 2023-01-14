// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Game is ERC20 {
    // update life price, gift amount, winning prize, default cooldown, free lives,

    // modifier to check owner
    modifier onlyManager() {
        require(msg.sender == manager, "Unauthorized - only Manager allowed");
        _;
    }

    // will be emitted when new player joins the game
    event NewPlayerAdded(
        address indexed playerAddress,
        uint256 indexed timeOfJoining
    );

    // will be emitted when game ends
    event GameEnded(address indexed winnerAddress, uint256 indexed winnerScore);

    // will be emitted afte buying lives
    event LivesReceived(
        uint256 indexed LivesReceived,
        uint256 indexed RemainingBalance
    );

    // when setting new values
    event GameUpdated(
        uint256 lifePrice,
        uint256 freeLives,
        uint256 winningPrize,
        uint256 defaultCoolDown
    );

    // manager
    address payable manager;

    // game state
    bool public gameOngoing;

    // waiting time after playing once
    uint256 defaultCoolDown = 30 seconds;

    // all time high score and winner address
    uint256 public lastHighScore = 0;
    address public lastWinner = address(0);

    // highscore and possible winner of current game
    uint256 public currHighScore = 0;
    address payable public currentlyWinning = payable(address(0));

    // free lives
    uint256 public freeLives = 3;

    // token gifted once
    mapping(address => bool) tokenReceived;

    // winner price
    uint256 public winningPrize = 50;

    // price to buy life
    uint256 public lifePrice = 5;

    // setting initial values
    constructor() ERC20("GameToken", "GTK") {
        manager = payable(msg.sender);
        _mint(manager, 10000);
    }

    // player struct
    struct Player {
        address playerAddress;
        uint256 tokenBalance;
        uint256 score;
        uint256 gamesPlayed;
        bool isPartOf;
        uint256 lastPlayed;
    }

    // to hold all the players who plays the game
    Player[] allPlayers;

    // to get player from it's address
    mapping(address => Player) getPlayer;

    // starting game
    function startGame() public onlyManager {
        gameOngoing = true;
    }

    // setting life price, gift amount, winning prize, default cooldown, free lives
    function updateGame(
        uint256 _lifePrice,
        uint256 _freeLives,
        uint256 _winningPrize,
        uint256 _defaultCoolDown
    ) public onlyManager {
        require(!gameOngoing, "Game should not be ongoing");

        lifePrice = _lifePrice;
        freeLives = _freeLives;
        winningPrize = _winningPrize;
        defaultCoolDown = _defaultCoolDown;

        emit GameUpdated(lifePrice, freeLives, winningPrize, defaultCoolDown);
    }

    // enter into the game
    function enter() public {
        // manager can not take part
        require(msg.sender != manager, "Manager should not enter");

        // game must be ongoing
        require(gameOngoing, "Game must be ongoing");

        // not already participated
        require(getPlayer[msg.sender].isPartOf != true, "Already Participated");

        // giving tokens
        _transfer(manager, msg.sender, freeLives);

        // adding player
        getPlayer[msg.sender] = Player(
            msg.sender,
            freeLives, // not decrementing the token
            0,
            0,
            true,
            block.timestamp - defaultCoolDown
        );

        // pushing to all players
        allPlayers.push(
            Player(
                msg.sender,
                freeLives, // not decrementing the token
                0,
                0,
                true,
                block.timestamp - defaultCoolDown
            )
        );

        // emitting event
        emit NewPlayerAdded(msg.sender, block.timestamp);
    }

    // playing
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

        // has token balance
        require(
            getPlayer[msg.sender].tokenBalance > 0,
            "No tokens available - Buy Some"
        );

        // adding score
        getPlayer[msg.sender].score += 5;

        // updating lastPlayed
        getPlayer[msg.sender].lastPlayed = block.timestamp;

        // 1 token used
        _transfer(msg.sender, manager, 1);
        getPlayer[msg.sender].tokenBalance -= 1;

        // setting highscore and winner
        if (getPlayer[msg.sender].score > currHighScore) {
            currHighScore = getPlayer[msg.sender].score;
            currentlyWinning = payable(msg.sender);
        }
    }

    // to buy lives
    function buyLives(uint256 _numberOfLives) public payable {
        // can buy max 2
        require(_numberOfLives <= 2, "You can not buy more than 2 lives");

        // check balance
        require(msg.value >= lifePrice * _numberOfLives, "Not enough funds");

        // transfer funds and tokens
        (bool success, ) = manager.call{value: lifePrice * _numberOfLives}("");
        require(success, "Fund transfer error - try again in some time");

        _transfer(manager, msg.sender, _numberOfLives);

        getPlayer[msg.sender].tokenBalance += _numberOfLives;

        emit LivesReceived(_numberOfLives, getPlayer[msg.sender].tokenBalance);
    }

    // ending game
    function end() public payable onlyManager {
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

        // gifting shit - msg.value should match 4 ether
        (bool success, ) = currentlyWinning.call{value: winningPrize}("");
        require(success, "Fund Transfer Error");

        // resetting current highscore and winner
        currHighScore = 0;
        currentlyWinning = payable(address(0));
    }

    // get your score
    function getMyScore() public view returns (uint256) {
        return getPlayer[msg.sender].score;
    }
}
