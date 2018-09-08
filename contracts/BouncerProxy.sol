pragma solidity ^0.4.24;

import "openzeppelin/SignatureBouncer.sol";
import "SignerWithDeadSwitch.sol";

contract BouncerProxy is SignatureBouncer, SignerWithDeadSwitch {
  constructor() public { }
  //to avoid replay
  mapping(address => uint) public nonce;
  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  function () payable { emit Received(msg.sender, msg.value); }
  event Received (address indexed sender, uint value);
  // original forward function copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  function forward(bytes sig, address signer, address destination, uint value, bytes data, address rewardToken, uint rewardAmount) public {
      //the hash contains all of the information about the meta transaction to be called
      bytes32 _hash = keccak256(abi.encodePacked(address(this), signer, destination, value, data, rewardToken, rewardAmount, nonce[signer]++));
      //this makes sure signer signed correctly AND signer is a valid bouncer
      require(isValidDataHash(_hash,sig));
      //make sure the signer pays in whatever token (or ether) the sender and signer agreed to
      // or skip this if the sender is incentivized in other ways and there is no need for a token
      if(rewardToken==address(0)){
        //ignore reward, 0 means none
      }else if(rewardToken==address(1)){
        //REWARD ETHER
        require(msg.sender.call.value(rewardAmount).gas(36000)());
      }else{
        //REWARD TOKEN
        require((StandardToken(rewardToken)).transfer(msg.sender,rewardAmount));
      }
      //execute the transaction with all the given parameters
      require(executeCall(destination, value, data));
      emit Forwarded(sig, signer, destination, value, data, rewardToken, rewardAmount, _hash);
  }
  // when some frontends see that a tx is made from a bouncerproxy, they may want to parse through these events to find out who the signer was etc
  event Forwarded (bytes sig, address signer, address destination, uint value, bytes data,address rewardToken, uint rewardAmount,bytes32 _hash);

  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  // which was copied from GnosisSafe
  // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
  function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
    assembly {
       success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }
}

contract StandardToken {
  function transfer(address _to,uint256 _value) public returns (bool) { }
}
