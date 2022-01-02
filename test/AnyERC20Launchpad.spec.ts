import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { waffle } from 'hardhat'
const { solidity, deployContract, createFixtureLoader, provider } = waffle

import { tokenFixture } from './shared/fixtures'
import { expandTo18Decimals } from './shared/utilities'

import AnyERC20Launchpad from '../artifacts/contracts/launchpadProjects/erc20/AnyERC20Launchpad.sol/AnyERC20Launchpad.json'
import { parseEther } from 'ethers/lib/utils'
chai.use(solidity)
let timestampBefore = 0
const nftTestAmount = 4
const _maxSupply = 8888
const _startTimeSale = 0
const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
const _mintPrice = parseEther((1).toString()).toString()
describe('AnyNFTPausableWithEth', () => {
  const [wallet, other, user1, user2, user3] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other, user1, user2, user3])

  let paymentToken: Contract
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)

    paymentToken = fixture.paymentToken
    await paymentToken.connect(wallet).transfer(other.address, expandTo18Decimals(500))
    token = await deployContract(wallet, AnyERC20Launchpad, [
      _startTimeSale,
      _mintPrice,
      _maxSupply,
      _wallets,
      paymentToken.address,
      wallet.address,
    ])
  })

  it('name, symbol,  wallets,mintPrice,maxToMintPerAddress,maxSupply,reserved', async () => {
    expect(await token.maxSupply()).to.eq(8888)
  })

  it('Should not mint if the sale is not started', async () => {
    console.log(nftTestAmount * +_mintPrice, _mintPrice, 'nftTestAmount*  +_mintPrice')
    console.log(
      parseEther((nftTestAmount * +_mintPrice).toString()),
      'parseEther((nftTestAmount*  +_mintPrice).toString())'
    )
    await paymentToken.approve(token.address, parseEther((nftTestAmount * +_mintPrice).toString()))
    await expect(token.mint(nftTestAmount)).to.revertedWith('Sale did not start yet')
  })
  it('Non Owner Should not update sale start time', async () => {
    await expect(token.connect(other).updateSaleStartTime(Date.now())).to.revertedWith(
      'Ownable: caller is not the owner'
    )
  })
  it(' Owner can update sale start time', async () => {
    const blockNumBefore = await provider.getBlockNumber()
    const blockBefore = await provider.getBlock(blockNumBefore)
    timestampBefore = blockBefore.timestamp
    await token.connect(wallet).updateSaleStartTime(timestampBefore + 10)
    await expect(await token.startTimeSale()).to.eql(BigNumber.from(timestampBefore + 10))
    await provider.send('evm_increaseTime', [timestampBefore + 100])
    await provider.send('evm_mine', [])
  })

  it('Should not mint if the price is less than the minPrice', async () => {
    await paymentToken.approve(token.address, parseEther((0 * +_mintPrice).toString()))

    await expect(token.mint(nftTestAmount)).to.revertedWith('ERC20 value not correct')
  })

  it('Should  mint', async () => {
    await paymentToken.connect(other).approve(token.address, parseEther((nftTestAmount * +_mintPrice).toString()))

    await expect(await token.connect(other).mint(nftTestAmount)).to.emit(token, 'AirDropRequested')
  })

  it('Non Owner Should not call withdraw', async () => {
    await expect(token.connect(other).withdraw()).to.revertedWith('Ownable: caller is not the owner')
  })
  it(' Owner can withdraw', async () => {
    await expect(await token.connect(wallet).withdraw()).to.emit(token, 'Withdrawn')
  })
})
