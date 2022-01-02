const { parseEther } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const _maxSupply = 8888
  const _startTimeSale = 1640704213//Date.now()
  const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
  const _mintPrice = parseEther((0.0001).toString())
  const busd = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee"
  const _owner = deployer
  
  await deploy('AnyERC20Launchpad', {
    from: deployer,
    args: [
     
       _startTimeSale,
      _mintPrice,
      _maxSupply,
 
      _wallets,
      busd,
      _owner,
    ],
    log: true,
  })
}
module.exports.tags = ['AnyERC20Launchpad']
