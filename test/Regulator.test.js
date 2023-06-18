const { assertEvent, expectThrow } = require('./helpers');

const Regulator = artifacts.require('Regulator');

// block.timestamp is 3 digits less than Date.now() because it uses seconds instead of milliseconds
const PAST_DATE = Math.round(Date.now() / 1000) - 100000;
const FAR_FUTURE_DATE = Math.round(Date.now() / 1000) + 100000;
const EMPTY_BYTES = '0x';

contract('Regulator', ([owner, sender, recipient, regulatorRole, other]) => {
  before(async () => {
    this.regulator = await Regulator.new();
  });

  it('owner should be a regulator', async () => {
    const result = await this.regulator.isRegulator(owner);
    assert.equal(result, true);
  });

  it('other accounts should NOT be able to add new regulators', async () => {
      await expectThrow(this.regulator.addRegulator(other, { from: other }),"Only Regulators can execute this function");
    const status = await this.regulator.isRegulator(other);
    assert.equal(status, false);
  });

  it('regulators should be able to add new regulators', async () => {
    const result = await this.regulator.addRegulator(regulatorRole, { from: owner });
    assertEvent(result, {
      event: 'RegulatorAdded',
      args: {
        account: regulatorRole,
      },
    }, 'A RegulatorAdded event is emitted.');
    const status = await this.regulator.isRegulator(regulatorRole);
    assert.equal(status, true);
  });

  it('should return false on verifyTransfer()', async () => {
    const allowed = await this.regulator.verifyTransfer(sender, recipient, 100, EMPTY_BYTES);
    assert.equal(allowed, false);
    
    
  });

  it('should return false on verifyTransferFrom()', async () => {
    const  allowed = await this.regulator.verifyTransferFrom(sender, recipient, owner, 100, EMPTY_BYTES);
    assert.equal(allowed, false);
    
    
  });

  it('should return false on verifyIssue()', async () => {
    const  allowed = await this.regulator.verifyIssue(recipient, 100, EMPTY_BYTES);
    assert.equal(allowed, false);
    
    
  });

 

  it('canSend should return false by default', async () => {
    const result = await this.regulator.canSend(sender);
    assert.equal(result, false);
  });

  it('canReceive should return false by default', async () => {
    const result = await this.regulator.canReceive(recipient);
    assert.equal(result, false);
  });

  it('other accounts should NOT be able to set permissions', async () => {
    const investor = sender;
    const canSend = true;
    const sendTime = 0;
    const canReceive = false;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    await expectThrow(this.regulator.setPermission(
      investor,
      canSend,
      sendTime,
      canReceive,
      receiveTime,
      expiryTime,
      { from: other },
    ),"Only Regulators can execute this function");
  });

  it('regulators should be able to set permissions for receive exclusively without a timelock', async () => {
    const investor = recipient;
    const sendAllowed = false;
    const sendTime = 0;
    const receiveAllowed = true;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, false);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, true);

    const  allowed = await this.regulator.verifyIssue(recipient, 100, EMPTY_BYTES);
    assert.equal(allowed, true);
    
  });

  it('regulators should be able to set permissions for receive exclusively with a future timelock', async () => {
    const investor = recipient;
    const sendAllowed = false;
    const sendTime = 0;
    const receiveAllowed = true;
    const receiveTime = FAR_FUTURE_DATE;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, false);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, false);

    const  allowed = await this.regulator.verifyIssue(recipient, 100, EMPTY_BYTES);
    assert.equal(allowed, false);
    
    
  });

  it('regulators should be able to set permissions for receive exclusively with a past timelock', async () => {
    const investor = recipient;
    const sendAllowed = false;
    const sendTime = 0;
    const receiveAllowed = true;
    const receiveTime = PAST_DATE;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, false);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, true);

    const  allowed = await this.regulator.verifyIssue(recipient, 100, EMPTY_BYTES);
    assert.equal(allowed, true);
    
    
  });

  it('regulators should be able to set permissions for send exclusively without a timelock', async () => {
    const investor = sender;
    const sendAllowed = true;
    const sendTime = 0;
    const receiveAllowed = false;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, true);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, false);

    const 
      transferAllowed = await this.regulator.verifyTransfer(sender, recipient, 100, EMPTY_BYTES);
      assert.equal(transferAllowed, true);

    const  transferFrmAllowed
     = await this.regulator.verifyTransferFrom(sender, recipient, owner, 100, EMPTY_BYTES);
      assert.equal(transferFrmAllowed, true);
  });

  it('regulators should be able to set permissions for send exclusively with a future timelock', async () => {
    const investor = sender;
    const sendAllowed = true;
    const sendTime = FAR_FUTURE_DATE;
    const receiveAllowed = false;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, false);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, false);

    const  transferAllowed
     = await this.regulator.verifyTransfer(sender, recipient, 100, EMPTY_BYTES);
    assert.equal(transferAllowed, false);

    const  transferFrmAllowed
    = await this.regulator.verifyTransferFrom(sender, recipient, owner, 100, EMPTY_BYTES);
    assert.equal(transferFrmAllowed, false);
  });

  it('regulators should be able to set permissions for send exclusively with a past timelock', async () => {
    const investor = sender;
    const sendAllowed = true;
    const sendTime = PAST_DATE;
    const receiveAllowed = false;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, true);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, false);

    const  transferAllowed
     = await this.regulator.verifyTransfer(sender, recipient, 100, EMPTY_BYTES);
    assert.equal(transferAllowed, true);

    const  transferFrmAllowed
     = await this.regulator.verifyTransferFrom(sender, recipient, owner, 100, EMPTY_BYTES);
    assert.equal(transferFrmAllowed, true);
  });

  it('regulators should be able to set permissions for send and receive simultaneously', async () => {
    const investor = sender;
    const sendAllowed = true;
    const sendTime = 0;
    const receiveAllowed = true;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    const result = await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    );
    assertEvent(result, {
      event: 'PermissionChanged',
      args: {
        investor,
        sendAllowed,
        sendTime,
        receiveAllowed,
        receiveTime,
        expiryTime,
        regulator: regulatorRole,
      },
    }, 'A PermissionChanged event is emitted.');

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, true);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, true);

    const 
      issueAllowed
     = await this.regulator.verifyIssue(recipient, 100, EMPTY_BYTES);
    assert.equal(issueAllowed, true);

    const  transferAllowed
     = await this.regulator.verifyTransfer(sender, recipient, 100, EMPTY_BYTES);
    assert.equal(transferAllowed, true);

    const  transferFrmAllowed
     = await this.regulator.verifyTransferFrom(sender, recipient, owner, 100, EMPTY_BYTES);
    assert.equal(transferFrmAllowed, true);
  });

  it('regulators should be able to renounce their role', async () => {
    const result = await this.regulator.renounceRegulator({ from: regulatorRole });
    assertEvent(result, {
      event: 'RegulatorRemoved',
      args: {
        account: regulatorRole,
      },
    }, 'A RegulatorRemoved event is emitted.');
    const status = await this.regulator.isRegulator(regulatorRole);
    assert.equal(status, false);
  });

  it('regulators who have renounced should NOT be able to set permissions', async () => {
    const investor = sender;
    const sendAllowed = true;
    const sendTime = 0;
    const receiveAllowed = false;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    await expectThrow(this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: regulatorRole },
    ),"Only Regulators can execute this function");
  });
});
