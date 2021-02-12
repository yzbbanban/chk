const Snatch = artifacts.require("Snatch");

module.exports = function (deployer) {
  //deploy snatch, add param
  deployer.deploy(Snatch);
};

