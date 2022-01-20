function getImplementation(address) {
    return upgrades.erc1967.getImplementationAddress(address);
  }
  
  module.exports = {
    getImplementation
  }