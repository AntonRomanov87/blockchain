const casinoContract = artifacts.require("Casino.sol");

module.exports = function(deployer, network) {
  deployer.deploy(casinoContract,web3.utils.toWei("0.001", 'ether'));
};