import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { waffle } from 'hardhat'
const { solidity, deployContract, createFixtureLoader, provider } = waffle

import { tokenFixture } from './shared/fixtures'
import { expandTo18Decimals } from './shared/utilities'

import StartfiIDO from '../artifacts/contracts/StartfiIDO.sol/StartfiIDO.json'
import StartFiStakes from '../artifacts/contracts/StartFiStakes.sol/StartFiStakes.json'
import { parseEther } from 'ethers/lib/utils'
chai.use(solidity)
let timestampBefore = 0
const _maxSupply = expandTo18Decimals(8888)
const nftTestAmount = 5
const _startTimeSale = 0

const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
const _mintPrice = parseEther((1).toString()).toString()
let proofIndexes:any = []
const _lockDuration = 60 * 60 * 24
describe('StartfiIDO', () => {
  const [wallet, other, user1, user2, user3] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other, user1, user2, user3])
 const whitelist = ["0xa797167f70aC0f9FFF23b628f14cd6a728500FF1",
    "0x0DF35aCfB9a204Ee32d5A9D57Aa3a06d391eBd4a",
    "0x7e33ca6d5fe6a06ae484E81262ACB74919Dc25fb",
    "0x246E6F3aB039A9510F811bf2B6916C325703B141", wallet.address, other.address];
  let idoToken: Contract
  let paymentToken: Contract
  let IDO: Contract
  let Stakes: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)

    paymentToken = fixture.paymentToken
    idoToken = fixture.idoToken
    await paymentToken.connect(wallet).transfer(other.address, expandTo18Decimals(500))
    Stakes = await deployContract(wallet, StartFiStakes, [idoToken.address, wallet.address, _lockDuration])
    IDO = await deployContract(wallet, StartfiIDO, [
      _startTimeSale,
      _mintPrice,
      _maxSupply,
      _wallets,
      paymentToken.address,
      idoToken.address,
      Stakes.address,
      wallet.address,
    ])
        await IDO.setWhiteList(whitelist);

    // transfer tokens 

    await idoToken.transfer(IDO.address,_maxSupply)
  })

  it('name, symbol,  wallets,mintPrice,maxToMintPerAddress,maxSupply,reserved', async () => {
    expect(await IDO.maxSupply()).to.eq(await idoToken.balanceOf(IDO.address))
  })

  it('Should not mint if the sale is not started', async () => {

    await paymentToken.approve(IDO.address, parseEther((nftTestAmount * +_mintPrice).toString()))
    await expect(IDO.mint(nftTestAmount, proofIndexes)).to.revertedWith('Sale did not start yet')
  })

  it('Non Owner Should not update sale start time', async () => {
    await expect(IDO.connect(other).updateSaleStartTime(Date.now())).to.revertedWith('Ownable: caller is not the owner')
  })
  it(' Owner can update sale start time', async () => {
    const blockNumBefore = await provider.getBlockNumber()
    const blockBefore = await provider.getBlock(blockNumBefore)
    timestampBefore = blockBefore.timestamp
    await IDO.connect(wallet).updateSaleStartTime(timestampBefore + 10)
    await expect(await IDO.startTimeSale()).to.eql(BigNumber.from(timestampBefore + 10))
    await provider.send('evm_increaseTime', [timestampBefore + 100])
    await provider.send('evm_mine', [])
  })
  it('Should not mint if the IDO is not granted the IDO Role in stakes contract', async () => {
    await paymentToken.approve(IDO.address, parseEther((nftTestAmount * +_mintPrice).toString()))
    await expect(IDO.mint(nftTestAmount, proofIndexes)).to.revertedWith('caller is not IDO')
  })
  it('Should not mint if the user does not have stakes', async () => {
    const IDOROLE = await Stakes.IDO_ROLE();
    console.log({IDOROLE});
    
    await Stakes.grantRole( IDOROLE,IDO.address)
    await paymentToken.approve(IDO.address, parseEther((nftTestAmount * +_mintPrice).toString()))
    await expect(IDO.mint(nftTestAmount, proofIndexes)).to.revertedWith('No Participation with zero stakes')
  })
  it('user should be able to stake', async () => {
    // create 3 pools 
    const amount = parseEther((nftTestAmount ).toString());
    await idoToken.approve(Stakes.address, amount);
    const allowance = await idoToken.allowance(wallet.address, Stakes.address);
    const balance = await idoToken.balanceOf(wallet.address);
    console.log({allowance,balance});
    
    await expect(Stakes.deposit(wallet.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(0);
    await idoToken.approve(Stakes.address, amount);
    await expect(Stakes.deposit(wallet.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(1);
    await idoToken.approve(Stakes.address, amount);
    await expect(Stakes.deposit(wallet.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(2);
  })
  it('Should not mint if the price is less than the minPrice', async () => {
    await paymentToken.approve(IDO.address, parseEther((0 * +_mintPrice).toString()))
  await provider.send('evm_increaseTime', [timestampBefore + 5000000000 + _lockDuration])
    await provider.send('evm_mine', [])  
    await expect(IDO.mint(nftTestAmount, proofIndexes)).to.revertedWith('Insufficient price value')
  })
  it('user can  unstake / withdraw part of the unlocked stake', async () => {
    const blockNumBefore = await provider.getBlockNumber()
    const blockBefore = await provider.getBlock(blockNumBefore)
    timestampBefore = blockBefore.timestamp
    await provider.send('evm_increaseTime', [timestampBefore + 5000000000 + _lockDuration])
    await provider.send('evm_mine', [])
    const amount = parseEther("1")
    const userReserveBefore = await Stakes.getReserves(wallet.address)
    await expect(Stakes.withdraw(amount, [0])).to.emit(Stakes, 'WithdrawFunds')
    const userPool0 = await Stakes.getUserPoolDetails(wallet.address, [0])
    const userReserveAfter = await Stakes.getReserves(wallet.address)

    await expect(userReserveBefore).to.not.eq(userReserveAfter)
    await expect(userPool0.amount).to.not.eq(amount)
    await expect(userPool0.unlocked).to.true.eq(true)
    await expect(userPool0.reservedToIDO).to.eq(false)
  })
  it('Should  mint', async () => {
    await paymentToken.approve(IDO.address, parseEther((nftTestAmount * +_mintPrice).toString()))
 
    await expect(await IDO.mint(nftTestAmount, proofIndexes)).to.emit(idoToken, 'Transfer')
    const ava = await IDO.availableTokenCount();
    console.log({ava});
    
  })

  it('Non Owner Should not call withdraw', async () => {
    await expect(IDO.connect(other).withdraw()).to.revertedWith('Ownable: caller is not the owner')
  })
  it(' Owner can withdraw', async () => {
    await expect(await IDO.connect(wallet).withdraw()).to.emit(IDO, 'Withdrawn')
  })
})
