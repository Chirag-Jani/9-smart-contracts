// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";

// ! fund transfer error

contract Auction {
    // how to automatically call the functions in contracts (to end the auction)

    // write events for each one

    // the one who manages everything
    address payable public owner;

    // item struct
    struct Item {
        uint256 id;
        // IERC721 nft; // will require an address IERC721(address) to fetch the nft
        string nftName;
        uint256 price;
        address payable seller;
        address highestBidder;
        uint256 startTime;
        uint256 endTime;
        State state;
        address winner;
    }

    enum State {
        Created,
        Ongoing,
        Ended
    }

    // to store the bidder info
    struct Bidder {
        address bidderAddress;
        uint256 bidAmount;
    }

    // to store all the items
    Item[] items;

    // to maintain the index
    uint256 index;

    // to get individual Item info from ID
    mapping(uint256 => Item) public getItemDetails;

    // id => all the bidders
    mapping(uint256 => Bidder[]) getBidders;

    // get highest bidder info
    mapping(address => Bidder) getHighestBidder;

    // constructor to set owner
    constructor() {
        owner = payable(msg.sender);
    }

    // create auction
    function create(
        uint256 _id,
        // address _nft,
        string memory _nftName,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    ) public {
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

    function start(uint256 _id) public {
        // only owner can start
        require(msg.sender == owner, "Only owner can start auction");

        // needs to be in created state
        require(
            getItemDetails[_id].state == State.Created,
            "Not in Created State"
        );

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

    function bid(uint256 _id, uint256 _amount) public {
        // owner can  not bid
        require(msg.sender != owner, "owner can not bid");

        // needs to be in ongoing state
        require(
            getItemDetails[_id].state == State.Ongoing,
            "Not in Ongoing State"
        );

        // getting item with the given id
        Item storage _selectedItem = getItemDetails[_id];

        // getting the current highest bidder's address of the given item
        address currHightest = _selectedItem.highestBidder;

        // getting the bidder's info from the address
        Bidder storage _bidder = getHighestBidder[currHightest];

        // bid should be greater than the price
        require(
            _amount > _selectedItem.price,
            "Your bid needs to be higher than the price"
        );

        // comparing amounts
        require(
            _amount > _bidder.bidAmount,
            "Your bid needs to be higher than the current bid"
        );

        // setting the new highest bidder
        _selectedItem.highestBidder = msg.sender;

        // adding to the bidder array of the selected item's id
        getBidders[_id].push(Bidder(msg.sender, _amount));
    }

    function end(uint256 _id) public payable {
        // only owner can end
        require(msg.sender == owner, "Only owner can end");

        // getting item with the given id
        Item storage _selectedItem = getItemDetails[_id];

        // getting the current highest bidder's address of the given item
        address currHightest = _selectedItem.highestBidder;

        // getting the bidder's info from the address
        Bidder storage _bidder = getHighestBidder[currHightest];

        // checking the state
        require(
            _selectedItem.state == State.Ongoing,
            "The state needs to be Ongoing"
        );

        // time should be right
        // require(_selectedItem.endTime <= block.timestamp, "You can not end the auction yet");

        // transfer the funds if the current highest bidder has the amount available
        if (currHightest.balance >= _bidder.bidAmount) {
            // (bool success, ) = _selectedItem.seller.call{ value: _bidder.bidAmount}("");
            (bool success, ) = _selectedItem.seller.call{value: 8 ether}("");
            require(success == true, "Fund transfer error");

            // set the state to ended
            _selectedItem.state = State.Ended;

            _selectedItem.winner = _bidder.bidderAddress;
        } else {
            // find the next highest
            Bidder[] memory _biddersArray = getBidders[_id];

            for (uint256 i = 0; i < _biddersArray.length; i++) {
                Bidder memory tempBidder = getHighestBidder[
                    _biddersArray[i].bidderAddress
                ];

                if (tempBidder.bidderAddress.balance >= tempBidder.bidAmount) {
                    // (bool success,) = _selectedItem.seller.call{ value: tempBidder.bidAmount }("");
                    (bool success, ) = _selectedItem.seller.call{
                        value: 17 ether
                    }("");

                    if (success) {
                        _selectedItem.winner = tempBidder.bidderAddress;
                        return;
                    }
                }
            }

            // set the state to ended
            _selectedItem.state = State.Ended;
        }
    }
}
