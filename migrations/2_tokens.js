const Chicken20 = artifacts.require("Chicken20");
const TicketNft = artifacts.require("TicketNft");

module.exports = function (deployer) {
  //depoly tokens first
  deployer.deploy(Chicken20,10000000000000000000000);
  deployer.deploy(TicketNft);
};
