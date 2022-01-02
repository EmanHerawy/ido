import { Contract, Wallet } from 'ethers'
import { deployContract, MockProvider } from 'ethereum-waffle'

import { expandTo18Decimals } from './utilities'

import ERC20 from '../../artifacts/contracts/test-supplements-contracts/AnyERC20.sol/AnyERC20.json'

interface ContractsFixture {
  paymentToken: Contract
 
}

 const name1 = 'paymentToken'
const symbol1 = 'apt'
 
export async function tokenFixture([wallet]: Wallet[], _: MockProvider): Promise<ContractsFixture> {
  const paymentToken = await deployContract(wallet, ERC20, [name1, symbol1, expandTo18Decimals(100000000), wallet.address])
   
  return {  paymentToken }
}
