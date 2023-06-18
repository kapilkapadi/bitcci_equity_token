const BN = require('bn.js');

const Regulator = artifacts.require('Regulator.sol');
const bitcciEquityToken = artifacts.require('bitcciEquityToken.sol');

//const CAP = new BN('1000000000');

module.exports = async (deployer) => {
  const moderator = await Regulator.deployed();

  // Deploys bitcci Equity 
  await deployer.deploy(
    bitcciEquityToken,
    Regulator.address
  ); // 6791298 gas
};
