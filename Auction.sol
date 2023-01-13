// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";

contract Auction{
    // how to automatically call the functions in contracts (to end the auction)

    // write events for each one

    // the one who manages everything
    address payable public owner;

    // item struct
    struct Item{
        uint id;
        // IERC721 nft; // will require an address IERC721(address) to fetch the nft
        string nftName;
        uint price;
        address payable seller;
        address highestBidder;
        uint startTime;
        uint endTime;
        State state;
        address winner;
    }

    enum State {
        Created,
        Ongoing,
        Ended
    }

    // to store the bidder info
    struct Bidder{
        address payable bidderAddress;
        uint bidAmount;
    }

    // to store all the items
    Item[] items;

    // to maintain the index
    uint index;

    // to get individual Item info from ID
    mapping(uint => Item) public getItemDetails;

    // id => all the bidders
    mapping(uint => Bidder[]) getBidders; 

    // get highest bidder info
    mapping(address => Bidder) getHighestBidder;

    // constructor to set owner
    constructor(){
        owner = payable(msg.sender);
    }

    // create auction
    function create(
        uint _id,
        // address _nft,
        string memory _nftName,
        uint _price,
        uint _startTime,
        uint _endTime
    )
    public{

        // manager can not create - make this reverse (bija koi no kari sakva joiye)
        require(msg.sender == owner, "Only Owner can create");

        // non zero price
        require(_price != 0, "Please add Non-zero price");

        // start time and end time
        require(_startTime < _endTime, "Add valid end time");

        // adding to array
        items.push(
            Item(
                _id,
                // IERC721(_nft),
                _nftName,
                _price,
                owner,
                address(0),
                _startTime,
                _endTime,
                State.Created,
                address(0)
            )
        );

        // adding to mapping
        getItemDetails[_id] = items[index];

        // incrementing the index
        index++;
    }

    function start(uint _id) public {
        // only owner can start
        require(msg.sender == owner, "Only owner can start auction");

        // needs to be in created state
        require(getItemDetails[_id].state == State.Created , "Not in Created State");

        // need to be valid time
        // require(block.timestamp == getItemDetails[_id].startTime || 
        // (
        //     block.timestamp > getItemDetails[_id].startTime && block.timestamp < getItemDetails[_id].endTime
        // ),
        // "Not Valid Start time"
        // );

        // set the state
        getItemDetails[_id].state = State.Ongoing;
    }

    function bid(uint _id, uint _amount) public{
        // owner can  not bid
        require(msg.sender != owner, "owner can not bid");

        // needs to be in ongoing state
        require(getItemDetails[_id].state == State.Ongoing , "Not in Ongoing State");

        // getting item with the given id
        Item storage _selectedItem = getItemDetails[_id];

        // getting the current highest bidder's address of the given item
        address currHightest = _selectedItem.highestBidder;

        // getting the bidder's info from the address
        Bidder storage _bidder = getHighestBidder[currHightest];

        // bid should be greater than the price
        require(_amount > _selectedItem.price, "Your bid needs to be higher than the price");

        // comparing amounts
        require(_amount > _bidder.bidAmount, "Your bid needs to be higher than the current bid"); 

        // setting the new highest bidder
        _selectedItem.highestBidder = msg.sender;

        // adding to the bidder array of the selected item's id
        getBidders[_id].push(Bidder(payable(msg.sender), _amount));
    }

    function end(uint _id) public payable{

        // only owner can end
        require(msg.sender == owner, "Only owner can end");

        // getting item with the given id
        Item storage _selectedItem = getItemDetails[_id];

        // getting the current highest bidder's address of the given item
        address currHightest = _selectedItem.highestBidder;

        // getting the bidder's info from the address
        Bidder storage _bidder = getHighestBidder[currHightest];

        // checking the state
        require(_selectedItem.state == State.Ongoing, "The state needs to be Ongoing");

        // time should be right
        // require(_selectedItem.endTime <= block.timestamp, "You can not end the auction yet");

        // fund transfer
        _selectedItem.seller.transfer(_bidder.bidAmount);
        
        _selectedItem.winner = _bidder.bidderAddress;

        // set the state to ended
        _selectedItem.state = State.Ended;

    }
}

// // transfer the funds if the current highest bidder has the amount available
//         if(currHightest.balance >= _bidder.bidAmount){
            
//             _selectedItem.seller.transfer(_bidder.bidAmount);
        
//             // set the state to ended
//             _selectedItem.state = State.Ended;

//             // setting winner
//             _selectedItem.winner = _bidder.bidderAddress;
//         }

//         else{
//             // find the next highest
//             Bidder[] memory _biddersArray = getBidders[_id];

//             for(uint i = 0; i < _biddersArray.length; i++){
                
//                 Bidder memory tempBidder = getHighestBidder[_biddersArray[i].bidderAddress];

//                 if(tempBidder.bidderAddress.balance >= tempBidder.bidAmount){

//                     _selectedItem.seller.transfer(tempBidder.bidAmount);
//                     _selectedItem.winner = tempBidder.bidderAddress;
    
//                     // set the state to ended
//                     _selectedItem.state = State.Ended;

//                     return;
//                 }
//             }
//         }