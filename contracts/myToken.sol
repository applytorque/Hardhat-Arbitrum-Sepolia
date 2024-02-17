// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Corrected import paths
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdvancedAntiSnipeBotToken is ERC20, ReentrancyGuard, Ownable {
    uint256 public maxTxAmount;
    mapping(address => uint256) private lastTxTime;
    mapping(address => uint256) private buyAttempts;
    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private isWhitelisted;
    uint256 private cooldownTime;
    bool public tradeOn;
    uint256 public maxSupply;
    uint256 public burnRate;
    address public uniswapPair;

    constructor() ERC20("AdvancedAntiSnipeBotToken", "AASBT") Ownable(msg.sender) {
        maxSupply = 1000000 * 10**18; // Max supply of 1,000,000 tokens
        burnRate = 10; // Initial burn rate of 0.00001% of the transaction
        _mint(msg.sender, maxSupply); // Mint the max supply to deployer
        maxTxAmount = 10000 * 10**18; // Set max transaction amount to 10,000 tokens
        cooldownTime = 30 seconds; // Set cooldown time to 30 seconds
        tradeOn = true; // Set trade mode to on by default
    }

   function transferInternal(
    address from,
    address to,
    uint256 amount
) internal nonReentrant {
    require(tradeOn || isWhitelisted[from], "Trading is currently disabled.");
    require(!isBlacklisted[from], "Sender is blacklisted.");
    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
    require(block.timestamp >= lastTxTime[from] + cooldownTime, "Cooldown period not met.");
    require(block.timestamp >= lastTxTime[to] + cooldownTime, "Cooldown period not met.");

    if (to == uniswapPair) {
        buyAttempts[from]++;
        if (buyAttempts[from] > 3) {
            isBlacklisted[from] = true;
        }
    }

    uint256 burnAmount = (amount * burnRate) / 10000000; // Calculate burn amount
    uint256 transferAmount = amount - burnAmount; // Adjust transfer amount

    if (to == 0x000000000000000000000000000000000000dEaD) {
        // Burn tokens by subtracting from total supply
        _burn(from, burnAmount);
        emit Transfer(from, address(0), burnAmount);
    } else {
        // Transfer tokens to recipient
        super._transfer(from, to, transferAmount);
    }

    lastTxTime[from] = block.timestamp;
    lastTxTime[to] = block.timestamp;
}


    // Admin functions
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Minting would exceed max supply");
        _mint(to, amount);
    }

    function setUniswapPair(address _uniswapPair) external onlyOwner {
        uniswapPair = _uniswapPair;
    }

    function setBurnRate(uint256 _burnRate) external onlyOwner {
        burnRate = _burnRate;
    }

    function toggleTradeMode() external onlyOwner {
        tradeOn = !tradeOn;
    }

    function blacklistAddress(address _address, bool _value) external onlyOwner {
        isBlacklisted[_address] = _value;
    }

    function whitelistAddress(address _address, bool _value) external onlyOwner {
        isWhitelisted[_address] = _value;
    }

    function updateMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function updateCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
    }
}
