// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EvoxPreSaleV1
 * @dev $Evox TokenPreSale contract V1
 * @notice This contract facilitates the sale of $Evox tokens.
 */
contract EvoxPreSale is ReentrancyGuard {
    // SafeERC20 is a library from OpenZeppelin Contracts, ensuring safe ERC20 token transfers.
    using SafeERC20 for IERC20;

    // ChainLink BNB-USD price feed.
    AggregatorV3Interface internal priceFeed;

    // Evox token contract instance.
    IERC20 constant EvoxToken =
        IERC20(0x746F40b5B32FaFF8d89f4624B84a7b70ECfb1659);

    // USDT token contract instance.
    IERC20 constant usdtToken =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

   
   

    // USDC token contract instance.
    IERC20 constant usdcToken =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // Evox company's fund wallet address.
    address constant evoxCompanyFundWallet =
        0xF8c6D7E3fAcbd67C687eD6d1F9499E98eEed7e19;

    // Admin address.
    address constant admin = 0xC523bed68D08dbC411edE8ffBE4A9444eA19488C;

    // Evox token price in USD denominated in wei.
    uint constant EvoxUSDPriceInWei = 320000000000000000; // $0.32

    // Tolerance percentage for BNB price fluctuations to buy Evox.
    uint constant ethPriceTolerance = 5; // 5%

    // Lockup period for Evox tokens before users can claim purchased tokens, measured in days.
    uint constant tokenLockupPeriodDays = 390; // 390 days

    // Timestamp indicating the start time of the token sale.
    uint immutable startTime;

    // Timestamp marking the end time of the token sale.
    uint immutable endTime;

    // This variable represents the total amount of Evox tokens deposited by the admin, denominated in wei.
    uint totalDepositedEvoxTokenByAdmin = 0;

    // This variable represents the total amount of Evox tokens withdraw by the admin, denominated in wei.
    uint totalWithdrawEvoxTokenByAdmin = 0;

    // Minimum amount of Evox tokens that a user can buy, denominated in wei.
    uint minBuyEvoxInWei = 30000000000000000000; // 30 Evox

    // Maximum amount of Evox tokens that a user can buy, denominated in wei.
    uint maxBuyEvoxInWei = 20000000000000000000000; // 20,000 Evox

    // Total amount of Evox tokens bought by users, measured in wei.
    uint totalBoughtEvoxInWei = 0;

    // Flag indicating whether the token sale is active.
    bool isTokenSaleActive = true;

    // Flag indicating whether buying tokens with BNB (Binance Coin) is enabled.
    bool enableBuyWithETH = true;

    // Flag indicating whether buying tokens with USDT (Tether) is enabled.
    bool enableBuyWithUSDT = true;

    // Flag indicating whether buying tokens with Binance-Peg BUSD Token (BUSD) is enabled.

    // Flag indicating whether buying tokens with Binance-Peg USD Coin (USDC) is enabled.
    bool enableBuyWithUSDC = true;

    // Struct to represent vesting details for each user.
    struct Vesting {
        // Total amount of Evox tokens bought by the user, denominated in wei.
        uint totalBoughtEvox;
        // Duration in days for which the tokens are locked up before they can be claimed.
        uint lockupPeriod;
        // Cumulative amount of Evox tokens claimed by the user up to the current point in time.
        uint totalClaimed;
    }

    // Struct to hold all the details of the token sale.
    struct TokenSaleDetails {
        uint startTime;
        uint endTime;
        bool isTokenSaleActive;
        uint EvoxUSDPriceInWei;
        uint minBuyEvoxInWei;
        uint maxBuyEvoxInWei;
        uint tokenLockupPeriodDays;
        uint contractEvoxBalance;
        uint totalBoughtEvoxInWei;
        uint remainingEvoxTokensToSell;
        bool enableBuyWithETH;
        bool enableBuyWithUSDT;
        bool enableBuyWithUSDC;
    }

    // Mapping to associate each user's address with their Vesting details.
    mapping(address => Vesting) userVesting;

    // Event emitted when the value of the minBuyEvoxInWei is updated.
    event MinBuyEvoxInWeiUpdated(uint indexed newMinBuyEvoxInWei);

    // Event emitted when the value of the maxBuyEvoxInWei is updated.
    event MaxBuyEvoxInWeiUpdated(uint indexed newMaxBuyEvoxInWei);

    // Event emitted when the status of the tokenSale is updated.
    event TokenSaleStatusUpdated(bool indexed newStatus);

    // Event emitted when a buyer purchases Evox tokens with BNB.
    event EvoxBoughtWithETH(
        address indexed buyer,
        uint amountETH,
        uint amountEvox
    );

    // Event emitted when a buyer purchases Evox tokens with USDT.
    event EvoxBoughtWithUSDT(
        address indexed buyer,
        uint amountUSDT,
        uint amountEvox
    );

    // Event emitted when a buyer purchases Evox tokens with BUSD.
    event EvoxBoughtWithBUSD(
        address indexed buyer,
        uint amountBUSD,
        uint amountEvox
    );

    // Event emitted when a buyer purchases Evox tokens with USDC.
    event EvoxBoughtWithUSDC(
        address indexed buyer,
        uint amountUSDC,
        uint amountEvox
    );

    // Event emitted when a user successfully claims their Evox tokens after the lockup period.
    event EvoxTokensClaimed(address indexed recipient, uint amountEvox);

    // Event emitted when the admin withdraws the remaining Evox tokens after the tokenSale has ended.
    event RemainingEvoxTokensWithdrawByAdmin(
        address indexed withdrawAddress,
        uint withdrawAmount
    );

    // Event emitted when the admin withdraws the contract's BNB balance.
    event ContractBalanceWithdrawnByAdmin(
        address indexed recipient,
        uint amount
    );

    // Event emitted when the option to buy tokens with BNB (Binance Coin) is enabled or disabled.
    event BuyWithETHUpdated(bool isEnabled);

    // Event emitted when the option to buy tokens with USDT (Tether) is enabled or disabled.
    event BuyWithUSDTUpdated(bool isEnabled);

    // Event emitted when the option to buy tokens with Binance-Peg BUSD Token (BUSD) is enabled or disabled.
    event BuyWithBUSDUpdated(bool isEnabled);

    // Event emitted when the option to buy tokens with Binance-Peg USD Coin (USDC) is enabled or disabled.
    event BuyWithUSDCUpdated(bool isEnabled);

    // Event emitted when the admin deposits Evox tokens into the contract.
    event EvoxTokensDepositedByAdmin(address indexed admin, uint EvoxAmount);

    // Event emitted when the ChainLink price feed contract address is updated.
    event PriceFeedContractAddressUpdated(address indexed newAddress);

    constructor(uint _startTime, uint _endTime) {
        startTime = _startTime;
        endTime = _endTime;
        priceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
    }

    // Modifier to restrict access exclusively to the admin.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // Modifier to make a function callable only when the token sale is active, started, and not ended.
    modifier tokenSaleActive() {
        require(isTokenSaleActive, "TokenSale is not active");
        require(
            startTime <= block.timestamp,
            "The token sale has not yet begun"
        );
        require(endTime > block.timestamp, "The token sale has ended");
        _;
    }

    // Allows the admin to deposit a specified amount of Evox tokens into the contract.
    function depositEvoxTokensByAdmin(uint _EvoxAmount) external onlyAdmin {
        uint contractAllowance = EvoxToken.allowance(msg.sender, address(this));
        require(contractAllowance >= _EvoxAmount, "Not enough allowance");

        EvoxToken.safeTransferFrom(msg.sender, address(this), _EvoxAmount);

        totalDepositedEvoxTokenByAdmin += _EvoxAmount;

        emit EvoxTokensDepositedByAdmin(msg.sender, _EvoxAmount);
    }

    // Function to purchase Evox tokens with Binance coin (BNB).
    function buyEvoxWithETH()
        external
        payable
        tokenSaleActive
        nonReentrant
        returns (bool)
    {
        require(enableBuyWithETH, "Not allowed to buy with ETH");

        require(msg.value > 0, "Invalid ETH amount");

        uint EvoxInWei = getEvoxInWeiBasedOnETHAmount(msg.value);
        require(
            EvoxInWei >=
                minBuyEvoxInWei - ((minBuyEvoxInWei * ethPriceTolerance) / 100),
            "Evox amount is below minimum"
        );
        require(
            EvoxInWei <=
                maxBuyEvoxInWei + ((minBuyEvoxInWei * ethPriceTolerance) / 100),
            "Evox amount exceeds maximum"
        );

        require(
            getRemainingEvoxTokensToSell() >= EvoxInWei,
            "Insufficient Evox tokens available for sale"
        );

        require(
            userVesting[msg.sender].totalBoughtEvox + EvoxInWei <=
                maxBuyEvoxInWei,
            "Evox amount exceeds maximum"
        );

        (bool success, ) = payable(evoxCompanyFundWallet).call{
            value: msg.value
        }("");
        require(success, "ETH Payment failed");

        if (userVesting[msg.sender].totalBoughtEvox > 0) {
            userVesting[msg.sender].totalBoughtEvox += EvoxInWei;
        } else {
            userVesting[msg.sender] = Vesting(
                EvoxInWei,
                block.timestamp + (tokenLockupPeriodDays * 1 days),
                0
            );
        }

        totalBoughtEvoxInWei += EvoxInWei;

        emit EvoxBoughtWithETH(msg.sender, msg.value, EvoxInWei);

        return true;
    }

    // Function allowing the purchase of Evox tokens with Tether (USDT).
    function buyEvoxWithUSDT(
        uint _usdtAmountInWei
    ) external tokenSaleActive nonReentrant returns (bool) {
        require(enableBuyWithUSDT, "Not allowed to buy with USDT");

        require(_usdtAmountInWei > 0, "Invalid USDT amount");

        uint EvoxInWei = getEvoxInWeiBasedOnUSDTAmount(_usdtAmountInWei);
        require(EvoxInWei >= minBuyEvoxInWei, "Evox amount is below minimum");
        require(EvoxInWei <= maxBuyEvoxInWei, "Evox amount exceeds maximum");

        require(
            getRemainingEvoxTokensToSell() >= EvoxInWei,
            "Insufficient Evox tokens available for sale"
        );

        require(
            userVesting[msg.sender].totalBoughtEvox + EvoxInWei <=
                maxBuyEvoxInWei,
            "Evox amount exceeds maximum"
        );

        uint contractAllowance = usdtToken.allowance(msg.sender, address(this));
        require(
            contractAllowance >= _usdtAmountInWei,
            "Make sure to add enough allowance"
        );

        require(
            usdtToken.balanceOf(msg.sender) >= _usdtAmountInWei,
            "Insufficient USDT balance"
        );

        usdtToken.safeTransferFrom(
            msg.sender,
            evoxCompanyFundWallet,
            _usdtAmountInWei
        );

        if (userVesting[msg.sender].totalBoughtEvox > 0) {
            userVesting[msg.sender].totalBoughtEvox += EvoxInWei;
        } else {
            userVesting[msg.sender] = Vesting(
                EvoxInWei,
                block.timestamp + (tokenLockupPeriodDays * 1 days),
                0
            );
        }

        totalBoughtEvoxInWei += EvoxInWei;

        emit EvoxBoughtWithUSDT(msg.sender, _usdtAmountInWei, EvoxInWei);

        return true;
    }

    // Function allowing the purchase of Evox tokens with Binance-Peg BUSD Token (BUSD).
    
    // Function allowing the purchase of Evox tokens with Binance-Peg USD Coin (USDC).
    function buyEvoxWithUSDC(
        uint _usdcAmountInWei
    ) external tokenSaleActive nonReentrant returns (bool) {
        require(enableBuyWithUSDC, "Not allowed to buy with USDC");

        require(_usdcAmountInWei > 0, "Invalid USDC amount");

        uint EvoxInWei = getEvoxInWeiBasedOnUSDTAmount(_usdcAmountInWei);
        require(EvoxInWei >= minBuyEvoxInWei, "Evox amount is below minimum");
        require(EvoxInWei <= maxBuyEvoxInWei, "Evox amount exceeds maximum");

        require(
            getRemainingEvoxTokensToSell() >= EvoxInWei,
            "Insufficient Evox tokens available for sale"
        );

        require(
            userVesting[msg.sender].totalBoughtEvox + EvoxInWei <=
                maxBuyEvoxInWei,
            "Evox amount exceeds maximum"
        );

        uint contractAllowance = usdcToken.allowance(msg.sender, address(this));
        require(
            contractAllowance >= _usdcAmountInWei,
            "Make sure to add enough allowance"
        );

        require(
            usdcToken.balanceOf(msg.sender) >= _usdcAmountInWei,
            "Insufficient USDC balance"
        );

        usdcToken.safeTransferFrom(
            msg.sender,
            evoxCompanyFundWallet,
            _usdcAmountInWei
        );

        if (userVesting[msg.sender].totalBoughtEvox > 0) {
            userVesting[msg.sender].totalBoughtEvox += EvoxInWei;
        } else {
            userVesting[msg.sender] = Vesting(
                EvoxInWei,
                block.timestamp + (tokenLockupPeriodDays * 1 days),
                0
            );
        }

        totalBoughtEvoxInWei += EvoxInWei;

        emit EvoxBoughtWithUSDC(msg.sender, _usdcAmountInWei, EvoxInWei);

        return true;
    }

    // Function permitting the claiming of Evox tokens once the lockup period has elapsed.
    function claimEvoxTokens() external nonReentrant {
        require(
            userVesting[msg.sender].totalBoughtEvox > 0,
            "Nothing to claim"
        );
        require(userVesting[msg.sender].totalClaimed == 0, "Already claimed");
        require(
            userVesting[msg.sender].lockupPeriod <= block.timestamp,
            "Lockup period has not ended yet"
        );

        userVesting[msg.sender].totalClaimed = userVesting[msg.sender]
            .totalBoughtEvox;

        EvoxToken.safeTransfer(
            msg.sender,
            userVesting[msg.sender].totalBoughtEvox
        );

        emit EvoxTokensClaimed(
            msg.sender,
            userVesting[msg.sender].totalBoughtEvox
        );
    }

    // This function retrieves essential details about the token sale, providing a comprehensive overview of the token sale parameters and status.
    function getTokenSaleDetails()
        external
        view
        returns (TokenSaleDetails memory)
    {
        return
            TokenSaleDetails({
                startTime: startTime,
                endTime: endTime,
                isTokenSaleActive: isTokenSaleActive,
                EvoxUSDPriceInWei: EvoxUSDPriceInWei,
                minBuyEvoxInWei: minBuyEvoxInWei,
                maxBuyEvoxInWei: maxBuyEvoxInWei,
                tokenLockupPeriodDays: tokenLockupPeriodDays,
                contractEvoxBalance: EvoxToken.balanceOf(address(this)),
                totalBoughtEvoxInWei: totalBoughtEvoxInWei,
                remainingEvoxTokensToSell: getRemainingEvoxTokensToSell(),
                enableBuyWithETH: enableBuyWithETH,
                enableBuyWithUSDT: enableBuyWithUSDT,
                enableBuyWithUSDC: enableBuyWithUSDC
            });
    }

    // Function to get the remaining Evox tokens available for sale, represented in wei.
    function getRemainingEvoxTokensToSell() internal view returns (uint) {
        if (totalBoughtEvoxInWei > totalDepositedEvoxTokenByAdmin) {
            return 0;
        } else {
            return totalDepositedEvoxTokenByAdmin - totalBoughtEvoxInWei;
        }
    }

    // Function to get the user vesting details.
    function getUserVetsingDetails(
        address userAddr
    )
        external
        view
        returns (uint _totalBoughtEvox, uint _totalClaimed, uint _lockupPeriod)
    {
        Vesting memory vestingInfo = userVesting[userAddr];
        _totalBoughtEvox = vestingInfo.totalBoughtEvox;
        _totalClaimed = vestingInfo.totalClaimed;
        _lockupPeriod = vestingInfo.lockupPeriod;

        return (_totalBoughtEvox, _totalClaimed, _lockupPeriod);
    }

    // Function to get the maximum amount of Evox tokens a user can purchase.
    // It subtracts the total amount of Evox tokens already bought by the user from the maximum allowed purchase limit.
    function getMaxEvoxTokenCanUserBuy(
        address userAddr
    ) external view returns (uint) {
        uint maxEvoxTokenCanUserBuy = maxBuyEvoxInWei -
            userVesting[userAddr].totalBoughtEvox;
        if (getRemainingEvoxTokensToSell() < maxEvoxTokenCanUserBuy) {
            maxEvoxTokenCanUserBuy = getRemainingEvoxTokensToSell();
        }

        return maxEvoxTokenCanUserBuy;
    }

    // Function to get Evox in wei based on BNB amount in wei.
    // Converts a given amount of BNB in wei to an equivalent amount of Evox in wei.
    function getEvoxInWeiBasedOnETHAmount(
        uint _bnbAmountInWei
    ) public view returns (uint) {
        uint EvoxInWei = (_bnbAmountInWei * getETHPrice()) / EvoxUSDPriceInWei;

        return EvoxInWei;
    }

    // Function to get Evox in wei based on USDT amount in wei.
    // Converts a given amount of USDT in wei to an equivalent amount of Evox in wei.
    function getEvoxInWeiBasedOnUSDTAmount(
        uint _usdtAmountInWei
    ) public pure returns (uint) {
        uint EvoxInWei = (_usdtAmountInWei * 10 ** 18) / EvoxUSDPriceInWei;

        return EvoxInWei;
    }

    // Function to get BNB in wei based on Evox amount in wei.
    // Converts a given amount of Evox in wei to an equivalent amount of BNB in wei.
    function getETHInWeiBasedOnEvoxAmount(
        uint _EvoxAmountInWei
    ) public view returns (uint) {
        uint bnbInWei = (getUSDTInWeiBasedOnEvoxAmount(_EvoxAmountInWei) *
            10 ** 18) / getETHPrice();

        return bnbInWei;
    }

    // Function to get USDT in wei based on Evox amount in wei.
    // Converts a given amount of Evox in wei to an equivalent amount of USDT in wei.
    function getUSDTInWeiBasedOnEvoxAmount(
        uint _EvoxAmountInWei
    ) public pure returns (uint) {
        uint usdtInWei = (_EvoxAmountInWei * EvoxUSDPriceInWei) / 10 ** 18;

        return usdtInWei;
    }

    // Function to update the minimum buy amount of Evox in wei.
    // Allows only the admin to update the minimum buy amount of Evox, specified in wei.
    function updateMinBuyEvoxInWei(uint _minBuyEvoxInWei) external onlyAdmin {
        minBuyEvoxInWei = _minBuyEvoxInWei;
        emit MinBuyEvoxInWeiUpdated(_minBuyEvoxInWei);
    }

    // Function to update the maximum buy amount of Evox in wei.
    // Allows only the admin to update the maximum buy amount of Evox, specified in wei.
    function updateMaxBuyEvoxInWei(uint _maxBuyEvoxInWei) external onlyAdmin {
        maxBuyEvoxInWei = _maxBuyEvoxInWei;
        emit MaxBuyEvoxInWeiUpdated(_maxBuyEvoxInWei);
    }

    // Function to update the token sale status.
    // Allows only the admin to update the token sale status, setting it to either active or inactive.
    function updateTokenSaleStatus(bool _status) external onlyAdmin {
        isTokenSaleActive = _status;
        emit TokenSaleStatusUpdated(_status);
    }

    // Function to allow the admin to withdraw the remaining Evox tokens.
    // Requires that the token sale is not currently active.
    function withdrawRemainingTokens(address _to) external onlyAdmin {
        require(!isTokenSaleActive, "The token sale is currently activated");

        require(_to != address(0), "Invalid recipient address");

        uint withdrawAmount = getRemainingEvoxTokensToSell() -
            totalWithdrawEvoxTokenByAdmin;
        require(withdrawAmount > 0, "Nothing to transfer");

        totalWithdrawEvoxTokenByAdmin += withdrawAmount;

        EvoxToken.safeTransfer(_to, withdrawAmount);

        emit RemainingEvoxTokensWithdrawByAdmin(_to, withdrawAmount);
    }

    // Function to allow the admin to withdraw the entire BNB balance of the contract and transfer it to the Evox company's fund wallet address.
    function withdrawContractBalance() external onlyAdmin {
        uint withdrawAmount = address(this).balance;
        require(withdrawAmount > 0, "Nothing to withdraw");

        (bool success, ) = payable(evoxCompanyFundWallet).call{
            value: withdrawAmount
        }("");
        require(success, "ETH Payment failed");

        emit ContractBalanceWithdrawnByAdmin(admin, withdrawAmount);
    }

    // Function to enable or disable buying tokens with BNB (Binance Coin).
    // Allows only the admin to update the status.
    function buyWithETHUpdateStatus(bool _isEnabled) external onlyAdmin {
        enableBuyWithETH = _isEnabled;
        emit BuyWithETHUpdated(_isEnabled);
    }

    // Function to enable or disable buying tokens with USDT (Tether).
    // Allows only the admin to update the status.
    function buyWithUSDTUpdateStatus(bool _isEnabled) external onlyAdmin {
        enableBuyWithUSDT = _isEnabled;
        emit BuyWithUSDTUpdated(_isEnabled);
    }

    // Function to enable or disable buying tokens with Binance-Peg BUSD Token (BUSD).
    // Allows only the admin to update the status.
    // function buyWithBUSDUpdateStatus(bool _isEnabled) external onlyAdmin {
    //     enableBuyWithBUSD = _isEnabled;
    //     emit BuyWithBUSDUpdated(_isEnabled);
    // }

    // Function to enable or disable buying tokens with Binance-Peg USD Coin (USDC).
    // Allows only the admin to update the status.
    function buyWithUSDCUpdateStatus(bool _isEnabled) external onlyAdmin {
        enableBuyWithUSDC = _isEnabled;
        emit BuyWithUSDCUpdated(_isEnabled);
    }

    // Allows the admin to update the address of the ChainLink price feed contract.
    function updatePriceFeedContractAddress(
        address _newPriceFeedAddress
    ) external onlyAdmin {
        priceFeed = AggregatorV3Interface(_newPriceFeedAddress);
        emit PriceFeedContractAddressUpdated(_newPriceFeedAddress);
    }

    // Function to get the BNB price.
    function getETHPrice() internal view returns (uint) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        price = (price * (10 ** 10));

        return uint(price);
    }

    // Function to receive BNB. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
