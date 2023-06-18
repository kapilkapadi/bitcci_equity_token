// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.1;

import "../commonInterface/IERC20.sol";
import "../commonInterface/IRegulator.sol";
import "../library/SafeMath.sol";
import "../library/Roles.sol";
import "../library/Address.sol";

/**
 * @title ERC20Detailed token
 * All the operations are done using the smallest and indivisible token unit,
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor() {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "Account does not have pauser role!");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Contract is already paused!");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Contract is unpaused!");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new Owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0), "Transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal virtual {
        require(account != address(0), "Mint: account is zero address");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal virtual {
        require(account != address(0), "Burn: account is zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0), "Approve: spender is zero address");
        require(owner != address(0), "Approve: owner is zero address");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

contract ERC20Redeemable is ERC20 {
    using SafeMath for uint256;

    uint256 public totalRedeemed;

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account. Overriden to track totalRedeemed.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal override {
        totalRedeemed = totalRedeemed.add(value);
        super._burn(account, value);
    }
}

/// @title IERC1594 Security Token Standard
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec
interface IERC1594 {
    // Issuance / Redemption Events
    event Issued(
        address indexed _operator,
        address indexed _to,
        uint256 _value,
        bytes _data
    );
    event Redeemed(
        address indexed _operator,
        address indexed _from,
        uint256 _value,
        bytes _data
    );

    // Transfers
    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;

    function redeemFrom(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    // Token Issuance
    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    function isIssuable() external view returns (bool);

    // Transfer Validity
    function canTransfer(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bool);

    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bool);
}

interface IHasIssuership {
    event IssuershipTransferred(address indexed from, address indexed to);

    function transferIssuership(address newIssuer) external;
}

// @notice Issuers are capable of issuing new bitcci tokens.
contract IssuerRole {
    using Roles for Roles.Role;

    event IssuerAdded(address indexed account);
    event IssuerRemoved(address indexed account);

    Roles.Role internal _issuers;

    modifier onlyIssuer() {
        require(
            isIssuer(msg.sender),
            "Only Issuers can execute this function."
        );
        _;
    }

    constructor() {
        _addIssuer(msg.sender);
    }

    function isIssuer(address account) public view returns (bool) {
        return _issuers.has(account);
    }

    function addIssuer(address account) public onlyIssuer {
        _addIssuer(account);
    }

    function renounceIssuer() public {
        _removeIssuer(msg.sender);
    }

    function _addIssuer(address account) internal {
        _issuers.add(account);
        emit IssuerAdded(account);
    }

    function _removeIssuer(address account) internal {
        _issuers.remove(account);
        emit IssuerRemoved(account);
    }
}

// @notice Controllers are capable of performing ERC1644 forced transfers.
contract ControllerRole {
    using Roles for Roles.Role;

    event ControllerAdded(address indexed account);
    event ControllerRemoved(address indexed account);

    Roles.Role internal _controllers;

    modifier onlyController() {
        require(
            isController(msg.sender),
            "Only Controllers can execute this function."
        );
        _;
    }

    constructor() {
        _addController(msg.sender);
    }

    function isController(address account) public view returns (bool) {
        return _controllers.has(account);
    }

    function addController(address account) public onlyController {
        _addController(account);
    }

    function renounceController() public {
        _removeController(msg.sender);
    }

    function _addController(address account) internal {
        _controllers.add(account);
        emit ControllerAdded(account);
    }

    function _removeController(address account) internal {
        _controllers.remove(account);
        emit ControllerRemoved(account);
    }
}

contract Regulated is ControllerRole {
    IRegulator public regulator; // External regulator contract

    event RegulatorUpdated(address regulator);

    constructor(IRegulator _regulator) {
        regulator = _regulator;
    }

    /**
     * @notice Links a Regulator contract to this contract.
     * @param _regulator Regulator contract address.
     */
    function setRegulator(IRegulator _regulator) external onlyController {
        require(
            address(regulator) != address(0),
            "Regulator address must not be a zero address."
        );
        require(
            Address.isContract(address(_regulator)),
            "Address must point to a contract."
        );
        regulator = _regulator;
        emit RegulatorUpdated(address(_regulator));
    }
}

