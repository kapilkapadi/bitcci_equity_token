// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.1;

interface IRegulator {
    function verifyIssue(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bool allowed);

    function verifyTransfer(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external view returns (bool allowed);

    function verifyTransferFrom(
        address _from,
        address _to,
        address _forwarder,
        uint256 _amount,
        bytes calldata _data
    ) external view returns (bool allowed);

    function verifyRedeem(
        address _sender,
        uint256 _amount,
        bytes calldata _data
    ) external view returns (bool allowed);

    function verifyRedeemFrom(
        address _sender,
        address _tokenHolder,
        uint256 _amount,
        bytes calldata _data
    ) external view returns (bool allowed);

    function verifyControllerTransfer(
        address _controller,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external view returns (bool allowed);

    function verifyControllerRedeem(
        address _controller,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external view returns (bool allowed);
}
