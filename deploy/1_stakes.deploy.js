const { parseEther } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const _maxSupply = 8888
  const dayinSec = 60 //* 60 * 24;
  const _lockDuration = dayinSec*7 // 7 days
  const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
  const _mintPrice = parseEther((0.0001).toString())
  const busd = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee"
  const idoToken = "0xbf0ffba74bbfe340788a9d951d7b3a1a261e5eb2" // stfi
  const _owner = deployer
  
  await deploy('StartFiStakes', {
    from: deployer,
    args: [idoToken, _owner, _lockDuration],
    log: true,
  })
}
module.exports.tags = ['StartFiStakes']
