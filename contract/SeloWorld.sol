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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   *  The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   *  Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }


  /**
   * Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Seloworld is Ownable {
    uint internal landsLength = 0;
    uint internal salesMenLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Land {
        address payable owner;
        string name;
        string image;
        string streetName;
        uint price;
        
    }
    mapping (uint => Land) internal lands;
    
    uint256 private seed;


    mapping (address => bool) public salesMen;

    constructor(){
      seed = uint (blockhash(block.number - 1)) % 100;
      salesMen[_owner] = true;

    }
    
    
    //give a user the right to add a new Land
    //can be called by anyone sending the transaction
    function giveRightToWriteLand (
      address _salesman
    ) external {
      if(seed <= 50) {
        salesMen[_salesman] = true;
        salesMenLength++;
        }
    }

    function writeLand(
      string memory _name,
      string memory _image,
      string memory _streetName,
      uint _price
    ) public {
      bool sender = salesMen[msg.sender];
      require(sender != false, "has no right");
    
      lands[landsLength] = Land(
        payable(msg.sender),
        _name,
        _image,
        _streetName,
        _price
      );
      landsLength++;
    }
    
    function readLand(uint _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    uint
  ) {
    return (
      lands[_index].owner,
      lands[_index].name,
      lands[_index].image, 
      lands[_index].streetName,
      lands[_index].price
    );
  }

  function buyLand(uint _index) public payable {
    require(
      IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        lands[_index].owner,
        lands[_index].price
      ),
      "Transfer Failed."
      );
  }

  function getLandsLength() public view returns (uint) {
    return (landsLength);
  }

  function getSalesMenLength() public view returns (uint){
    return (salesMenLength);
  }


}