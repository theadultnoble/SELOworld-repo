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

/*
  SELOWORLD IS AN NFT MARKETPLACE FOR AUCTIONING REAL ESTATE ON THE NATIVE CELO NETWORK
*/
contract Seloworld {
    address internal _Owner;
    uint256 public landsLength = 0;
    uint256 internal salesMenLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    uint256 private seed;

    // DEFAULT AUCTION VARs
    uint32 public bidIncreasePercentage;
    uint32 public feePercentage;
    address feeRecepient = _Owner;

    bool public started;
    bool public ended;

    struct Land {
        address payable owner;
        string name;
        string image;
        string streetName;
        uint256 minPrice; 
        uint256 highestBid;
        address highestBidder;
        uint256 auctionEnd;
      }

    mapping(address => mapping(uint256 => Land)) public lands; // MAP Land STRUCT TO AN UINT AND THEN TO AN ADDRESS IN lands ARRAY
    mapping (address => bool) public salesMen; 
    
    /*
      AUCTION EVENTS 
    */
    event AuctionCreated(
      address payable owner,
      string name,
      string image,
      string streetName,
      uint256 minPrice
    );

    event AuctionStart(
      address owner,
      uint256 minPrice,
      uint32 bidIncreasePercentage,
      address feeRecepient,
      uint256 feePercentage
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
      END AUCTION EVENTS
    */
    
    /*
      AUCTION MODIFIERS
    */
    
    //REQUIRES MINIMUM PRICE SET FOR AUCTION IS GREATER THAN ZERO
    modifier priceGreaterThanZero(uint256 _minPrice) {
      require(_minPrice > 0, "Price cannot be 0");
      _;
    }
    
    //REQUIRES AUCTION SELLER CANT BID ON OWN AUCTION
    modifier notNftSeller(address _landaddress, uint256 _index) {
      require(msg.sender != lands[_landaddress][_index].owner, "Owner cannot bid on own NFT");
      _;
    }

    //REQUIRES BID MADE MEETS ALL STANDARDS 
    modifier bidMeetsRequirements(
      address _landaddress,
      uint _index,
      uint256 _amount
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
    
    //REQUIRES MINIMUM BID HAS NOT BEEN MADE
    modifier minBidNotMade(
      address _landaddress,
      uint256 _index
    ) {
      require(!_isMinimumBidMade(_landaddress, _index), "Min bid made");
      _;
    }

    /*
      END AUCTION MODIFIERS
    */
    
    //CONSTRUCTOR CODE CALLED ONCE WHEN CONTRACT IS DEPLOYED

    constructor() {
      _Owner = msg.sender; 
      bidIncreasePercentage = 100;
      feePercentage = 10;
      seed = uint (blockhash(block.number - 1)) % 100;

      salesMen[_Owner] = true; //GIVES _Owner PERMISSION TO WRITELAND

      if(salesMen[_Owner] = true){
        salesMenLength++;
      }
    }

    /*
      CHECK AUCTION FUNCTIONS
      N.B - CALLED IN AUCTION MODIFIERS
    */
    
    function _isMinimumBidMade(address _landaddress,uint256 _index) internal view returns (bool) {
      uint256 minPrice = lands[_landaddress][_index].minPrice;
      return
      minPrice > 0 && (lands[_landaddress][_index].highestBid >= minPrice);
    }
    
    function _doesBidMeetBidRquirements(address _landaddress, uint256 _index, uint256 _amount)
    internal view returns (bool) {
      uint256 bidIncreaseAmount = (lands[_landaddress][_index].highestBid *
      (10000 + bidIncreasePercentage)) / 10000;
      return (msg.value >= bidIncreaseAmount ||
      _amount >= bidIncreaseAmount);
    }

    // RETURNS THE CALCULATED FEE TO BE PAID 
    function _getPortionOfBid(address _landaddress,uint256 _index)
        internal
        view
        returns (uint256)
    {
      uint256 highestBid = lands[_landaddress][_index].highestBid;
        return (highestBid * feePercentage) / 10000;
    }

    /*
      END AUCTION CHECK FUNCTIONS
    */
    
    //HANDLE AUCTION PAYMENTS
    function _payout(
      address _recepient,
      uint256 _amount
    ) internal {
      if(1>0){
      require(IERC20Token(cUsdTokenAddress).transfer(
        _recepient,
        _amount
      ));
      } else{
        (bool sent, ) = payable(_recepient).call{value: _amount, gas: 20000}("");
        require(sent, "Could not withdraw");
        }
      }


    /*
      AUCTION FUNCTIONS
    */

    
    //GIVE USER RIGHT TO ADD NEW AUCTIONS
    // SEED IMITATES AN ACCOUNT LISTING ASSESMENT FOR USERS  
    function GiveRightToAuction (
      address _salesman
    ) external returns (bool) {
      if(seed >=1) {
        salesMen[_salesman] = true;
        salesMenLength++;
      }
      return (salesMen[_salesman]);
    }

    function CreateAuction(
      address payable _owner,
      string memory _name,
      string memory _image,
      string memory _streetName,
      uint256 _minPrice
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

  function MakeBid(address _landaddress, uint256 _index, uint256 _amount) external payable
  /*bidMeetsRequirements(
    _landaddress,
    _index,
    _amount
  ) 
  minBidNotMade(
    _landaddress,
    _index
  ) 
  notNftSeller(
   _landaddress, 
   _index
  )*/{
    /*require(started, "Auction has not started");
    require(block.timestamp < lands[_landaddress][_index].auctionEnd, "Auction has ended");*/
      require(IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        address(this),
        _amount
      ), "Transfer failed");
    lands[_landaddress][_index].highestBid = _amount;
    lands[_landaddress][_index].highestBidder = msg.sender;
    /*
    emit BidMade(
      msg.sender,
      msg.value
    );*/
  }
  
  function WithdrawBid(address _landaddress, uint256 _index) external payable
  minBidNotMade(_landaddress, _index) 
  {
    address highestBidder = lands[_landaddress][_index].highestBidder;
    uint256 highestBid = lands[_landaddress][_index].highestBid;
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

  function SettleFeesandBids (
    address _landaddress, 
    uint256 _index
    ) internal {
      uint256 fee = _getPortionOfBid(_landaddress, _index);
      _payout(
        feeRecepient,
        fee
      );
  }

  function EndAuction(address _landaddress, uint256 _index) external {
    require(started, "You need to start first!");
      require(block.timestamp >= lands[_landaddress][_index].auctionEnd, "Auction is still ongoing!");
        require(!ended, "Auction already ended!");
        address highestBidder = lands[_landaddress][_index].highestBidder;
        uint256 highestBid = lands[_landaddress][_index].highestBid;
        address owner = lands[_landaddress][_index].owner;
      
        if(highestBidder != address(0)) {
          require(IERC20Token(cUsdTokenAddress).transferFrom(
          address(this),
          owner,
          highestBid), "failed"
          );
        } else {
          (bool sent,) = payable(owner).call{value: highestBid, gas: 20000}("");
          require(sent, "Could not withdraw");
        }

        SettleFeesandBids(_landaddress,_index);

        //to disburse funds to other bidders

        ended = true;
        emit AuctionEnd(
          highestBidder
        );

  }

  function ReadAuction(address _landaddress,uint256 _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    uint256
  ) {
    return (
      lands[_landaddress][_index].owner,
      lands[_landaddress][_index].name,
      lands[_landaddress][_index].image, 
      lands[_landaddress][_index].streetName,
      lands[_landaddress][_index].minPrice
    );
  }

  function GetLandsLength() public view returns (uint) {
    return (landsLength);
  }

  function GetSalesMenLength() public view returns (uint){

    return (salesMenLength);
  }

  /*
    END AUCTION FUNCTIONS
  */

}