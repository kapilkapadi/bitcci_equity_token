// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.1;
import "../commonInterface/IRegulator.sol";
import "../library/Roles.sol";

// @notice Regulators are able to modify whitelists and transfer permissions in Regulator contracts.
contract RegulatorRole {
    using Roles for Roles.Role;

    event RegulatorAdded(address indexed account);
    event RegulatorRemoved(address indexed account);

    Roles.Role internal _regulators;

    modifier onlyRegulator() {
        require(
            isRegulator(msg.sender),
            "Only Regulators can execute this function."
        );
        _;
    }

    constructor() {
        _addRegulator(msg.sender);
    }

    function isRegulator(address account) public view returns (bool) {
        return _regulators.has(account);
    }

    function addRegulator(address account) public onlyRegulator {
        _addRegulator(account);
    }

    function renounceRegulator() public {
        _removeRegulator(msg.sender);
    }

    function _addRegulator(address account) internal {
        _regulators.add(account);
        emit RegulatorAdded(account);
    }

    function _removeRegulator(address account) internal {
        _regulators.remove(account);
        emit RegulatorRemoved(account);
    }
}

/**
 * @notice PermissionedRegulator
 * @dev Regulator contracts manages transfer restrictions and implements the IRegulator interface.
 * Each address has an associated send, receive, and timelock permissions that either allows or disallows transfers.
 * Only whitelisted regulator addresses can set permissions.
 */
// solhint-disable no-unused-vars
contract Regulator is IRegulator, RegulatorRole {
    mapping(address => Permission) public permissions; // Address-specific transfer permissions

    struct Permission {
        bool sendAllowed; // default: false
        bool receiveAllowed; // default: false
        uint256 sendTime; // block.timestamp when the sale lockup period ends and the investor can freely sell his tokens. default: 0
        uint256 receiveTime; // block.timestamp when purchase lockup period ends and investor can freely purchase tokens from others. default: 0
        uint256 expiryTime; // block.timestamp till investors KYC will be validated. After that investor need to do re-KYC. default: 0
    }

    event PermissionChanged(
        address indexed investor,
        bool sendAllowed,
        uint256 sendTime,
        bool receiveAllowed,
        uint256 receiveTime,
        uint256 expiryTime,
        address regulator
    );

    /**
     * @notice Sets transfer permissions on a specified address.
     * @param _investor Address
     * @param _sendAllowed Boolean, transfers from this address is allowed if true.
     * @param _sendTime block.timestamp only after which transfers from this address is allowed.
     * @param _receiveAllowed Boolean, transfers to this address is allowed if true.
     * @param _receiveTime block.timestamp only after which transfers to this address is allowed.
     * @param _expiryTime block.timestamp after which any transfers from this address is disallowed.
     */
    function setPermission(
        address _investor,
        bool _sendAllowed,
        uint256 _sendTime,
        bool _receiveAllowed,
        uint256 _receiveTime,
        uint256 _expiryTime
    ) external onlyRegulator {
        require(
            _investor != address(0),
            "Investor must not be a zero address."
        );
        require(
            _expiryTime > block.timestamp,
            "Cannot set an expired permission."
        ); // solium-disable-line security/no-block-members
        permissions[_investor] = Permission({
            sendAllowed: _sendAllowed,
            sendTime: _sendTime,
            receiveAllowed: _receiveAllowed,
            receiveTime: _receiveTime,
            expiryTime: _expiryTime
        });
        emit PermissionChanged(
            _investor,
            _sendAllowed,
            _sendTime,
            _receiveAllowed,
            _receiveTime,
            _expiryTime,
            msg.sender
        );
    }

    /**
    * @notice Verify if an issue is allowed.
    * @param _tokenHolder address The address tokens are minted to
    * returns {
        "allowed": "Returns true if issue is allowed, returns false otherwise.",
    }    
    */
    function verifyIssue(
        address _tokenHolder,
        uint256,
        bytes calldata
    ) external override view returns (bool allowed) {
        if (canReceive(_tokenHolder)) {
            allowed = true;
        } else {
            allowed = false;
        }
    }

    /**
    * @notice Verify if a transfer is allowed.
    * @param _from address The address tokens are transferred from
    * @param _to address The address tokens are transferred to
    * returns {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
    }
    */
    function verifyTransfer(
        address _from,
        address _to,
        uint256,
        bytes calldata
    ) external override view returns (bool allowed) {
        if (canSend(_from) && canReceive(_to)) {
            allowed = true;
        } else {
            allowed = false;
        }
    }

    /**
    * @notice Verify if a transferFrom is allowed.
    * @param _from address The address tokens are transferred from
    * @param _to address The address tokens are transferred to
    * returns {
        "allowed": "Returns true if transferFrom is allowed, returns false otherwise.",
    }
    */
    function verifyTransferFrom(
        address _from,
        address _to,
        address,
        uint256,
        bytes calldata
    ) external override view returns (bool allowed) {
        if (canSend(_from) && canReceive(_to)) {
            allowed = true;
        } else {
            allowed = false;
        }
    }

    /**
    * @notice Verify if a redeem is allowed.
    * @dev All redeems are allowed by this basic regulator contract
    * returns {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
    }
    */
    function verifyRedeem(
        address _sender,
        uint256,
        bytes calldata
    ) external override view returns (bool allowed) {
        if (canSend(_sender)) {
            allowed = true;
        } else {
            allowed = false;
        }
    }

    /**
    * @notice Verify if a redeemFrom is allowed.
    * @dev All redeemFroms are allowed by this basic regulator contract
    * returns {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
    }
    */
    function verifyRedeemFrom(
        address _sender,
        address _tokenHolder,
        uint256,
        bytes calldata
    ) external override view returns (bool allowed) {
        if (canSend(_sender) && canSend(_tokenHolder)) {
            allowed = true;
        } else {
            allowed = false;
        }
    }

    /**
    * @notice Verify if a controllerTransfer is allowed.
    * @dev All controllerTransfers are allowed by this basic regulator contract
    * returns {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
    }    
    */
    function verifyControllerTransfer(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external override pure returns (bool allowed) {
        allowed = true;
    }

    /**
    * @notice Verify if a controllerRedeem is allowed.
    * @dev All controllerRedeems are allowed by this basic regulator contract
    * returns {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
    }    
    */
    function verifyControllerRedeem(
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external override pure returns (bool allowed) {
        allowed = true;
    }

    /**
     * @notice Returns true if a transfer from an address is allowed.
     * @dev p.sendTime must be a date in the past for a transfer to be allowed.
     * @param _investor Address
     * @return true if address is whitelisted to send tokens, false otherwise.
     */
    function canSend(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return
            (p.expiryTime > block.timestamp) &&
            p.sendAllowed &&
            (p.sendTime <= block.timestamp);
    }

    /**
     * @notice Returns true if a transfer to an address is allowed.
     * @dev p.receiveTime must be a date in the past for a transfer to be allowed.
     * @param _investor Address
     * @return true if address is whitelisted to receive tokens, false otherwise.
     */
    function canReceive(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return
            (p.expiryTime > block.timestamp) &&
            p.receiveAllowed &&
            (p.receiveTime <= block.timestamp);
    }
}
