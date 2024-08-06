// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EvoxToken is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public maxSupply;
    address public admin;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private constant MAX = ~uint256(0);

    uint256 private taxPercentage; // Tax percentage to be deducted on each transfer
    address[] public tokenHolders;
    mapping(address => uint256) public tokenHolderIndex;

    uint256 public totalTaxCollected;
    address public paymentReceiveWalletAddress;
    uint256 public minTokenBuy;
    mapping(address => bool) public blacklist;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _taxPercentage,
        uint256 _maxSupply,
        uint256 _initialSupply
    ) public initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        maxSupply = _maxSupply * 10e18;
        totalSupply = _initialSupply * 10e18;
        balanceOf[msg.sender] = totalSupply;
        taxPercentage = _taxPercentage;

        emit Transfer(address(0), msg.sender, totalSupply);
        admin = msg.sender;
        // Add initial token holder
        tokenHolders.push(msg.sender);
        tokenHolderIndex[msg.sender] = tokenHolders.length - 1;
        minTokenBuy = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function addToBlacklist(address _address) external onlyOwner {
        require(!blacklist[_address], "Address is already blacklisted");
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        require(blacklist[_address], "Address is not blacklisted");
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    modifier notBlacklisted(address _address) {
        require(!blacklist[_address], "Address is blacklisted");
        _;
    }

    function transfer(address _to, uint256 _value) external notBlacklisted(msg.sender) nonReentrant returns (bool) {
        require(_to != address(0), "Invalid recipient");
        require(_value > 0, "Invalid transfer amount");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        // Deduct tax from the transfer amount
        uint256 taxAmount = (_value * taxPercentage) / 100;
        uint256 transferAmount = _value - taxAmount;

        // Update sender and recipient balances
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;

        // Update tax collected
        totalTaxCollected += taxAmount / 2;

        // Check if the recipient is a new token holder
        if (balanceOf[_to] == transferAmount && tokenHolderIndex[_to] == 0) {
            tokenHolders.push(_to);
            tokenHolderIndex[_to] = tokenHolders.length - 1;
        }

        emit Transfer(msg.sender, _to, transferAmount);

        // Transfer tax amount to contract for redistribution
        if (taxAmount > 0) {
            balanceOf[admin] += taxAmount / 2;
            balanceOf[address(this)] += taxAmount / 2;
            emit Transfer(msg.sender, address(this), taxAmount / 2);
            emit Transfer(msg.sender, admin, taxAmount / 2);
        }

        return true;
    }

    function mint(uint256 _value) external onlyOwner notBlacklisted(msg.sender) {
        require(
            totalSupply + _value <= maxSupply,
            "Amount exceeds maximum supply"
        );
        totalSupply = _value + totalSupply;
        balanceOf[msg.sender] = balanceOf[msg.sender] + _value;
    }

    function redistributeTax() external onlyOwner nonReentrant {
        require(
            balanceOf[address(this)] > 0,
            "No tax available for redistribution"
        );
        require(tokenHolders.length > 0, "No token holders to redistribute to");

        uint256 taxAmount = balanceOf[address(this)];

        // Distribute tax amount among token holders
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            address account = tokenHolders[i];

            uint256 distributionAmount = (balanceOf[account] * taxAmount) /
                totalSupply;
            balanceOf[account] += distributionAmount;
            emit Transfer(address(this), account, distributionAmount);
        }

        // Reduce tax amount from contract balance
        balanceOf[address(this)] -= taxAmount;
        totalTaxCollected -= taxAmount;
    }

    function approve(address _spender, uint256 _value) external notBlacklisted(msg.sender) returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external notBlacklisted(msg.sender) nonReentrant returns (bool) {
        require(_to != address(0), "Invalid recipient");
        require(_value > 0, "Invalid transfer amount");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(
            allowance[_from][msg.sender] >= _value,
            "Insufficient allowance"
        );

        // Deduct tax from the transfer amount
        uint256 taxAmount = (_value * taxPercentage) / 100;
        uint256 transferAmount = _value - taxAmount;

        // Update sender, recipient, and spender balances
        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        allowance[_from][msg.sender] -= _value;

        // Update tax collected
        totalTaxCollected += taxAmount / 2;

        // Check if the recipient is a new token holder
        if (balanceOf[_to] == transferAmount && tokenHolderIndex[_to] == 0) {
            tokenHolders.push(_to);
            tokenHolderIndex[_to] = tokenHolders.length - 1;
        }

        emit Transfer(_from, _to, transferAmount);

        // Transfer tax amount to contract for redistribution
        if (taxAmount > 0) {
            balanceOf[admin] += taxAmount / 2;
            balanceOf[address(this)] += taxAmount / 2;
            emit Transfer(_from, address(this), taxAmount / 2);
            emit Transfer(_from, admin, taxAmount / 2);
        }

        return true;
    }

    function updateAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
    }
}
