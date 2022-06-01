// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Seloworld {
    address internal _Owner;
    uint public landsLength = 0;
    uint internal salesMenLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    uint256 private seed;

    //Default Values for LandAuction
    uint32 public bidIncreasePercentage;
    uint32 public feePercentage;
    address feeRecepient = _Owner;

    struct Land {
        address payable owner;
        string name;
        string image;
        string streetName;
        uint128 minPrice; 
        uint128 highestBid;
        address highestBidder;
        uint256 auctionEnd;
        
        
    }
    mapping(address => mapping(uint256 => Land)) public lands;

    mapping (address => bool) public salesMen;


    /*
      EVENTS 
    */
    event AuctionCreated(
      address payable owner,
      string name,
      string image,
      string streetName,
      uint128 minPrice
    );

    event AuctionStart(
      address owner,
      uint128 minPrice,
      uint32 bidIncreasePercentage,
      address feeRecepient,
      uint32 feePercentage
    );

    event BidMade(
      address bidder,
      uint256 amount
    );


    event AuctionEnd(
      address auctionSettler
    );

    event BidWithdrawn(
      address highestBidder
    );

    event HighestBidTaken();
    /*
      ENDEVENTS
    */

    bool public started;
    bool public ended;
    
    /*
      MODIFIERS
    */
    
    modifier priceGreaterThanZero(uint256 _minPrice) {
      require(_minPrice > 0, "Price cannot be 0");
      _;
    }
  
    modifier notNftSeller(address _landaddress, uint256 _index) {
      require(msg.sender != lands[_landaddress][_index].owner, "Owner cannot bid on own NFT");
      _;
    }
    modifier bidMeetsRequirements(
      address _landaddress,
      uint _index,
      uint128 _amount
    ) {
      require(
        _doesBidMeetBidRquirements(
          _landaddress,
          _index,
          _amount
        ), "Not enough to bid"
      );
      _;
    }
    
    modifier minBidNotMade(
      address _landaddress,
      uint _index
    ) {
      require(!_isMinimumBidMade(_landaddress, _index), "Min bid made");
      _;
    }
    

    /*
      ENDMODIFIERS
    */

    constructor() {
      _Owner = msg.sender;
      seed = uint (blockhash(block.number - 1)) % 100;
      salesMen[_Owner] = true;
      if(salesMen[_Owner] = true){
        salesMenLength++;
      }
      bidIncreasePercentage = 100;
      feePercentage = 10;

    }

    /*
      CHECK FUNCTIONS
    */
    
    function _isMinimumBidMade(address _landaddress,uint _index) internal view returns (bool) {
      uint128 minPrice = lands[_landaddress][_index].minPrice;
      return
      minPrice > 0 && (lands[_landaddress][_index].highestBid >= minPrice);
    }
    
    

    function _doesBidMeetBidRquirements(address _landaddress, uint _index, uint128 _amount)
    internal view returns (bool) {
      uint128 bidIncreaseAmount = (lands[_landaddress][_index].highestBid *
      (10000 + bidIncreasePercentage)) / 10000;
      return (msg.value >= bidIncreaseAmount ||
      _amount >= bidIncreaseAmount);
    }

    // Returns the percentage of the total bid (used to calculate fee payments)
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }
    /*
      END CHECK FUNCTIONS
    */


    /*
      AUCTION FUNCTIONS
    */

    //give a user the right to add new Land
    //can be called by anyone sending the transaction
    function giveRightToWriteLand (
      address _salesman
    ) external returns (bool) {
      if(seed >=1) {
        salesMen[_salesman] = true;
        salesMenLength++;
      }
      return (salesMen[_salesman]);

    }

    function writeLand(
      address payable _owner,
      string memory _name,
      string memory _image,
      string memory _streetName,
      uint128 _minPrice
    ) public  {
      bool sender = salesMen[msg.sender];
      require(sender != false, "has no right");
      lands[_owner][landsLength].owner = _owner;
      lands[_owner][landsLength].name = _name;
      lands[_owner][landsLength].image= _image;
      lands[_owner][landsLength].streetName = _streetName;
      lands[_owner][landsLength].minPrice = _minPrice;


      landsLength++;
      started = true;
      lands[_owner][landsLength].auctionEnd = block.timestamp + 1 days;


      emit AuctionCreated(
       _owner,
       _name,
       _image,
       _streetName,
       _minPrice
      );

      
    }
    
    function readLand(address _landaddress,uint _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    uint128
  ) {
    return (
      lands[_landaddress][_index].owner,
      lands[_landaddress][_index].name,
      lands[_landaddress][_index].image, 
      lands[_landaddress][_index].streetName,
      lands[_landaddress][_index].minPrice
    );
  }

  function makeBid(address _landaddress, uint _index, uint128 _amount) external payable
 /* bidMeetsRequirements(
    _landaddress,
    _index,
    _amount
  ) 
  minBidNotMade(
    _landaddress,
    _index
  )*/ {
    //require(started, "Auction has not started");
    //require(block.timestamp < lands[_landaddress][_index].auctionEnd, "Auction has ended");
      IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        address(this),
        _amount
      );
      lands[_landaddress][_index].highestBid = _amount;
      lands[_landaddress][_index].highestBidder = msg.sender;
    emit BidMade(
      msg.sender,
      msg.value
    );
  }

  function withdrawBid(address _landaddress, uint _index) external payable
  minBidNotMade(_landaddress, _index) 
  {
    address highestBidder = lands[_landaddress][_index].highestBidder;
    uint128 highestBid = lands[_landaddress][_index].highestBid;
    if(highestBidder != address(0)){
      require(IERC20Token(cUsdTokenAddress).transferFrom(
        address(this),
        msg.sender,
        highestBid), "failed"
      );
      } else{
        (bool sent, ) = payable(msg.sender).call{value: highestBid, gas: 20000}("");
        require(sent, "Could not withdraw");
        }
    
    emit BidWithdrawn(
      msg.sender
    );

  }

  function endAuction(address _landaddress, uint _index) external {
    require(started, "You need to start first!");
      require(block.timestamp >= lands[_landaddress][_index].auctionEnd, "Auction is still ongoing!");
        require(!ended, "Auction already ended!");
        address highestBidder = lands[_landaddress][_index].highestBidder;
        uint128 highestBid = lands[_landaddress][_index].highestBid;
        address owner = lands[_landaddress][_index].owner;
        if(highestBidder != address(0)) {
          require(IERC20Token(cUsdTokenAddress).transferFrom(
          address(this),
          owner,
          highestBid), "failed"
          );
        } else {
          (bool sent,) = payable(msg.sender).call{value: highestBid, gas: 20000}("");
          require(sent, "Could not withdraw");
        }

        //to disburse funds to other bidders

        ended = true;
        emit AuctionEnd(
          highestBidder
        );

  }

  function getLandsLength() public view returns (uint) {
    return (landsLength);
  }

  function getSalesMenLength() public view returns (uint){

    return (salesMenLength);
  }
  /*
    ENDAUCTIONFUNCTIONS
  */

}