
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery is ERC20, Ownable{
    using SafeMath for uint256;
    address public nft;
    address public winnerAddress;

    mapping(address=>address)user_contract; 


    mapping(address => uint[]) user_ticketID;
    mapping(uint=> address) ticketID_user;

    uint[] purchasedTickets;

    constructor() ERC20("ConquerLottery", "CNQ") {
        _mint(address(this), 10000);
        nft = address(new NFTs());
    }

    function tokenPrice(uint256 _numTokens) internal pure returns (uint256){
        return _numTokens.mul(0.5 ether);
    }


    function mint(uint _numTokens) public onlyOwner {
        _mint(address(this), _numTokens);
    }

    function userRegister() internal{
        address secondContract = address (new Tickets(msg.sender, address(this), nft));
        user_contract[msg.sender] = secondContract; 
    }

    function usersInfo (address _user) public view returns(address){
        return user_contract[_user]; 
    }

    function buyTokensERC20(uint _numTokens) public payable {
        if(user_contract[msg.sender] == address(0))
        {
            userRegister();
        }

        require (balanceOf(address(this))>= _numTokens, "Not enough tokens") ;
        uint price = tokenPrice(_numTokens);
        require(msg.value >= price, "Not enough ethers");
        uint returnValue = msg.value.sub(price);
        require(msg.sender == tx.origin, "Token purchase only possible from EOA");
        payable(msg.sender).transfer(returnValue);
        _transfer(address(this), msg.sender, _numTokens);

    }

    function ticketPrice() public returns (uint) {
        return 2;
    }


    function buyTicket (uint _numTickets) public {
        uint256 totalPrice = _numTickets.mul(ticketPrice());
        require(balanceOf(msg.sender) >= totalPrice);

        _transfer(msg.sender, address(this), totalPrice);

        for (uint i=0; i< _numTickets; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i)))%10000;
            Tickets(user_contract[msg.sender]).mintTicket(msg.sender, random);
            purchasedTickets.push(random);
            ticketID_user[random]=msg.sender;
            user_ticketID[msg.sender].push(random);
        }

    }
    function viewTickets(address _owner) public view returns (uint[]memory){
        return user_ticketID[_owner];
    }

    function generateWinner() public onlyOwner {
    uint len = purchasedTickets.length;
    require(len > 0);

    uint random = uint(keccak256(abi.encodePacked(block.timestamp)))%len;

    uint win = purchasedTickets[random];
    winnerAddress = ticketID_user[win];

    payable(winnerAddress).transfer(address(this).balance*80/100);  // el ganador recibe el 80 % del balance del contrato 
    payable(owner()).transfer(address(this).balance);       // y el 20% restante se va para el owner 
}


}

contract NFTs is ERC721 {
    address public lotteryContract;
    constructor() ERC721("ConquerTicket", "TCNQ"){
        lotteryContract = msg.sender;
    }

    function safeMint(address _owner, uint _ticketID) public {
        require(msg.sender == Lottery(lotteryContract).usersInfo(_owner), "You dont have access");
        _safeMint(_owner, _ticketID);
    } 
}

contract Tickets {
    struct Data {
        address owner; 
        address lotteryContract;
        address NFTContract; 
        address userContract;
    }

    Data public userData;

    constructor(address _owner, address _lotteryContract, address _NFTContract){
        userData = Data (_owner, _lotteryContract, _NFTContract, address(this));
    }

    function mintTicket(address _owner, uint _ticketID) public {
        require(msg.sender == userData.lotteryContract, "You dont have permissions");
        NFTs(userData.NFTContract).safeMint(_owner,_ticketID);
    }
}