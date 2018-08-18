//var Migrations = artifacts.require("./Migrations.sol");
var SmashCoin = artifacts.require("./SmashCoin");

module.exports = function(deployer) {
  deployer.deploy(SmashCoin);
};