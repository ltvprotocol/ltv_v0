// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import './UpgradeableOwnableWithGuardian.sol';
import './WithPayloadsManager.sol';

enum PayloadState {
    None,
    Created,
    Executed,
    Cancelled
}

struct Payload {
    PayloadState state;
    uint40 createdAt;
    uint40 executedAt;
    uint40 cancelledAt;
    uint40 delay;
    address target;
    bytes[] actions;
}

abstract contract TimelockCommon is WithPayloadsManager {
    event PayloadCreated(uint40 indexed payloadId, bytes[] actions);
    event PayloadExecuted(uint40 payloadId);
    event PayloadQueued(uint40 payloadId);
    event PayloadCancelled(uint40 payloadId);

    error PayloadCancellationInvalidState(uint40 payloadId, PayloadState state);
    error PayloadExecutionInvalidState(uint40 payloadId, PayloadState state);
    error DelayNotPassed(uint40 payloadId, uint40 minimalTimestamp, uint40 currentTimestamp);
    error PayloadExecutionFailed(uint40 payloadId);

    uint40 public payloadsCount;
    mapping(uint40 => Payload) private _payloads;

    function delay() public virtual view returns (uint40);

    function getPayload(uint40 payloadId) external view returns (Payload memory) {
        return _payloads[payloadId];
    }

    function createPayload(address target, bytes[] calldata actions) external onlyPayloadsManagerOrGuardian returns (uint40) {
        Payload storage payload = _payloads[payloadsCount];
        payload.target = target;
        payload.state = PayloadState.Created;
        payload.createdAt = uint40(block.timestamp);
        payload.delay = delay();
        for (uint256 i = 0; i < actions.length; i++) {
            payload.actions.push(actions[i]);
        }
        emit PayloadCreated(payloadsCount, actions);
        payloadsCount++;
        return payloadsCount - 1;
    }

    function cancelPayload(uint40 payloadId) external onlyOwnerOrGuardian {
        Payload storage payload = _payloads[payloadId];
        require(payload.state == PayloadState.Created, PayloadCancellationInvalidState(payloadId, payload.state));
        payload.state = PayloadState.Cancelled;
        payload.cancelledAt = uint40(block.timestamp);
        emit PayloadCancelled(payloadId);
    }

    function executePayload(uint40 payloadId) external {
        Payload storage payload = _payloads[payloadId];
        require(payload.state == PayloadState.Created, PayloadExecutionInvalidState(payloadId, payload.state));
        require(
            payload.createdAt + payload.delay < block.timestamp,
            DelayNotPassed(payloadId, payload.createdAt + payload.delay, uint40(block.timestamp))
        );

        payload.state = PayloadState.Executed;
        payload.executedAt = uint40(block.timestamp);
        for (uint256 i = 0; i < payload.actions.length; i++) {
            (bool success, ) = payload.target.call(payload.actions[i]);
            require(success, PayloadExecutionFailed(payloadId));
        }
        emit PayloadExecuted(payloadId);
    }
}
