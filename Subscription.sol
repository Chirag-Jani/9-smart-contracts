// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Subscription {
    modifier serviceActive() {
        require(active, "Service not active");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    event PurchaseSuccessful(
        address indexed buyer,
        Service indexed serviceDetails
    );

    event UserAdded(
        address indexed ServiceOwner,
        address indexed NewUser,
        Service indexed serviceDetails
    );

    address payable owner;
    bool active;
    uint256 singleUserServicePrice; // 5
    uint256 multipleUserServicePrice; // 7
    uint256 userAdditionPrice; // 3
    uint256 maximumUsers; // 3

    constructor() // uint256 _singleUserServicePrice,
    // uint256 _multipleUserServicePrice,
    // uint256 _userAdditionPrice,
    // uint256 _maxUsers
    {
        owner = payable(msg.sender);
        active = true;
        // singleUserServicePrice = _singleUserServicePrice;
        // multipleUserServicePrice = _multipleUserServicePrice;
        // userAdditionPrice = _userAdditionPrice;
        // maximumUsers = _maxUsers;

        singleUserServicePrice = 5 ether;
        multipleUserServicePrice = 7 ether;
        userAdditionPrice = 4 ether;
        maximumUsers = 3;
    }

    struct Service {
        uint256 price;
        Type serviceType;
        address payable mainUser;
        uint256 lastPurchase;
        uint256 endTime;
    }

    enum Type {
        SingleOwner,
        MultipleOwner
    }
    mapping(address => address[]) users;
    mapping(address => mapping(address => bool)) alreadyUser;
    mapping(address => Service) public getMyServiceDetails;
    mapping(address => bool) public alreadyPurchased;

    // purchase subscription
    function buy(Type selectedType) public payable serviceActive {
        require(
            !alreadyPurchased[msg.sender],
            "You already purchased the service"
        );

        // temporary instance
        Service memory serviceInstance = Service(
            singleUserServicePrice,
            selectedType,
            payable(msg.sender),
            block.timestamp,
            block.timestamp + 10 seconds
        );

        // adding to mapping
        getMyServiceDetails[msg.sender] = serviceInstance;

        if (selectedType == Type.SingleOwner) {
            // payment
            require(msg.value >= singleUserServicePrice, "Invalid Value Field");
            (bool sent, ) = owner.call{value: singleUserServicePrice}("");
            require(sent, "Fund Transfer Error");
        } else {
            // payment
            require(
                msg.value >= multipleUserServicePrice,
                "Invalid Value Field"
            );
            (bool sent, ) = owner.call{value: multipleUserServicePrice}("");
            require(sent, "Fund Transfer Error");

            users[msg.sender].push(msg.sender);
        }

        alreadyPurchased[msg.sender] = true;
        alreadyUser[msg.sender][msg.sender] = true;

        emit PurchaseSuccessful(msg.sender, serviceInstance);
    }

    function addUser(address _newUser) public payable {
        require(
            getMyServiceDetails[msg.sender].serviceType == Type.MultipleOwner,
            "Service Type needs to be Multiple user"
        );

        require(
            users[msg.sender].length < maximumUsers,
            "Not Allowed to add more users"
        );

        require(alreadyUser[msg.sender][_newUser] == false, "Alreay a user");

        require(msg.sender != _newUser, "User cannot add itself");

        // payment
        require(msg.value >= userAdditionPrice, "Invalid Value Field");
        (bool sent, ) = owner.call{value: userAdditionPrice}("");
        require(sent, "Fund Transfer Error");

        users[msg.sender].push(_newUser);

        alreadyUser[msg.sender][_newUser] = true;

        emit UserAdded(msg.sender, _newUser, getMyServiceDetails[msg.sender]);
    }

    function getUsers() public view returns (address[] memory) {
        require(
            getMyServiceDetails[msg.sender].serviceType == Type.MultipleOwner,
            "Service Type needs to be Multiple user"
        );

        return users[msg.sender];
    }

    function useService() public view returns (bool) {
        // if (getMyServiceDetails[msg.sender].endTime - getMyServiceDetails[msg.sender].lastPurchase > 0) {
        //     return true;
        // }
        // return false;
    }
}

// set and check benifits
// set offers
// show available offers
// update offers (based on some conditions)
// transfer ownership
// remove user
// renew subscription
