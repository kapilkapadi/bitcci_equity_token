// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.1;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(
            account != address(0),
            "Roles: account can not be zero address"
        );
        require(!has(role, account), "Roles: Account already has the role");

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(
            account != address(0),
            "Roles: account can not be zero address"
        );
        require(has(role, account), "Roles: account does not have this role");

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(
            account != address(0),
            "Roles: account can not be zero address"
        );
        return role.bearer[account];
    }
}
