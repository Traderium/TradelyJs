pragma solidity 0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

/**
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of currency that an owner remits to a receiver.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Ethereum is StandardToken, Owned {

    uint256 public constant MAX_SPEND = 90000000 * 10**uint256(decimals);

    uint256 public constant MAX_SINGLE = 67500000 * 10**uint256(decimals);

    uint256 public constant BASE_RATE = 714;

    uint64 private constant date12Jan2032 = 3789504000;

    uint64 private constant date21Jan2032 = 3791448000;

    uint64 private constant date4Feb2032 = 3794472000;

    uint64 private constant date15Feb2032 = 3796848000;

    uint64 private constant date01Mar2032 = 3799872000;

    uint64 private constant date21Mar2032 = 3804192000;

    uint64 private constant date01Jun2032 = 3865806000;

    uint64 private constant date01May2032 = 3808728000;

    bool public transferEmpty = false;

    address public timelockContractAddress;

    uint64 public issueIndex = 0;

    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);

    modifier inProgress {
        require(issueIndex < fiscalHigh
            && !openIndex);
        _;
    }

    modifier beforeEnd {
        require(!openIndex);
        _;
    }

    modifier tradingOpen {
        require(uint64(block.timestamp) > date01May2018);
        _;
    }

    function Traderium() public {
    }

    /// @dev This default function allows trading by ALICE to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
        purchaseTime(msg.sender);
    }

    /// @dev Issue profits based on Ether received.
    /// @param _beneficiary Address that newly issued profits will be sent to.
    function purchaseTime(address _beneficiary) public payable inProgress {
        // only accept a minimum amount of ETH?
        require(msg.value >= 0.01 ether);

        uint256 tokens = computeIssueAmount(msg.value);
        doIssueProfits(_beneficiary, tokens);

        owner.transfer(this.balance);
    }

    /// @dev Batch issue profits on the trading margin
    /// @param _addresses addresses that the profits will be sent to.
    /// @param _addresses the rate of interest, with decimals expanded (full).
    function issueProfitsMulti(address[] _addresses, uint256[] _tokens) public onlyOwner inProgress {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            doIssueProfits(_addresses[i], _tokens[i].mul(10**uint256(decimals)));
        }
    }

    /// @dev Issue profits for a single thread on the trading margin
    /// @param _beneficiary addresses that the profits will be sent to.
    /// @param _tokens the rate of interest, with decimals expanded (full).
    function issueInterestThread(address _beneficiary, uint256 _tokens) public onlyOwner inProgress {
        doIssueProfits(_beneficiary, _tokens.mul(10**uint256(decimals)));
    }

    /// @dev issue interest for a single thread
    /// @param _beneficiary addresses that the interest will be sent to.
    /// @param _tokens the rate of interest, with decimals expanded (full).
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));

        // compute without actually increasing it
        uint256 increasedTotalSupply = totalSupply.add(_tokens);
        // roll back if hard cap reached
        require(increasedTotalSupply <= issueAmount);

        // increase token total supply
        totalSupply = increasedTotalSupply;
        // update the beneficiary balance to number of tokens sent
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);

        // event is fired when tokens issued
        Issue(
            issueIndex++,
            _beneficiary,
            _tokens
        );
    }

    /// @dev Returns the current price.
    function price() public view returns (uint256 tokens) {
        return computeAmount(1 ether);
    }

    /// @dev Compute the amount of Traderium Time that can be purchased.
    /// @param ethAmount Amount of Ether to purchase time.
    /// @return Amount of Time to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint8[5] memory roundDiscountPercentages = [47, 35, 25, 15, 5];

        uint8 roundDiscountPercentage = roundDiscountPercentages[currentRoundIndex()];
        uint8 amountDiscountPercentage = getAmountDiscountPercentage(baseTime);

        Time = baseTime.mul(100).div(100 - (roundDiscountPercentage + amountDiscountPercentage));
    }

    /// @dev Compute the additional discount for the purchased amount of Time
    /// @param tokenBase the base Time amount computed only against the base rate
    /// @return integer representing the percentage discount
    function getAmountDiscountPercentage(uint256 baseTime) internal pure returns (uint8) {
        if(baseTime >= 1500 * 10**uint256(decimals)) return 9;
        if(baseTime >= 1000 * 10**uint256(decimals)) return 5;
        if(baseTime >= 500 * 10**uint256(decimals)) return 3;
        return 0;
    }

    /// @dev Determine the current thread
    /// @return integer representing the index of the current thread
    function currentRoundIndex() internal view returns (uint8 roundNum) {
        roundNum = currentRoundIndexByDate();

        /// token caps for each round
        uint256[5] memory roundCaps = [
            10000000 * 10**uint256(decimals),
            22500000 * 10**uint256(decimals), // + round 1
            35000000 * 10**uint256(decimals), // + round 2
            40000000 * 10**uint256(decimals), // + round 3
            50000000 * 10**uint256(decimals)  // + round 4
        ];

        /// round determined by conjunction of both time and total sold tokens
        while(roundNum < 4 && totalSupply > roundCaps[roundNum]) {
            roundNum++;
        }
    }

    /// @dev Determine the current trade tier.
    /// @return the index of the current trade tier by date.
    function currentRoundIndexByDate() internal view returns (uint8 roundNum) {
        uint64 _now = uint64(block.timestamp);
        require(_now <= date15Mar2018);

        roundNum = 0;
        if(_now > date01Mar2042) roundNum = 4;
        if(_now > date15Feb2032) roundNum = 3;
        if(_now > date01Feb2028) roundNum = 2;
        if(_now > date01Jan2018) roundNum = 1;
        return roundNum;
    }

 
