// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MultiSig {
    // generate with seed (private key genetation)
    // generate public key
    // any owner can create transactions and sign it's part when it does create

    // the one that creates the transactions
    address payable deployer;

    // wallet state
    bool public wallletInitialized;

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // when any owner signs the transaction
    event TransactionSigned(
        uint256 indexed TransactionId,
        address indexed Signer
    );

    // when transaction is successfully executed
    event TransactionExecuted(
        uint256 indexed TransactionId,
        address Reciever,
        uint256 Amount
    );

    // struct of owner
    struct Owner {
        address payable publicAddress;
        bytes32 signature;
    }

    // total owners
    uint256 public totalOwners = 3;

    // transaction struct
    struct Tx {
        uint256 id;
        bytes32[] signatures;
        uint256 totalConfirmations;
        address payable to;
        uint256 amount;
        bool transactionExecuted;
    }

    // to check is any perticular owner has already signed the given transaction or not
    mapping(uint256 => mapping(bytes32 => bool)) signedOrNot;

    // to get the tranasaction detail
    mapping(uint256 => Tx) public getTransaction;

    // to get owner
    mapping(address => Owner) getOwner;

    // to check if given address is owner or not
    mapping(address => bool) isPartOwner;

    // current transaction id
    uint256 public txId = 0;

    constructor() {
        deployer = payable(msg.sender);
    }

    // initialization of wallet
    function initializeWallet() public {
        require(msg.sender == deployer, "Only deployer can initialize wallet");

        address owner1 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        string memory password1 = "Password 1";
        bytes32 signature1 = generateSignature(owner1, password1);

        address owner2 = 0x583031D1113aD414F02576BD6afaBfb302140225;
        string memory password2 = "Password 2";
        bytes32 signature2 = generateSignature(owner2, password2);

        address owner3 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
        string memory password3 = "Password 3";
        bytes32 signature3 = generateSignature(owner3, password3);

        getOwner[owner1] = Owner(payable(owner1), signature1);
        getOwner[owner2] = Owner(payable(owner2), signature2);
        getOwner[owner3] = Owner(payable(owner3), signature3);

        isPartOwner[owner1] = true;
        isPartOwner[owner2] = true;
        isPartOwner[owner3] = true;

        wallletInitialized = true;
    }

    // generating signatures based on public key and password
    function generateSignature(address publicKey, string memory password)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(publicKey, password));
    }

    // creating transactions
    function createTransaction(address _to, uint256 amount) public {
        // wallet must be initialized
        require(wallletInitialized, "Wallet not initialized yet");

        // can not send funds to itself
        require(_to != msg.sender, "Cannot send funds to itself");

        // to push an empty array of signatures
        bytes32[] memory temp;

        // adding to the mapping
        getTransaction[txId] = Tx(txId, temp, 0, payable(_to), amount, false);

        // incrementing id for the next one
        txId += 1;
    }

    // signing transaction
    function signTx(uint256 transactionId, string memory _password) public {
        // only owner can call
        require(isPartOwner[msg.sender] == true, "Only owner can call");

        // getting transaction
        Tx storage tempTx = getTransaction[transactionId];

        // generating signature from public key and entered password
        bytes32 sig = keccak256(abi.encodePacked(msg.sender, _password));

        // checking signature
        require(
            getOwner[msg.sender].signature == sig,
            "Signature doesn't match"
        );

        // checkig if already signed or not
        require(signedOrNot[transactionId][sig] != true, "Already Signed once");

        // adding to signatures
        tempTx.signatures.push(sig);

        // updating confirmations
        tempTx.totalConfirmations += 1;

        // checking as signed
        signedOrNot[transactionId][sig] = true;

        // send your part to the contract

        // emitting signing event
        emit TransactionSigned(transactionId, msg.sender);
    }

    // executing transactions
    function executeTransaction(uint256 id) public payable {
        // checking sender (can be done msg.sender == address(this) by doing this only contract can call this
        require(msg.sender == deployer, "Only deployer can call");

        // getting transaction
        Tx storage tempTx = getTransaction[id];

        // checking signatures
        require(
            tempTx.totalConfirmations == totalOwners,
            "Not enough Signatures"
        );

        // marking as executed
        tempTx.transactionExecuted = true;

        // checking value field
        require(msg.value >= tempTx.amount, "Value field invalid");

        // distribute amount among the owners

        // transacting
        (bool sent, ) = tempTx.to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        // emitting executed event
        emit TransactionExecuted(id, tempTx.to, tempTx.amount);
    }
}
