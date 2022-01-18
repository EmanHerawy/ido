import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { waffle } from 'hardhat'
const { solidity, deployContract, createFixtureLoader, provider } = waffle

import { tokenFixture } from './shared/fixtures'
import { expandTo18Decimals } from './shared/utilities'

import StartfiIDO from '../artifacts/contracts/AirdropedStartfiIDOWithStaking.sol/AirdropedStartfiIDOWithStaking.json'
 import { parseEther } from 'ethers/lib/utils'
chai.use(solidity)
let timestampBefore = 0
const _maxSupply = expandTo18Decimals(8888)
const nftTestAmount = expandTo18Decimals(2700)
const _startTimeSale = 0

const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
const _mintPrice = parseEther((1).toString()).toString()
const _lockDuration = 60 * 60 * 24
describe('AirdropedStartfiIDOWithStaking', () => {
  const [wallet, other, user1, user2, user3] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other, user1, user2, user3])
  const whitelist = ["0xa797167f70aC0f9FFF23b628f14cd6a728500FF1",
    "0x0DF35aCfB9a204Ee32d5A9D57Aa3a06d391eBd4a",
    "0x7e33ca6d5fe6a06ae484E81262ACB74919Dc25fb",
    "0x246E6F3aB039A9510F811bf2B6916C325703B141", wallet.address, other.address];
  let idoToken: Contract
  let paymentToken: Contract
  let IDO: Contract
   before(async () => {
    const fixture = await loadFixture(tokenFixture)

    paymentToken = fixture.paymentToken
     idoToken = fixture.idoToken
 
    await paymentToken.connect(wallet).transfer(other.address, expandTo18Decimals(500))
     IDO = await deployContract(wallet, StartfiIDO, [
      _startTimeSale,
      _mintPrice,
      _maxSupply,
      _lockDuration,
      _wallets,
      paymentToken.address,
       idoToken.address,
      wallet.address,
    ])
    await IDO.setWhiteList(whitelist);
    // transfer tokens 

   })

  it('name, symbol,  wallets,mintPrice,maxToMintPerAddress,maxSupply,reserved', async () => {
    expect(await IDO.maxSupply()).to.eq(_maxSupply)
  })

  it('Should not mint if the sale is not started', async () => {

    await paymentToken.approve(IDO.address,nftTestAmount .mul(_mintPrice))
    await expect(IDO.mint(nftTestAmount )).to.revertedWith('Sale did not start yet')
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
  
  it('Should not mint if the user does not have stakes', async () => {
   await paymentToken.approve(IDO.address, nftTestAmount .mul(_mintPrice))
    await expect(IDO.mint(nftTestAmount )).to.revertedWith('No Participation with zero stakes')
  })
  it('user should be able to stake', async () => {
    // create 3 pools 
    const amount = nftTestAmount// parseEther((nftTestAmount ).toString());
    await idoToken.approve(IDO.address, amount);
    const allowance = await idoToken.allowance(wallet.address, IDO.address);
    const balance = await idoToken.balanceOf(wallet.address);
    console.log({allowance,balance});
    
    await expect(IDO.deposit( amount)).to.emit(IDO, 'DepositFunds')
     await idoToken.approve(IDO.address, amount);
    await expect(IDO.deposit( amount)).to.emit(IDO, 'DepositFunds')
     await idoToken.approve(IDO.address, amount);
    await expect(IDO.deposit( amount)).to.emit(IDO, 'DepositFunds')
   })
  it('Should not mint if the price is less than the minPrice', async () => {
    await paymentToken.approve(IDO.address, parseEther((0 * +_mintPrice).toString()))
  await provider.send('evm_increaseTime', [timestampBefore + 5000000000 + _lockDuration])
    await provider.send('evm_mine', [])  
    await expect(IDO.mint(nftTestAmount)).to.revertedWith('Insufficient price value')
  })

  it('Should  mint', async () => {
    await paymentToken.approve(IDO.address, nftTestAmount .mul(_mintPrice))
 
    await expect(await IDO.mint("10" )).to.emit(IDO, 'AirDropRequested')
  })

  it('Non Owner Should not call unstake', async () => {
    await expect(IDO.connect(other).withdraw()).to.revertedWith('Ownable: caller is not the owner')
  })
  it(' Owner can withdraw', async () => {
    await expect(await IDO.connect(wallet).withdraw()).to.emit(IDO, 'Withdrawn')
  })
})

