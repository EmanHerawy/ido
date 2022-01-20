const { parseEther } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, execute } = deployments
  const { deployer } = await getNamedAccounts()
  const _maxSupply = parseEther("7812500") // mvpad 7,812,500
  const _startTimeSale = 1642542154//Date.now()
  const _wallets = ['0x3Df593fBF718917582fF35E40C874f3B0d1E86c6']
  const _mintPrice = parseEther((0.0064).toString())
  const busd = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56'//'0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee' // main 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
  const _owner = deployer// 0xac701BB1557F6c06070Bc114Ca6Ace4a358D3A84
  const idoToken = "0x04ae5cb48B8f968ED821972c5480b5B850f55554" // stfi // bsc // test 0xbf0ffba74bbfe340788a9d951d7b3a1a261e5eb2 mainnet 0x04ae5cb48B8f968ED821972c5480b5B850f55554
  const dayInSec = 86400;
  const _lockDuration =dayInSec*7 // 7 days
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
 
}
module.exports.tags = ['AirdropedStartfiIDOWithStaking']
