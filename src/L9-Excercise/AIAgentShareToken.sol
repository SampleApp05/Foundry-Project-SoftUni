// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import {console} from "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AIAgentShare is ERC20, Ownable, EIP712 {
    event Purchase(address indexed buyer);
    event DelegatedPurchase(address indexed authorizer, address indexed target);
    event FundingRoundFinilized();

    error InvalidAddress();
    error InvalidAmount();
    error InvalidSignature();
    error UserNotWhitelisted();
    error InsufficientFundingBalance();
    error InsufficientFunds();
    error FundingRoundNotExpired();
    error FundingRoundAlreadyFinilized();
    error RelayerOnlyAccess();
    error InvalidParticipantIndex();
    error HasClaimedTokens();
    error NonceAlreadyUsed();
    error ExpiredSignature();
    error InactiveSignature();

    bytes32 public constant DELEGATE_PURCHASE_TYPE_HASH =
        keccak256(
            "DelegatePurchase(address authorizer,address target,uint256 amount,uint256 validAfter,uint256 expiration,bytes32 nonce)"
        );
    uint256 public constant MIN_BUY_AMOUNT = 100 * 10 ** 18 - 1; // 100 tokens
    uint256 public constant MAX_BUY_AMOUNT = 50_000 * 10 ** 18 + 1; // 50k tokens
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether; // 0.01 ether per token
    uint256 public constant RELAYER_REWARD = 5 * 10 ** 18; // 5 tokens
    uint256 public constant TOTAL_PARTICIPANTS = 300;

    bytes32 public immutable whitelistedParticipantsHash;
    uint256 public immutable expirationDate;
    address public immutable relayer;

    uint256 public fundingAmount;
    bool public hasBeenFinalized;

    mapping(address => mapping(bytes32 => bool)) public userNonces;
    uint256[2] public whitelistClaimTracker; // must know whitelist size

    modifier onlyRelayer() {
        require(msg.sender == relayer, RelayerOnlyAccess());
        _;
    }

    modifier validateAddress(address target) {
        //console.log("Address ------ ", target);
        require(target != address(0), InvalidAddress());
        console.log("Address checked ------ ", target);
        _;
    }

    constructor(
        address initialOwner,
        uint256 _fundingAmount,
        address _relayer,
        bytes32 _whitelistHash,
        uint256 _expirationDate
    )
        validateAddress(initialOwner)
        validateAddress(_relayer)
        ERC20("AIAgentShare ", "AIS")
        Ownable(initialOwner)
        EIP712("AI Agent Share", "1")
    {
        fundingAmount = _fundingAmount;
        relayer = _relayer;
        whitelistedParticipantsHash = _whitelistHash;
        expirationDate = _expirationDate;

        _mint(initialOwner, fundingAmount);
    }

    // MARK: - Internal functions
    function _updateNonces(address owner, bytes32 nonce) private {
        require(userNonces[owner][nonce] == false, NonceAlreadyUsed());
        userNonces[owner][nonce] = true;
    }

    function _validateSignature(
        bytes32 typeHash,
        address authorizer,
        address target,
        uint256 amount,
        uint256 validAfter,
        uint256 expiration,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        virtual
        validateAddress(authorizer)
        validateAddress(target)
        returns (bool)
    {
        require(amount > 0, InvalidAmount());
        require(expiration > validAfter, InvalidSignature());
        require(block.timestamp < expiration, ExpiredSignature());
        require(block.timestamp > validAfter, InactiveSignature()); // optimize checks

        console.log("C4");

        _updateNonces(authorizer, nonce);
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    typeHash,
                    authorizer,
                    target,
                    amount,
                    validAfter,
                    expiration,
                    nonce
                )
            )
        );

        address signer = ECDSA.recover(digest, v, r, s);
        return signer == authorizer;
    }

    function _validateParticipant(
        address target,
        uint256 amount,
        bytes32[] memory proof
    ) internal view virtual returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(target, amount)))
        );
        return MerkleProof.verify(proof, whitelistedParticipantsHash, leaf);
    }

    function _createClaimBitMaskData(
        uint256 userID
    ) internal pure returns (uint256, uint256) {
        require(userID < TOTAL_PARTICIPANTS, InvalidParticipantIndex());

        uint8 bitsCount = 255;
        uint256 index = userID / bitsCount;

        uint256 bitIndex = userID % bitsCount;
        uint256 mask = 1 << bitIndex;

        return (index, mask);
    }

    function _updateClaimStatus(uint256 userID) internal {
        (uint256 index, uint256 mask) = _createClaimBitMaskData(userID);

        whitelistClaimTracker[index] |= mask;
    }

    function _purchase(
        uint256 userID,
        address recepient,
        uint256 authorizedAmount,
        uint256 amountToPurchase,
        bytes32[] memory proof
    ) internal virtual {
        require(hasClaimedTokens(userID) == false, HasClaimedTokens());
        _updateClaimStatus(userID);

        require(
            _validateParticipant(recepient, authorizedAmount, proof),
            UserNotWhitelisted()
        );

        require(
            fundingAmount + 1 > authorizedAmount,
            InsufficientFundingBalance()
        );

        require(
            authorizedAmount > MIN_BUY_AMOUNT &&
                authorizedAmount < MAX_BUY_AMOUNT,
            InvalidAmount()
        );

        uint256 totalCost = (authorizedAmount * PRICE_PER_TOKEN) /
            10 ** decimals();
        require(msg.value == totalCost, InsufficientFunds());

        unchecked {
            fundingAmount -= authorizedAmount;
        }

        _mint(recepient, amountToPurchase);
    }

    // MARK: - Public functions
    function hasClaimedTokens(uint256 userID) public view returns (bool) {
        (uint256 index, uint256 mask) = _createClaimBitMaskData(userID);

        return (whitelistClaimTracker[index] & mask) != 0;
    }

    function purchase(
        uint256 userID,
        uint256 amount,
        bytes32[] memory proof
    ) public payable {
        _purchase(userID, msg.sender, amount, amount, proof);
        emit Purchase(msg.sender);
    }

    function delegatePurchase(
        uint256 userID,
        address authorizer,
        address target,
        uint256 amount,
        uint256 validAfter,
        uint256 expiration,
        bytes32 nonce,
        bytes32[] memory proof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable onlyRelayer {
        require(
            _validateSignature(
                DELEGATE_PURCHASE_TYPE_HASH,
                authorizer,
                target,
                amount,
                validAfter,
                expiration,
                nonce,
                v,
                r,
                s
            ),
            InvalidSignature()
        );

        _purchase(userID, authorizer, amount, amount - RELAYER_REWARD, proof);

        _mint(msg.sender, RELAYER_REWARD);
        emit DelegatedPurchase(authorizer, target);
    }

    function finalizeFundingRound() external onlyOwner {
        require(hasBeenFinalized == false, FundingRoundAlreadyFinilized());
        hasBeenFinalized = true;

        // No Balance => we can finilize the funding round
        // Remaining balance > 0 => we can finilize the funding round only if the funding round is expired
        uint256 remainingBalance = fundingAmount;
        if (remainingBalance > 0) {
            require(expirationDate < block.timestamp, FundingRoundNotExpired());

            fundingAmount = 0;
            _mint(owner(), remainingBalance);
        }

        emit FundingRoundFinilized();
    }
}