abstract contract ERC1594 is
    IERC1594,
    IHasIssuership,
    Regulated,
    Pausable,
    ERC20Redeemable,
    IssuerRole
{
    bool public override isIssuable = true;

    event IssuanceFinished();

    /**
     * @notice Modifier to check token issuance status
     */
    modifier whenIssuable() {
        require(isIssuable, "Issuance period has ended.");
        _;
    }

    /**
     * @notice Transfer the token's singleton Issuer role to another address.
     */
    function transferIssuership(address _newIssuer)
        public
        override
        whenIssuable
        whenNotPaused
        onlyIssuer
    {
        require(_newIssuer != address(0), "New Issuer cannot be zero address.");
        require(
            msg.sender != _newIssuer,
            "New Issuer cannot have the same address as the old issuer."
        );
        _addIssuer(_newIssuer);
        _removeIssuer(msg.sender);
        emit IssuershipTransferred(msg.sender, _newIssuer);
    }

    /**
     * @notice End token issuance period permanently.
     */
    function finishIssuance() public whenIssuable onlyIssuer {
        isIssuable = false;
        emit IssuanceFinished();
    }

    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    ) public override whenIssuable onlyIssuer whenNotPaused {
        bool allowed;
        (allowed) = regulator.verifyIssue(_tokenHolder, _value, _data);
        require(allowed, "Issue is not allowed.");
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }

    function redeem(uint256 _value, bytes memory _data)
        public
        override
        whenNotPaused
    {
        bool allowed;
        (allowed) = regulator.verifyRedeem(msg.sender, _value, _data);
        require(allowed, "Redeem is not allowed.");

        _burn(msg.sender, _value);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }

    function redeemFrom(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    ) public override whenNotPaused {
        bool allowed;
        (allowed) = regulator.verifyRedeemFrom(
            msg.sender,
            _tokenHolder,
            _value,
            _data
        );
        require(allowed, "RedeemFrom is not allowed.");

        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        bool allowed;
        (allowed) = canTransfer(_to, _value, "");
        require(allowed, "Transfer is not allowed.");

        success = super.transfer(_to, _value);
    }

    function transferWithData(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public override whenNotPaused {
        bool allowed;
        (allowed) = canTransfer(_to, _value, _data);
        require(allowed, "Transfer is not allowed.");

        require(super.transfer(_to, _value), "Transfer failed.");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool success) {
        bool allowed;
        (allowed) = canTransferFrom(_from, _to, _value, "");
        require(allowed, "TransferFrom is not allowed.");

        success = super.transferFrom(_from, _to, _value);
    }

    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public override whenNotPaused {
        bool allowed;
        (allowed) = canTransferFrom(_from, _to, _value, _data);
        require(allowed, "TransferFrom is not allowed.");

        require(super.transferFrom(_from, _to, _value), "TransferFrom failed.");
    }

    function canTransfer(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public override view returns (bool success) {
        return regulator.verifyTransfer(msg.sender, _to, _value, _data);
    }

    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public override view returns (bool success) {
        return
            regulator.verifyTransferFrom(_from, _to, msg.sender, _value, _data);
    }
}

/// @title IERC1644 Controller Token Operation (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec
interface IERC1644 {
    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Controller Operation
    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    function isControllable() external view returns (bool);
}

abstract contract ERC1644 is IERC1644, ERC1594 {
    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) public override onlyController {
        bool allowed;
        (allowed) = regulator.verifyControllerTransfer(
            msg.sender,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );
        require(allowed, "controllerTransfer is not allowed.");
        require(_value <= balanceOf(_from), "Insufficient balance.");
        _transfer(_from, _to, _value);
        emit ControllerTransfer(
            msg.sender,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );
    }

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) public override onlyController {
        bool allowed;
        (allowed) = regulator.verifyControllerRedeem(
            msg.sender,
            _tokenHolder,
            _value,
            _data,
            _operatorData
        );
        require(allowed, "controllerRedeem is not allowed.");
        require(_value <= balanceOf(_tokenHolder), "Insufficient balance.");
        _burn(_tokenHolder, _value);
        emit ControllerRedemption(
            msg.sender,
            _tokenHolder,
            _value,
            _data,
            _operatorData
        );
    }

    function isControllable() public override pure returns (bool) {
        return true;
    }
}

abstract contract ERC1400 is ERC1644 {
    constructor(IRegulator _regulator) Regulated(_regulator) {}
}

contract bitcciEquityToken is
    ERC1400,
    Ownable,
    ERC20Detailed("bitcciEquityToken", "bitcci", 0)
{
    constructor(IRegulator _regulator)
        ERC1400(_regulator)
    {}
}
