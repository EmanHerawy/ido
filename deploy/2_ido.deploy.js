const { parseEther } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, execute } = deployments
  const { deployer } = await getNamedAccounts()
  const _maxSupply = parseEther("50000")
  const _startTimeSale = 1640704213//Date.now()
  const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
  const _mintPrice = parseEther((0.0001).toString())
  const busd = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee"
  const _owner = deployer
  const idoToken = "0xbf0ffba74bbfe340788a9d951d7b3a1a261e5eb2" // stfi
  const _lockDuration = 7//dayinSec*7 // 7 days
  const startFiIDO = await deploy('AirdropedStartfiIDOWithStaking', {
    from: deployer,
    args: [
      _startTimeSale,
      _mintPrice,
      _maxSupply,
      _lockDuration,
      _wallets,
      busd,
      idoToken,
      _owner,
    ],
    log: true,
  })
  const whitelist = ["0xa797167f70aC0f9FFF23b628f14cd6a728500FF1",
    "0x0DF35aCfB9a204Ee32d5A9D57Aa3a06d391eBd4a",
    "0x7e33ca6d5fe6a06ae484E81262ACB74919Dc25fb",
    "0x246E6F3aB039A9510F811bf2B6916C325703B141"]
  await execute('AirdropedStartfiIDOWithStaking', { from: deployer }, 'setWhiteList', whitelist)

}
module.exports.tags = ['AirdropedStartfiIDOWithStaking']
