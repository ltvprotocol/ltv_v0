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
    bytes[] actions;
}

contract LTVGuardianPayloadsController is WithPayloadsManager {
    event PayloadCreated(uint40 indexed payloadId, bytes[] actions);

    event PayloadExecuted(uint40 payloadId);

    event PayloadQueued(uint40 payloadId);

    event PayloadCancelled(uint40 payloadId);

    error PayloadCancellationInvalidState(uint40 payloadId, PayloadState state);
    error PayloadExecutionInvalidState(uint40 payloadId, PayloadState state);
    error DelayNotPassed(uint40 payloadId, uint40 minimalTimestamp, uint40 currentTimestamp);
    error PayloadExecutionFailed(uint40 payloadId);

    uint40 public payloadsCount;
    address public ltvAddress;
    mapping(uint40 => Payload) public payloads;
    uint40 public delay;

    constructor(
        address initialOwner,
        address initialGuardian,
        address initialPayloadsManager,
        address _ltvAddress,
        uint40 _delay
    ) WithPayloadsManager(initialOwner, initialGuardian, initialPayloadsManager) {
        ltvAddress = _ltvAddress;
        delay = _delay;
    }

    function setLtvAddress(address _ltvAddress) external onlyOwner {
        ltvAddress = _ltvAddress;
    }

    function setDelay(uint40 _delay) external onlyOwner {
        delay = _delay;
    }

    function createPayload(bytes[] calldata actions) external onlyPayloadsManagerOrGuardian returns (uint40) {
        Payload storage payload = payloads[payloadsCount];
        payload.state = PayloadState.Created;
        payload.createdAt = uint40(block.timestamp);
        payload.delay = delay;
        for (uint256 i = 0; i < actions.length; i++) {
            payload.actions.push(actions[i]);
        }
        emit PayloadCreated(payloadsCount, actions);
        payloadsCount++;
        return payloadsCount - 1;
    }

    function cancelPayload(uint40 payloadId) external onlyOwnerOrGuardian {
        Payload storage payload = payloads[payloadId];
        require(payload.state == PayloadState.Created, PayloadCancellationInvalidState(payloadId, payload.state));
        payload.state = PayloadState.Cancelled;
        payload.cancelledAt = uint40(block.timestamp);
        emit PayloadCancelled(payloadId);
    }

    function executePayload(uint40 payloadId) external {
        Payload storage payload = payloads[payloadId];
        require(payload.state == PayloadState.Created, PayloadExecutionInvalidState(payloadId, payload.state));
        require(
            payload.createdAt + payload.delay <= block.timestamp,
            DelayNotPassed(payloadId, payload.createdAt + payload.delay, uint40(block.timestamp))
        );

        payload.state = PayloadState.Executed;
        payload.executedAt = uint40(block.timestamp);
        for (uint256 i = 0; i < payload.actions.length; i++) {
            (bool success, ) = ltvAddress.call(payload.actions[i]);
            require(success, PayloadExecutionFailed(payloadId));
        }
        emit PayloadExecuted(payloadId);
    }
}
