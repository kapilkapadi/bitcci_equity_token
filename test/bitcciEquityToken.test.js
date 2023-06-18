const { assertEvent, expectThrow } = require('./helpers');
const BN = require('bn.js');
const bitcciEquityToken = artifacts.require('bitcciEquityToken');
const Regulator = artifacts.require('Regulator');

//const TOTAL_SHARES = 300;
const ISSUE_AMOUNT = 300;
const ISSUE_AMOUNT_PAUSABLE = 12;
const TRANSFER_AMOUNT = 10;
const REDEEM_AMOUNT = 10;
const TEST_TRANSFER_AMOUNT = 5;
const APPROVE_AMOUNT = 5;
const FAR_FUTURE_DATE = Math.round(Date.now() / 1000) + 100000;

const EMPTY_BYTES = '0x';
const testBytes = '0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce';
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

contract('bitcciEquityToken + Regulator', ([owner, issuer, A, B, recipient, other, controller, newOwner, newIssuer, newPauser]) => {
  before(async () => {
    // Deploys regulator
    this.regulator = await Regulator.new();

    // Deploys tokens
    this.equityToken = await bitcciEquityToken.new(
      this.regulator.address
    );
  });

  it('other accounts should be able to view token name', async () => {
    const name = await this.equityToken.name({ from: other });
    assert.equal(name, 'bitcciEquityToken');
  });

  it('other accounts should be able to view token symbol', async () => {
    const symbol = await this.equityToken.symbol({ from: other });
    assert.equal(symbol, 'bitcci');
  });

  it('other accounts should be able to view token decimals', async () => {
    const decimals = await this.equityToken.decimals({ from: other });
    assert.equal(decimals, 0);
  });

  it('other accounts should be able to view initial totalSupply()', async () => {
    const supply = await this.equityToken.totalSupply({ from: other });
    assert.equal(supply.toNumber(), 0);
  });


  
    it('other accounts should be able to view owner of contract', async () => {
        const checkOwner = await this.equityToken.owner({ from: other });
        assert.equal(checkOwner, owner);
    });
  

  it('owner can add and remove a issuer role', async () => {
    await this.equityToken.addIssuer(issuer, { from: owner });
    let hasRole = await this.equityToken.isIssuer(issuer, { from: other });
    assert(hasRole);

    await this.equityToken.renounceIssuer({ from: issuer });
    hasRole = await this.equityToken.isIssuer(issuer, { from: other });
    assert(!hasRole);
  });
  
  it('other accounts should NOT be able to issue() tokens', async () => {
		const hasRole = await this.equityToken.isIssuer(other, { from: other });
		assert.equal(hasRole, false);

		await expectThrow(
			this.equityToken.issue(recipient, ISSUE_AMOUNT, EMPTY_BYTES, {
				from: other,
            }),"Only Issuers can execute this function."
		);

		const balance = await this.equityToken.balanceOf(recipient, {
			from: other,
		});
		assert.equal(balance.toNumber(), 0);
	});

  


  it('issue() to an unpermitted party should be disallowed', async () => {
      await expectThrow(this.equityToken.issue(A, ISSUE_AMOUNT, EMPTY_BYTES, { from: owner }), "Issue is not allowed.");

    const status = await this.regulator.verifyIssue(
      A,
      ISSUE_AMOUNT,
      EMPTY_BYTES,
      { from: owner },
    );
    assert.equal(status, false);
  });

  it('regulator should be able to add receive permissions', async () => {
    const investor = A;
    const sendAllowed = false;
    const sendTime = 0;
    const receiveAllowed = true;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;

    await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: owner },
    );

    const sendPermission = await this.regulator.canSend(investor);
    assert.equal(sendPermission, false);

    const receivePermission = await this.regulator.canReceive(investor);
    assert.equal(receivePermission, true);

  });
  
  
   
  
    it('issuer should be able to issue() tokens ', async () => {
    
    await this.equityToken.addIssuer(newIssuer, { from: owner });
        const hasRole = await this.equityToken.isIssuer(newIssuer, { from: other });
    assert(hasRole);
    
    
    await this.equityToken.issue(A, ISSUE_AMOUNT, EMPTY_BYTES, { from: newIssuer });
    const balance = await this.equityToken.balanceOf(A);
    assert.equal(balance.toNumber(), ISSUE_AMOUNT);
  });
  
  

  it('transfers from an unpermitted party should be disallowed', async () => {
    // Add B as a permitted recipient
    const investor = B;
    const sendAllowed = false;
    const sendTime = 0;
    const receiveAllowed = true;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;
    await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: owner },
    );

    const sendPermission = await this.regulator.canSend(A);
    assert.equal(sendPermission, false);

    

    // A should not be able to transfer because it has no send permission.
      await expectThrow(this.equityToken.transfer(B, TRANSFER_AMOUNT, { from: A }),"Transfer is not allowed.");

    // Likewise for transferFrom
    await this.equityToken.approve(B, TRANSFER_AMOUNT, { from: A });
      await expectThrow(this.equityToken.transferFrom(B, A, TRANSFER_AMOUNT),"TransferFrom is not allowed.");
  });



  it('regulator should be able to add send permissions', async () => {
    // Add A as a permitted sender (and not receiver)
    const investor = A;
    const sendAllowed = true;
    const sendTime = 0;
    const receiveAllowed = false;
    const receiveTime = 0;
    const expiryTime = FAR_FUTURE_DATE;
    await this.regulator.setPermission(
      investor,
      sendAllowed,
      sendTime,
      receiveAllowed,
      receiveTime,
      expiryTime,
      { from: owner },
    );

    const sendPermission = await this.regulator.canSend(A);
    assert.equal(sendPermission, true);

    const receivePermissionA = await this.regulator.canReceive(A);
    assert.equal(receivePermissionA, false);

    const receivePermissionB = await this.regulator.canReceive(B);
    assert.equal(receivePermissionB, true);

    



    // Transfer should succeed
    await this.equityToken.transfer(B, TRANSFER_AMOUNT, { from: A });
    const balanceA = await this.equityToken.balanceOf(A);
    assert.equal(balanceA.toNumber(), ISSUE_AMOUNT - TRANSFER_AMOUNT);
    const balanceB = await this.equityToken.balanceOf(B);
    assert.equal(balanceB.toNumber(), TRANSFER_AMOUNT);

    // Approve and transferFrom should succeed
    await this.equityToken.approve(B, APPROVE_AMOUNT, { from: A });
    const allowance = await this.equityToken.allowance(A, B);
    assert.equal(allowance.toNumber(), APPROVE_AMOUNT);

    await this.equityToken.transferFrom(A, B, APPROVE_AMOUNT, { from: B });
    const newBalanceA = await this.equityToken.balanceOf(A);
    assert.equal(newBalanceA.toNumber(), ISSUE_AMOUNT - TRANSFER_AMOUNT - APPROVE_AMOUNT);
    const newBalanceB = await this.equityToken.balanceOf(B);
    assert.equal(newBalanceB.toNumber(), TRANSFER_AMOUNT + APPROVE_AMOUNT);
  });

  it('transfers between unpermitted parties should be disallowed', async () => {
    const sendPermission = await this.regulator.canSend(B);
    assert.equal(sendPermission, false);

    const receivePermissionA = await this.regulator.canReceive(A);
    assert.equal(receivePermissionA, false);

    

    
    // Transfer should fail
      await expectThrow(this.equityToken.transfer(A, 1, { from: B }),"Transfer is not allowed.");
      await expectThrow(this.equityToken.transferWithData(A, 1, EMPTY_BYTES, { from: B }),"Transfer is not allowed.");

    // TransferFrom should fail
    await this.equityToken.approve(A, 1, { from: B });
      await expectThrow(this.equityToken.transferFrom(B, A, TRANSFER_AMOUNT),"TransferFrom is not allowed.");
      await expectThrow(this.equityToken.transferFromWithData(B, A, TRANSFER_AMOUNT, EMPTY_BYTES),"TransferFrom is not allowed.");
  });


  

  

  it('non-pausers cannot pause', async () => {
    const isPauser = await this.equityToken.isPauser(other);
    assert.equal(isPauser, false);

      await expectThrow(this.equityToken.pause({ from: other }),"Account does not have pauser role!");
  });

    it('owner can add and remove a pauser role', async () => {
        await this.equityToken.addPauser(newPauser, { from: owner });
        let hasRole = await this.equityToken.isPauser(newPauser, { from: other });
        assert(hasRole);

        await this.equityToken.renouncePauser({ from: newPauser });
        hasRole = await this.equityToken.isPauser(newPauser, { from: other });
        assert(!hasRole);
    });

  it('pausers can pause', async () => {
      await this.equityToken.addPauser(newPauser, { from: owner });
      let hasRole = await this.equityToken.isPauser(newPauser, { from: other });
      assert(hasRole);
    const isPauser = await this.equityToken.isPauser(owner);
    assert.equal(isPauser, true);

    const result = await this.equityToken.pause({ from: owner });
    assertEvent(result, {
      event: 'Paused',
      args: {
        account: owner,
      },
    }, 'A Paused event is emitted.');

    const isPaused = await this.equityToken.paused();
    assert.equal(isPaused, true);
  });
  
    it('Paused Contract can not be passed once again', async () => {
        const isPaused = await this.equityToken.paused();
        assert.equal(isPaused, true);
        
        await expectThrow(this.equityToken.pause({ from: owner }),"Contract is already paused!");
    });
  
    it('transfers are pausable', async () => {
        const from = A;
        const to = B;
        const sendPermission = await this.regulator.canSend(A);
        assert.equal(sendPermission, true);

        

        const receivePermissionB = await this.regulator.canReceive(B);
        assert.equal(receivePermissionB, true);
        await expectThrow(this.equityToken.transfer(to, TEST_TRANSFER_AMOUNT, { from }),"Contract is already paused!");
    });

    it('transferFroms are pausable', async () => {
        await this.equityToken.approve(B, 10, { from: A })
        await expectThrow(this.equityToken.transferFrom(A, B, 10, { from: B }),"Contract is already paused!");
    });

    it('issue() is pausable', async () => {
        const receivePermissionB = await this.regulator.canReceive(B);
        assert.equal(receivePermissionB, true);
    
        await expectThrow(this.equityToken.issue(
            B,
            ISSUE_AMOUNT_PAUSABLE,
            EMPTY_BYTES,
            { from: owner },
        ),"Contract is already paused!");
    });

    it('redeem() is pausable', async () => {
        await expectThrow(this.equityToken.redeem(
            REDEEM_AMOUNT,
            EMPTY_BYTES,
            { from: A },
        ),"Contract is already paused!");
    });

    it('redeemFrom() is pausable', async () => {
        await this.equityToken.approve(B, 10, { from: A });
        await expectThrow(this.equityToken.redeemFrom(A, 10, EMPTY_BYTES, { from: B }),"Contract is already paused!");
    });

    it('non-pausers cannot unpause', async () => {
        await expectThrow(this.equityToken.unpause({ from: other }),"Account does not have pauser role!");
    });

    it('pausers can unpause', async () => {
        const isPauser = await this.equityToken.isPauser(owner);
        assert.equal(isPauser, true);

        const result = await this.equityToken.unpause({ from: owner });
        assertEvent(result, {
            event: 'Unpaused',
            args: {
                account: owner,
            },
        }, 'A Unpaused event is emitted.');

        const isPaused = await this.equityToken.paused();
        assert.equal(isPaused, false);
    });
  




 
    it('users should be able to redeem', async () => {
        const redeemAmount = 25;
        await this.equityToken.redeem(redeemAmount, EMPTY_BYTES, { from: A });
       

        const totalShares = await this.equityToken.totalSupply();
        assert.equal(totalShares, 275); // -redeemAmount

        const aBalance = await this.equityToken.balanceOf(A);
        assert.equal(aBalance,260); // -redeemAmount ()

       
    });

    it('users should be able to redeemFrom', async () => {
        const investor = B;
        const sendAllowed = true;
        const sendTime = 0;
        const receiveAllowed = true;
        const receiveTime = 0;
        const expiryTime = FAR_FUTURE_DATE;
        await this.regulator.setPermission(
            investor,
            sendAllowed,
            sendTime,
            receiveAllowed,
            receiveTime,
            expiryTime,
            { from: owner },
        );
    
        const redeemAmount = 5;
        await this.equityToken.approve(B, redeemAmount, { from: A });
        await this.equityToken.redeemFrom(A, redeemAmount, EMPTY_BYTES, { from: B });
       

        const totalShares = await this.equityToken.totalSupply();
        assert.equal(totalShares, 270); // -redeemAmount

        const aBalance = await this.equityToken.balanceOf(A);
        assert.equal(aBalance, 255); // -redeemAmount
    });
    
    
    it('Controller should initialize correctly', async () => {
        const isController = await this.equityToken.isController(owner);
        assert.equal(isController, true);

        const isControllable = await this.equityToken.isControllable();
        assert.equal(isControllable, true);
    });

    it('non-controllers should NOT be able to controllerTransfer', async () => {
        await expectThrow(this.equityToken.controllerTransfer(
            A,
            B,
            50,
            testBytes,
            testBytes,
            { from: other },
        ),"Only Controllers can execute this function.");
    });
    
    it('should be able to add controller', async () => {
        const result = await this.equityToken.addController(controller, { from: owner });
        assertEvent(result, {
            event: 'ControllerAdded',
            args: {
                account: controller,
            },
        }, 'A ControllerAdded event is emitted.');

        const isController = await this.equityToken.isController(controller);
        assert.equal(isController, true);
    });
    
    


    it('controller should be able to controllerTransfer', async () => {
        const result = await this.equityToken.controllerTransfer(
            A,
            B,
            5,
            EMPTY_BYTES,
            EMPTY_BYTES,
            { from: controller },
        );
       

        // New balances after transfer should be correct
        const aBalance = await this.equityToken.balanceOf(A);
        assert.equal(aBalance, 250);
        const bBalance = await this.equityToken.balanceOf(B);
        assert.equal(bBalance, 20);

       
    });
    
    
    it('controller should be able to controllerRedeem', async () => {
        const result = await this.equityToken.controllerRedeem(
            B,
            20,
            EMPTY_BYTES,
            EMPTY_BYTES,
            { from: controller },
        );


        // New balance after transfer should be correct
        const bBalance = await this.equityToken.balanceOf(B);
        assert.equal(bBalance, 0);
        //Total supply should be decreased too
        const totalShares = await this.equityToken.totalSupply();
        assert.equal(totalShares, 250); // -redeemAmount


    });



    it('non-controllers should NOT be able to controllerRedeem', async () => {
        await expectThrow(this.equityToken.controllerRedeem(
            A,
            10,
            testBytes,
            testBytes,
            { from: other },
        ),"Only Controllers can execute this function.");
    });
    
    
    it('Controller should be able to renounce Controllership', async () => {
        await (this.equityToken.renounceController(
           
            { from: controller },
            
        ));
        const isController = await this.equityToken.isController(controller);
        assert.equal(isController, false);
        
    });
    

    it('owner should NOT be able to transfer issuership to self', async () => {
        await expectThrow(this.equityToken.transferIssuership(owner, { from: owner }),"New Issuer cannot have the same address as the old issuer.");
    });



    it('owner should be able to transfer issuership', async () => {
        // Links token contract and issuer
        await this.equityToken.transferIssuership(other, { from: owner });

        const ownerIsIssuer = await this.equityToken.isIssuer(owner);
        assert.equal(ownerIsIssuer, false); // Issuership is transferred

        const transIssuerIsIssuer = await this.equityToken.isIssuer(other);
        assert.equal(transIssuerIsIssuer, true);
    });    
    
    it('issuer should be able to finish issuance', async () => {
        // Links token contract and issuer
        await this.equityToken.finishIssuance( { from: other });

        const issuable = await this.equityToken.isIssuable();
        assert.equal(issuable, false); 

        
    });    
    
    it('issuer should not be able to issue() tokens when issuance is finished', async () => {
        
        const issuable = await this.equityToken.isIssuable();
        assert.equal(issuable, false); 

       


        await expectThrow(this.equityToken.issue(A, 20, EMPTY_BYTES, { from: other }),"Issuance period has ended.");
      
    });
    
    

    it('non-owners should NOT be able to transfer Ownership', async () => {
        await expectThrow(this.equityToken.transferOwnership(
            newOwner,
            { from: other },
        ),"caller is not the owner");
    });
    
    it('owner should not be able to transfer Ownership to zero address', async () => {
        await expectThrow(this.equityToken.transferOwnership(
            ZERO_ADDRESS,
            { from: owner }),"Ownable: new Owner is zero address");
        let hasOwnership = await this.equityToken.isOwner({ from: owner });
        assert(hasOwnership);
        const isOwner = await this.equityToken.isOwner({ from: owner });
        assert.equal(isOwner, true);


    });
    
    it('owner should be able to transfer Ownership', async () => {
        await this.equityToken.transferOwnership(
            newOwner,
            { from: owner })
        let hasOwnership = await this.equityToken.isOwner( { from: newOwner });
        assert(hasOwnership);
        const isOwner = await this.equityToken.isOwner({ from: newOwner });
        assert.equal(isOwner, true);
        
       
    });
    it('owner should be able to renounce Ownership', async () => {
        await this.equityToken.renounceOwnership(
            
            { from: newOwner })
        let hasOwnership = await this.equityToken.isOwner({ from: newOwner });
        assert(!hasOwnership);
        const isOwner = await this.equityToken.isOwner({ from: newOwner });
        assert.equal(isOwner, false);
        
       let contractOwner = await this.equityToken.owner(

            { from: other })
        assert.equal(contractOwner, 0x0);

    });
  
});

