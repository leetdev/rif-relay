// SPDX-License-Identifier:MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IForwarder.sol";
import "../utils/RSKAddrValidator.sol";

/* solhint-disable no-inline-assembly */
/* solhint-disable avoid-low-level-calls */

contract SimpleSmartWallet is IForwarder {
    using ECDSA for bytes32;

    bytes32 public currentVersionHash;
    uint256 public override nonce;
    

    /**It will only work if called through Enveloping */
    function setVersion(bytes32 versionHash) public {
       
        require(
            address(this) == msg.sender,
            "Caller must be the SmartWallet"
        );        
        
        currentVersionHash = versionHash;
    }

    function verify(
        bytes32 domainSeparator,
        bytes32 suffixData,
        ForwardRequest memory req,
        bytes calldata sig
    ) external override view {

        _verifySig(domainSeparator, suffixData, req, sig);
    }

    function getOwner() private view returns (bytes32 owner){
        assembly {
            owner := sload(
                0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a
            )
        }
    }
    

    function directExecute(address to, bytes calldata data) external override payable returns (
            bool success,
            bytes memory ret  
        )
    {

        //Verify Owner
        require(
            getOwner() == keccak256(abi.encodePacked(msg.sender)),
            "Not the owner of the SmartWallet"
        );

        (success, ret) = to.call{value: msg.value}(data);

        //If any balance has been added then trasfer it to the owner EOA
        if (address(this).balance > 0) {
            //can't fail: req.from signed (off-chain) the request, so it must be an EOA...
            payable(msg.sender).transfer(address(this).balance);
        }
   
    }
    
    function execute(
        bytes32 domainSeparator,
        bytes32 suffixData,
        ForwardRequest memory req,
        bytes calldata sig
    )
        external
        override
        payable
        returns (
            bool success,
            bytes memory ret  
        )
    {

        (sig);
        require(msg.sender == req.relayHub, "Invalid caller");

        _verifySig(domainSeparator, suffixData, req, sig);
        nonce++;

        if(req.tokenContract != address(0)){
            /* solhint-disable avoid-tx-origin */
            (success, ret) = req.tokenContract.call(
                abi.encodeWithSelector(
                    hex"a9059cbb", 
                    tx.origin,
                    req.tokenAmount
                )
            );

            require(
                success && (ret.length == 0 || abi.decode(ret, (bool))),
                "Unable to pay for relay"
            );
        }
            (success, ret) = req.to.call{gas: req.gas, value: req.value}(req.data);
     
            //If any balance has been added then trasfer it to the owner EOA
            uint256 balance = address(this).balance;
            if ( balance > 0) {
                //can't fail: req.from signed (off-chain) the request, so it must be an EOA...
                payable(req.from).transfer(balance);
            }
  
    }

   

    function getChainID() private pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _verifySig(
        bytes32 domainSeparator,
        bytes32 suffixData,
        ForwardRequest memory req,
        bytes memory sig
    ) private view {

        //Verify Owner
        require(
            getOwner() == keccak256(abi.encodePacked(req.from)),
            "Not the owner of the SmartWallet"
        );

        //Verify nonce
        require(nonce == req.nonce, "nonce mismatch");

        require(
            keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), //hex"8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f",
                keccak256("RSK Enveloping Transaction"), //DOMAIN_NAME hex"d41b7f69f4d7734774d21b5548d74704ad02f9f1545db63927a1d58479c576c8"
                currentVersionHash,
                getChainID(),
                address(this))) == domainSeparator,
            "Invalid domain separator"
        );
        
        require(
            RSKAddrValidator.safeEquals(
                keccak256(abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(_getEncoded(suffixData, req)))
                ).recover(sig), req.from), "signature mismatch"
        );
    }

    function _getEncoded(
        bytes32 suffixData,
        ForwardRequest memory req
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                keccak256("RelayRequest(address relayHub,address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,address tokenContract,uint256 tokenAmount,RelayData relayData)RelayData(uint256 gasPrice,bytes32 domainSeparator,address relayWorker,address callForwarder,address callVerifier)"), //requestTypeHash,
                abi.encode(
                    req.relayHub,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data),
                    req.tokenContract,
                    req.tokenAmount               
                ),
                suffixData
            );
    }

    function isInitialized() external view returns (bool) {
        
        if (getOwner() == bytes32(0)) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * This Proxy will first charge for the deployment and then it will pass the
     * initialization scope to the wallet logic.
     * This function can only be called once, and it is called by the Factory during deployment
     * @param owner - The EOA that will own the smart wallet
     * @param tokenAddr - The Token used for payment of the deploy
     * @param versionHash - The version of the domain separator to be used
     * @param transferData - payment function and params to use when calling the Token.
     * sizeof(transferData) = transfer(4) + _to(20) + _value(32) = 56 bytes = 0x38
     */

    function initialize(
        address owner,
        address tokenAddr,
        bytes32 versionHash,
        bytes memory transferData
    ) external  {

        require(getOwner() == bytes32(0), "already initialized");

        //Set the owner of this Smart Wallet
        //slot for owner = bytes32(uint256(keccak256('eip1967.proxy.owner')) - 1) = a7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a
        bytes32 ownerCell = keccak256(abi.encodePacked(owner));

        assembly {
            sstore(
                0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a,
                ownerCell
            )
        }

        //we need to initialize the contract
        if (tokenAddr != address(0)) {
            (bool success, bytes memory ret ) = tokenAddr.call(transferData);
            require(
            success && (ret.length == 0 || abi.decode(ret, (bool))),
            "Unable to pay for deployment");
        }

        currentVersionHash = versionHash;
    }

/* solhint-disable no-empty-blocks */
    receive() payable external  {
        
    }
}
