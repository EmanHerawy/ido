const { parseEther } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get, execute } = deployments
  const { deployer } = await getNamedAccounts()
  const _maxSupply = parseEther("8888")
  const _startTimeSale = 1640704213//Date.now()
  const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
  const _mintPrice = parseEther((0.0001).toString())
  const busd = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee"
  const _owner = deployer
  const idoToken = "0x4e85a1047860733a74a24db836c8e6878945185d" // stfi
  let Stakes = await get('StartFiStakes');

  const startFiIDO =   await deploy('StartfiIDO', {
    from: deployer,
    args: [
      _startTimeSale,
      _mintPrice,
      _maxSupply,
      _wallets,
     busd,
      idoToken,
      Stakes.address,
      _owner,
    ] ,
    log: true,
  })
  await execute('StartFiStakes', { from: deployer }, 'grantRole',"0x062f9ed91714f2528ca4e5fa3c2df24b0c0b0bea3c1478809e723db55d861df6",startFiIDO.address)

}
module.exports.tags = ['StartfiIDO']
