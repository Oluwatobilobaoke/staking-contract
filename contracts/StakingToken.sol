// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingToken is ERC20, Ownable {

  using SafeMath for uint256;

  /*
    * get all token stake holders
   */
  address[] internal stakeholders;

  /*
    * get individual stakes
   */

  mapping(address => uint256) internal stakes;

  /*
    * get individual rewards
   */
  mapping(address => uint256) internal rewards;

  /*
    * get individual rewardTime
   */

  mapping(address => uint256) internal rewardTime;

  string public tokenName = "PheToken";
  string public tokenSymbol = "(Phe)";
  uint8 public tokenDecimals = 18;

  uint256 public _supply;

  uint256 public tokenPrice = 0.001 ether;
  uint256 public numberPerToken = 1000;
  address payable public _owner;

  event TokePriceUpdate(uint256 newPrice);
  event TokenStake(address _stakeholder, uint256 _amount);

  constructor() payable ERC20(tokenName, tokenSymbol) {
    _supply = 100000 * numberPerToken**tokenDecimals;
    _owner = payable(msg.sender);
    _mint(_owner, 1000 * 10**tokenDecimals);
  }



  // --------- TOKEN PURCHASE ---------

  

  function buyToken (address _receiver) public payable returns (bool) {
    require(msg.value >= 0, "You cannot mint (Phe) with zero ETH");
    (bool success, ) = _owner.call{value: msg.value}("");
    require(success, "Failed to send money");
    uint tokensToRecieve = msg.value * numberPerToken;
    _mint(_receiver, tokensToRecieve);
    return true;
  }

  function modifyTokenPrice(uint256 _newPrice) external onlyOwner {
    require(_newPrice > 0, "Price must be greater than zero");
    tokenPrice = _newPrice;
    uint rate = 1;
    numberPerToken = rate / tokenPrice;
    emit TokePriceUpdate(tokenPrice);
  }



  // --------- STAKEHOLDER ---------

  // check an address is stake holder
  function isStakeHolder(address _address) public view returns (bool, uint256) {
    for (uint256 s = 0; s < stakeholders.length; s += 1){
      if (_address == stakeholders[s]) return (true, s);
    }
    return (false, 0);
  }

  // add a stake holder
  function addStakeHolder(address _stakeholder) public {
    (bool _isStakeHolder, ) = isStakeHolder(_stakeholder);
    if(!_isStakeHolder) stakeholders.push(_stakeholder);
  }

  // remove a stake holder
  function removeStakeHolder(address _stakeholder) public {
    (bool _isStakeHolder, uint256 s) = isStakeHolder(_stakeholder);
    if(_isStakeHolder) {
      stakeholders[s] = stakeholders[stakeholders.length - 1];
      stakeholders.pop();
    }
  }


  // --------- STAKEs ---------

  // get stake of an address
  function stakeOf(address _stakeholder) public view returns (uint256) {
    return stakes[_stakeholder];
  }

  // get all total stakes
  function totalStakes() public view returns (uint256) {
    uint256 _totalStakes = 0;
    for (uint256 s = 0; s < stakeholders.length; s += 1){
      _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
    }
    return _totalStakes;
  }


  /*
    * create stakes
   */

  function createStake(uint _stake) public {
    // make sure it's greater than 0
    require(_stake > 0);
    _burn(msg.sender, _stake);
    // check if the person has a stake
    if(stakes[msg.sender] == 0) addStakeHolder(msg.sender);
    stakes[msg.sender] = stakes[msg.sender].add(_stake);
    rewardTime[msg.sender] = block.timestamp;
    distributeReward(msg.sender);
    emit TokenStake(msg.sender, _stake);
  }

  // remove stake
  function removeStake(uint _stake) public {
    // make sure it's greater than 0
    require(_stake > 0);
    // check if the person has a stake
    if(stakes[msg.sender] == 0) return;
    // make sure the inputed stake is less than the stake
    require(stakes[msg.sender] >= _stake);
    stakes[msg.sender] = stakes[msg.sender].sub(_stake);
    if(stakes[msg.sender] == 0) removeStakeHolder(msg.sender);
    _mint(msg.sender, _stake);
  }

  // --------- REWARDS ---------

  // get reward of an address
  function rewardOf(address _stakeholder) public view returns (uint256) {
    return rewards[_stakeholder];
  }

  // get all total rewards
  function totalRewards() public view returns (uint256) {
    uint256 _totalRewards = 0;
    for (uint256 s = 0; s < stakeholders.length; s += 1){
      _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
    }
    return _totalRewards;
  }

  // calculate rewards
  // stakerholder get 1% of their stake
  function calculateReward(address _stakeholder) public view returns (uint256) {
    uint256 _reward = 0;
    if(stakes[_stakeholder] > 0) {
      _reward = stakes[_stakeholder].mul(1).div(100);
    }
    return _reward;
  }

  // distribute rewards
  function distributeRewards() public onlyOwner {
    for (uint256 s = 0; s < stakeholders.length; s += 1){
      address stakeholder = stakeholders[s];

      // calculate each reward of each stakeholder
      uint256 _reward = calculateReward(stakeholder);

      // add to their rewards
      rewards[stakeholder] = rewards[stakeholder].add(_reward);
    }
  }

  function distributeReward(address _stakeholder) internal {
    uint256 _reward = calculateReward(_stakeholder);
    rewards[_stakeholder] = rewards[_stakeholder].add(_reward);
  }

  // claim rewards
  function claimReward() public {
    // check if the person has a reward
    if(rewards[msg.sender] == 0) return;

    if(block.timestamp >= rewardTime[msg.sender] + 7 days) {
      uint256 _rewardsToBeClaimed = rewards[msg.sender];
      _mint(msg.sender, _rewardsToBeClaimed);
      rewards[msg.sender] = 0;
      rewardTime[msg.sender] = block.timestamp;
    } else {
      rewards[msg.sender] = 0;
      require(false, "You cannot claim rewards until 7 days after the last reward");
    }
  }

}