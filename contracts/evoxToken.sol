/**
 *Submitted for verification at BscScan.com on 2023-06-04
 */
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EvoxToken is Initializable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public presaleTokenPrice;
    uint256 public maxSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private constant MAX = ~uint256(0);

    uint256 private taxPercentage; // Tax percentage to be deducted on each transfer
    address public admin;
    address[] public tokenHolders;
    address public paymentToken;
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
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        maxSupply = _maxSupply * 10e18;
        totalSupply = _initialSupply * 10e18;
        balanceOf[msg.sender] = totalSupply;
        taxPercentage = _taxPercentage;
        presaleTokenPrice = 0.05 * 1e6;
        paymentToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        emit Transfer(address(0), msg.sender, totalSupply * 10e18);
        admin = msg.sender;
        owner = msg.sender;
        // Add initial token holder
        tokenHolders.push(msg.sender);
        tokenHolderIndex[msg.sender] = tokenHolders.length - 1;
        minTokenBuy = 1;
    }

    function addToBlacklist(address _address) external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        require(!blacklist[_address], "Address is already blacklisted");
        blacklist[_address] = true;
        emit AddedToBlacklist(_address);
    }
    function removeFromBlacklist(address _address) external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        require(blacklist[_address], "Address is not blacklisted");
        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }
     modifier notBlacklisted(address _address) {
        require(!blacklist[_address], "Address is blacklisted");
        _;
    }

    function setPaymentToken(address _paymentToken) external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        require(_paymentToken != address(0), "Invalid address");
        paymentToken = _paymentToken;
    }

    function setPaymentTokenPrice(uint256 _preSaleTokenPrice) external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        require(_preSaleTokenPrice != 0, "Price Cannot be zero");
        presaleTokenPrice = _preSaleTokenPrice;
    }

    function buy(uint256 amount) external notBlacklisted(msg.sender) {
        require(
            paymentReceiveWalletAddress != address(0),
            "Invalid payment Deposit address "
        );
        require(
            amount >= minTokenBuy * 1e18,
            "amount should be greater than Minimum token buy"
        );
        uint256 usdtBalance = IERC20(paymentToken).balanceOf(msg.sender);
        require(
            usdtBalance >= (amount / 1e18) * presaleTokenPrice,
            "Insufficent USDT balance"
        );
        IERC20(paymentToken).transferFrom(
            msg.sender,
            paymentReceiveWalletAddress,
            (amount / 1e18) * presaleTokenPrice
        );
        IERC20(address(this)).transfer(msg.sender, amount);
    }

    function sell(uint256 amount) external notBlacklisted(msg.sender) {
       
        uint256 mvBalance = IERC20(address(this)).balanceOf(msg.sender);
        require(mvBalance >= amount, "Insufficent MV balance");
        IERC20(address(this)).transferFrom(
            msg.sender,
            paymentReceiveWalletAddress,
            amount
        );
        IERC20(paymentToken).transfer(
            msg.sender,
            (amount / 1e18) * (presaleTokenPrice)
        );
    }

    function transfer(address _to, uint256 _value) external notBlacklisted(msg.sender) returns (bool) {
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

    function mint(uint256 _value) external notBlacklisted(msg.sender) {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        require(
            totalSupply + _value <= maxSupply,
            "Amount Exceed maximmum supply"
        );
        totalSupply = _value + totalSupply;
        balanceOf[msg.sender] = balanceOf[msg.sender] + _value;
    }

    function redistributeTax() external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
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

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external notBlacklisted(msg.sender) returns (bool) {
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

    function updateAdmin(address _newAdmin) external {
        require(msg.sender == owner, "Only owner can call this function");
        admin = _newAdmin;
    }

    function setPaymentReceiveWalletAddress(address walletAddress) external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        require(walletAddress != address(0), "Invalid address");
        paymentReceiveWalletAddress = walletAddress;
    }

    function setMinTokenBuy(uint256 amount) external {
        require(msg.sender == owner, "Only Owner Can Call This Function");
        minTokenBuy = amount;
    }
}
