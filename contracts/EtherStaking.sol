// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Etherstaking {
    struct Staker {
        uint256 stakingPeriodStart;
        uint256 amountStaked;
        uint256 stakingDurationInSeconds;
        uint256 reward;
    }

    event Stakesuccessful(address sender, uint amount);
    event rewardDepositSuccessful(address sender, uint amount);
    event withdrawalSuccessful(address receiver, uint amount);

    address public owner;
    uint256 public totalAmountStaked;
    uint256 public rewardPool;

    mapping(address => Staker) public stakers;

    constructor() payable  {
       owner = msg.sender; 
    }

    modifier onlyOwner (){
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    uint256 constant SCALING_FACTOR = 10**18;

    function depositReward () public payable onlyOwner{
        rewardPool += msg.value;
        emit rewardDepositSuccessful(msg.sender, msg.value);
    }

    function stakeEther( uint256 _durationInSeconds ) public payable{
        require(msg.value > 0, "Can't deposit lower than 0");
        require(msg.sender != address(0), "Address zero detected");
        require(rewardPool > 0, "Can't stake now");
        
        stakers[msg.sender].stakingPeriodStart = block.timestamp;
        stakers[msg.sender].amountStaked += msg.value;
        stakers[msg.sender].stakingDurationInSeconds += _durationInSeconds;


        totalAmountStaked += msg.value;

        uint256 _rewardFromTime = (_durationInSeconds * SCALING_FACTOR) / 10000;
        uint256 _rewardPerAmount = _rewardFromTime * msg.value;
        uint256 _rewardFromPool = (_rewardPerAmount * (rewardPool * SCALING_FACTOR)) / SCALING_FACTOR;

        uint256 finalReward = (_rewardFromPool / SCALING_FACTOR) / SCALING_FACTOR;

        rewardPool -= finalReward;

        stakers[msg.sender].reward += finalReward;  

        emit Stakesuccessful(msg.sender, finalReward );
    }

    function checkReward() public view returns (uint256){
        return stakers[msg.sender].reward;
    }

    function withdraw() public payable{
        require(msg.sender != address(0), "zero address detected");
        require( block.timestamp >= stakers[msg.sender].stakingPeriodStart + stakers[msg.sender].stakingDurationInSeconds, "You can't withdraw yet" );
        require(stakers[msg.sender].amountStaked > 0, "you didn't stake ether");

        uint256 amountToWithdraw = stakers[msg.sender].amountStaked + stakers[msg.sender].reward;

        payable(msg.sender).transfer(amountToWithdraw);
        emit withdrawalSuccessful(msg.sender, amountToWithdraw);
        stakers[msg.sender].amountStaked = 0;
        stakers[msg.sender].reward = 0;
        stakers[msg.sender].stakingPeriodStart = 0;
        stakers[msg.sender].stakingDurationInSeconds = 0;

        totalAmountStaked -= stakers[msg.sender].amountStaked;

    }

    function withdrawAllFromRewardpool() public payable onlyOwner{
        require(rewardPool > 0, "reward pool is empty");
        payable(msg.sender).transfer(address(this).balance);
    }
}
