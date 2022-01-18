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

let proofIndexes: any = []
const _lockDuration = 60 * 60 * 24
function* generateSequence(start: number, end: number) {
  for (let i = start; i <= end; i++) {
    yield i
  }
}
describe('StartfiStakes', () => {
  const [wallet, other, user1, user2, user3] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other, user1, user2, user3])

  let idoToken: Contract
  let Stakes: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)

    idoToken = fixture.idoToken
    Stakes = await deployContract(wallet, StartFiStakes, [idoToken.address, wallet.address, _lockDuration])

    // transfer tokens
    await idoToken.transfer(other.address, _maxSupply)
  })

  it('check lock duration', async () => {
    expect(await Stakes.lockDuration()).to.eq(_lockDuration)
  })
  it('check staking token', async () => {
    expect(await Stakes.stakingToken()).to.eq(idoToken.address)
  })

  it('Should not deposit if the contract is paused', async () => {
    await Stakes.pause()
    const amount = parseEther(nftTestAmount.toString())
    await idoToken.approve(Stakes.address, amount)
    await expect(Stakes.deposit(wallet.address, amount)).to.be.reverted
  })
  it('user should be able to stake if not paused', async () => {
    // create 3 pools
    const amount = parseEther(nftTestAmount.toString())
    await idoToken.approve(Stakes.address, amount)
    await Stakes.unpause()

    const allowance = await idoToken.allowance(wallet.address, Stakes.address)
    const balance = await idoToken.balanceOf(wallet.address)
    console.log({ allowance, balance })

    await expect(Stakes.deposit(wallet.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(0)
    await idoToken.approve(Stakes.address, amount)
    await expect(Stakes.deposit(wallet.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(1)
    await idoToken.approve(Stakes.address, amount)
    await expect(Stakes.deposit(wallet.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(2)
  })
  it('user can not unstake / withdraw locked stake', async () => {
    const amount = parseEther(nftTestAmount.toString())
    const userReserveBefore = await Stakes.getReserves(wallet.address)
    await expect(Stakes.withdraw(amount, [0])).to.revertedWith('fund is locked or already released')
    const userReserveAfter = await Stakes.getReserves(wallet.address)

    await expect(userReserveBefore).to.eq(userReserveAfter)

    const userPool0 = await Stakes.getUserPoolDetails(wallet.address, [0])

    await expect(userPool0.amount).to.eq(amount)
    await expect(userPool0.unlocked).to.eq(false)
    await expect(userPool0.reservedToIDO).to.eq(false)
  })
  it('user can  unstake / withdraw unlocked stake', async () => {
    const blockNumBefore = await provider.getBlockNumber()
    const blockBefore = await provider.getBlock(blockNumBefore)
    timestampBefore = blockBefore.timestamp
    await provider.send('evm_increaseTime', [timestampBefore + 5000000000 + _lockDuration])
    await provider.send('evm_mine', [])
    const amount = parseEther(nftTestAmount.toString())
    const userReserveBefore = await Stakes.getReserves(wallet.address)
    await expect(Stakes.withdraw(amount, [0])).to.emit(Stakes, 'WithdrawFunds')
    const userPool0 = await Stakes.getUserPoolDetails(wallet.address, [0])
    const userReserveAfter = await Stakes.getReserves(wallet.address)

    await expect(userReserveBefore).to.not.eq(userReserveAfter)
    await expect(userPool0.amount).to.not.eq(amount)
    await expect(userPool0.unlocked).to.true.eq(true)
    await expect(userPool0.reservedToIDO).to.eq(false)
  })

  it('Should not call validateStakes if the caller is not granted the IDO Role in stakes contract', async () => {
    await expect(Stakes.validateStakes(wallet.address, [0, 1, 2])).to.revertedWith('caller is not IDO')
  })

  it('user should not be able to call emergencyWithdraw  if not paused', async () => {
    // create 3 pools
    const amount = parseEther(nftTestAmount.toString())
    await idoToken.connect(other).approve(Stakes.address, amount)
    const allowance = await idoToken.allowance(wallet.address, Stakes.address)
    const balance = await idoToken.balanceOf(wallet.address)
    console.log({ allowance, balance })

    await expect(Stakes.connect(other).deposit(other.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(0)
    await idoToken.connect(other).approve(Stakes.address, amount)
    await expect(Stakes.connect(other).deposit(other.address, amount)).to.emit(Stakes, 'DepositFunds')
    proofIndexes.push(1)
    await expect(Stakes.connect(other).emergencyWithdraw([0, 1])).to.revertedWith('Pausable: not paused')
  })
  it('Non Owner Should not call updateLockDuration', async () => {
    const newDuration = 50000
    await expect(Stakes.connect(other).updateLockDuration(newDuration)).to.revertedWith('caller is not the owner')
  })
  it(' Owner Should not call updateLockDuration when not paused', async () => {
    const newDuration = 60 * 60 * 24 * 5
    await expect(Stakes.connect(wallet).updateLockDuration(newDuration)).to.revertedWith('Pausable: not paused')
  })
  it(' Owner can updateLockDuration when contract is paused', async () => {
    await Stakes.pause()

    const newDuration = 60 * 60 * 24 * 5
    await expect(Stakes.connect(wallet).updateLockDuration(newDuration)).to.emit(Stakes, 'ChangeLockDuration')
    expect(await Stakes.lockDuration()).to.eq(newDuration)
  })

  it('user should  be able to call emergencyWithdraw  when paused even before lock time', async () => {
    // create 3 pools
    const amount = parseEther(nftTestAmount.toString())
    const userPoolCount = await Stakes.getUserPoolLenght(other.address)
    console.log({userPoolCount});
     const userReserveBefore = await Stakes.getReserves(other.address)
    await expect(Stakes.connect(other).emergencyWithdraw([0, 1])).to.emit(Stakes, 'WithdrawFunds')
    const userPool0 = await Stakes.getUserPoolDetails(other.address, [0])
    const userReserveAfter = await Stakes.getReserves(other.address)

    await expect(userReserveBefore).to.not.eq(userReserveAfter)
    await expect(userPool0.amount).to.not.eq(amount)
     
  })
})
