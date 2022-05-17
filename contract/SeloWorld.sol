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

contract SeloWorld {
    uint internal landsLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Land {
        address payable owner;
        string name;
        string image;
        string streetName;
        uint price;
        
    }
    mapping (uint => Land) internal lands;

    struct salesMan {
      address owner;
      string name;
      uint weight;
    }
    mapping (address => salesMan) internal salesMen;


    //0x4845dBEF5e48176fc92C0fc2F341E8f85F2Ca5b4

    //give a user the right to add a new Land
    //can be called by anyone sending the transaction
    function giveRightToWriteLand (
      address _owner
    ) external {
      require(salesMen[_owner].weight == 0);
        salesMen[_owner].weight = 1;


    }

    function writeLand(
      string memory _name,
      string memory _image,
      string memory _streetName,
      uint _price
    ) public {
        salesMan storage sender = salesMen[msg.sender];
        require(sender.weight != 0, "Has no right");
    
      lands[landsLength] = Land(
        payable(msg.sender),
        _name,
        _image,
        _streetName,
        _price
      );
      landsLength++;
    }

  function deleteLand(uint _index) public payable {
    lands[_index] = lands[landsLength - 1];
    lands.pop();
  }
  function orderedLand(uint _index) public {
    for(uint i = _index ; i < landsLength -1; i++){
      lands[i] = lands[i+1];
    }
    lands.pop();
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


}