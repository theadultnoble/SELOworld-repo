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
    address payable public feeRecepient;

    mapping(uint => bool) public started;
    mapping(uint => bool) public ended;

    struct Land {
        address payable owner;
        string name;
        string image;
        uint256 minPrice; 
        uint256 highestBid;
        address payable highestBidder;
      }

    mapping(uint256 => Land) public lands; // MAP Land STRUCT TO AN UINT IN lands ARRAY
    mapping (address => bool) public salesMen; 
    
    /*
      AUCTION EVENTS 
    */
    event AuctionStart(
      address owner,
      string name,
      string image,
      uint256 minPrice
    );

    event BidMade(
      address bidder,
      uint256 amount
    );


    event AuctionEnd(
      address auctionSettler
    );
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
    modifier notNftSeller(uint256 _index) {
      require(msg.sender != lands[_index].owner, "Owner cannot bid on own NFT");
      _;
    }

    //REQUIRES BID MADE MEETS ALL STANDARDS 
    modifier bidMeetsRequirements(
      uint _index,
      uint256 _amount
    ) {
      require(
        _doesBidMeetBidRquirements(
          _index,
          _amount
        ), "Not enough to bid"
      );
      _;
    }
    /*
      END AUCTION MODIFIERS
    */

  
    
    //CONSTRUCTOR CALLED ONCE WHEN CONTRACT IS DEPLOYED

    constructor() {
      _Owner = msg.sender; 
      feeRecepient = payable(msg.sender);
      bidIncreasePercentage = 100;
      feePercentage = 15;
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
    
    function _doesBidMeetBidRquirements(uint256 _index, uint256 _amount)
    internal view returns (bool) {
      uint256 bidIncreaseAmount = (lands[_index].highestBid *
      (10000 + bidIncreasePercentage)) / 10000;
      return (msg.value >= bidIncreaseAmount ||
      _amount >= bidIncreaseAmount);
    }

    // RETURNS THE CALCULATED FEE TO BE PAID 
    function _getPortionOfBid(uint256 _index)
        public
        view
        returns (uint256)
    {
      uint256 highestBid = lands[_index].highestBid;
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

    function _settleFeesandBids(
      uint256 _index
    ) internal{
      uint256 fee = _getPortionOfBid(_index);
      _payout(
        feeRecepient,
        fee
      );
  }


    /*
      AUCTION FUNCTIONS
    */
    // GIVE USER RIGHT TO ADD NEW AUCTIONS
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
      string memory _name,
      string memory _image,
      uint256 _minPrice
    ) public  
    priceGreaterThanZero(
      _minPrice
    )
    {
      bool sender = salesMen[msg.sender];
      require(sender != false, "has no right");
      lands[landsLength].owner = payable(msg.sender);
      lands[landsLength].name = _name;
      lands[landsLength].image= _image;
      lands[landsLength].minPrice = _minPrice;
      
      started[landsLength] = true;
      ended[landsLength] = false;
      
      landsLength++;
      emit AuctionStart(
       msg.sender,
       _name,
       _image,
       _minPrice
      );
    }

  function MakeBid(uint256 _index, uint256 _amount) external payable
   bidMeetsRequirements(
    _index,
    _amount
  ) 
  notNftSeller( 
   _index
  ){
    require(started[_index], "Auction has not started");
    require(!ended[_index], "Auction has ended!");
      require(IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        address(this),
        _amount
      ), "Transfer failed");
      
    lands[_index].highestBid = _amount;
    lands[_index].highestBidder = payable(msg.sender);

    emit BidMade(
      msg.sender,
      msg.value
    );
  
  }

  receive() external payable{}

  function GetBalance() public view returns(uint) {
     return address(this).balance;
  } 
  
  function EndAuction(uint256 _index) external {
    require(started[_index], "You need to start first!");
    require(!ended[_index], "Auction already ended!");
    require(msg.sender == lands[_index].owner, "not owner of auction");
    address highestBidder = lands[_index].highestBidder;
    uint256 highestBid = lands[_index].highestBid;
    address owner = lands[_index].owner;
    uint256 fee = _getPortionOfBid(_index);
    uint256 winningBid = highestBid - fee;
    if(highestBidder != address(0)) {
        _payout(
        owner,
        winningBid
        );
        } else {
          (bool sent,) = payable(owner).call{value: winningBid, gas: 20000}("");
          require(sent, "Could not withdraw");
        }

        _settleFeesandBids(_index);

        ended[_index] = true;
        started[_index] = false;

        emit AuctionEnd(
          highestBidder
        );

  }

  function ReadAuction(uint256 _index) public view returns (
    address payable,
    string memory,
    string memory,
    uint256,
    uint256,
    address
  ) {
    return (
      lands[_index].owner,
      lands[_index].name,
      lands[_index].image, 
      lands[_index].minPrice,
      lands[_index].highestBid,
      lands[_index].highestBidder
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
