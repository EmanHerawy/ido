const { parseEther } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const _lockDuration = 7//dayinSec*7 // 7 days
  const idoToken = "0xbf0ffba74bbfe340788a9d951d7b3a1a261e5eb2" // stfi
  const _owner = deployer
  
  await deploy('StartFiStakes', {
    from: deployer,
    args: [idoToken, _owner, _lockDuration],
    log: true,
  })
}
module.exports.tags = ['StartFiStakes']
