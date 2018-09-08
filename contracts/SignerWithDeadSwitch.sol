pragma solidity ^0.4.24;

import "openzeppelin/SignerRole.sol";

contract SignerWithDeadSwitch is SignerRole {

    address private recoverer;
    uint    private finalizeAfter;

    constructor(address _recoverer) public {
        recoverer = _recoverer;
    }

    function initiateDeadSwitch(uint _finalizeAfter, bytes _recovererSig) public {
        require(_finalizeAfter > now + 6 * 30 days);
        require(recoverer == recover(keccak256(_finalizeAfter), _recovererSig));
        finalizeAfter = _finalizeAfter;
    }

    function finalizeDeadSwitch(address _newSigner, bytes _recovererSig) public {
        require(finalizeAfter > 0);
        require(now > finalizeAfter);
        require(recoverer == recover(keccak256(_newSigner, finalizeAfter), _recovererSig));
        _addSigner(committedSigner);
        finalizeAfter = 0;
    }

    function cancelDeadSwitch(address _newRecoverer) public onlySigner {
        require(_newRecoverer != recoverer); // to avoid malicious initiateDeadSwitch() calls via sig replay
        recoverer = _newRecoverer;
        finalizeAfter = 0;
    }

    function setRecoverer(address _recoverer) public onlySigner {
        recoverer = _recoverer;
    }

}
