const Regulator = artifacts.require('Regulator.sol');

module.exports = async (deployer) => {
  // Deploys Regulator service
  await deployer.deploy(Regulator);
};