describe('AirdropedStartfiIDOWithStaking 2 staking', () => {
  const [wallet, other, user1, user2, user3] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other, user1, user2, user3])
  const whitelist = ["0xa797167f70aC0f9FFF23b628f14cd6a728500FF1",
    "0x0DF35aCfB9a204Ee32d5A9D57Aa3a06d391eBd4a",
    "0x7e33ca6d5fe6a06ae484E81262ACB74919Dc25fb",
    "0x246E6F3aB039A9510F811bf2B6916C325703B141", wallet.address, other.address];
  let idoToken: Contract
  let paymentToken: Contract
  let IDO: Contract
   before(async () => {
 
    const fixture = await loadFixture(tokenFixture)

    paymentToken = fixture.paymentToken
     idoToken = fixture.idoToken
 
    await paymentToken.connect(wallet).transfer(other.address, expandTo18Decimals(500))
     IDO = await deployContract(wallet, StartfiIDO, [
      _startTimeSale,
      _mintPrice,
      _maxSupply,
      _lockDuration,
      _wallets,
      paymentToken.address,
       idoToken.address,
      wallet.address,
    ])
     await IDO.setWhiteList(whitelist);
         await idoToken.transfer(other.address, _maxSupply.mul(100))

  })

  it('check lock duration', async () => {
    expect(await IDO.lockDuration()).to.eq(_lockDuration)
  })
  it('check staking token', async () => {
    expect(await IDO.stakingToken()).to.eq(idoToken.address)
  })

  it('Should not deposit if the contract is paused', async () => {
    await IDO.pause()
    const amount = nftTestAmount
    await idoToken.approve(IDO.address, amount)
    await expect(IDO.deposit( amount)).to.be.reverted
  })
  it('user should be able to stake if not paused', async () => {
    // create 3 pools
    const amount = nftTestAmount
    await idoToken.approve(IDO.address, amount)
    await IDO.unpause()

    const allowance = await idoToken.allowance(wallet.address, IDO.address)
    const balance = await idoToken.balanceOf(wallet.address)
    console.log({ allowance, balance })

    await expect(IDO.deposit( amount)).to.emit(IDO, 'DepositFunds')
     await idoToken.approve(IDO.address, amount)
    await expect(IDO.deposit( amount)).to.emit(IDO, 'DepositFunds')
     await idoToken.approve(IDO.address, amount)
    await expect(IDO.deposit( amount)).to.emit(IDO, 'DepositFunds')
   })
  it('user can not unstake / withdraw locked stake', async () => {
    const amount = nftTestAmount
    const userReserveBefore = await IDO.getReserves(wallet.address)
    await expect(IDO.unstake(amount )).to.revertedWith('Fund is locked now')
    const userReserveAfter = await IDO.getReserves(wallet.address)

    await expect(userReserveBefore).to.eq(userReserveAfter)

 
  })
  it('user can  unstake / withdraw unlocked stake', async () => {
    const blockNumBefore = await provider.getBlockNumber()
    const blockBefore = await provider.getBlock(blockNumBefore)
    timestampBefore = blockBefore.timestamp
    await provider.send('evm_increaseTime', [timestampBefore + 5000000000 + _lockDuration])
    await provider.send('evm_mine', [])
    const amount = nftTestAmount
    const userReserveBefore = await IDO.getReserves(wallet.address)
    await expect(IDO.unstake(amount )).to.emit(IDO, 'WithdrawFunds')
     const userReserveAfter = await IDO.getReserves(wallet.address)

    await expect(userReserveBefore).to.not.eq(userReserveAfter)
   
  })

 

  it('user should not be able to call emergencyWithdraw  if not paused', async () => {
    // create 3 pools
    const amount = nftTestAmount
    await idoToken.connect(other).approve(IDO.address, amount)
        await expect(IDO.connect(other).deposit( amount)).to.emit(IDO, 'DepositFunds')
     await idoToken.connect(other).approve(IDO.address, amount)
    await expect(IDO.connect(other).deposit( amount)).to.emit(IDO, 'DepositFunds')
     await expect(IDO.connect(other).emergencyUnstake( amount)).to.revertedWith('Pausable: not paused')
  })
  it('Non Owner Should not call updateLockDuration', async () => {
    const newDuration = 50000
    await expect(IDO.connect(other).updateLockDuration(newDuration)).to.revertedWith('caller is not the owner')
  })
  it(' Owner Should not call updateLockDuration when not paused', async () => {
    const newDuration = 60 * 60 * 24 * 5
    await expect(IDO.connect(wallet).updateLockDuration(newDuration)).to.revertedWith('Pausable: not paused')
  })
  it(' Owner can updateLockDuration when contract is paused', async () => {
    await IDO.pause()

    const newDuration = 60 * 60 * 24 * 5
    await expect(IDO.connect(wallet).updateLockDuration(newDuration)).to.emit(IDO, 'ChangeLockDuration')
    expect(await IDO.lockDuration()).to.eq(newDuration)
  })

  it('user should  be able to call emergencyWithdraw  when paused even before lock time', async () => {
    // create 3 pools
    const amount = nftTestAmount
   
     const userReserveBefore = await IDO.getReserves(other.address)
    await expect(IDO.connect(other).emergencyUnstake(amount)).to.emit(IDO, 'WithdrawFunds')
     const userReserveAfter = await IDO.getReserves(other.address)

    await expect(userReserveBefore).to.not.eq(userReserveAfter)
      
  })
})
