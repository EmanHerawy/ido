import { Contract, Wallet } from 'ethers'
import { deployContract, MockProvider } from 'ethereum-waffle'

import { expandTo18Decimals } from './utilities'

import ERC20 from '../../artifacts/contracts/test-supplements-contracts/AnyERC20.sol/AnyERC20.json'

interface ContractsFixture {
  paymentToken: Contract
  idoToken:Contract
 
}

 const name1 = 'paymentToken'
const symbol1 = 'apt'
 const name2 = 'IdoToken'
const symbol2 = 'IDOT'
 
export async function tokenFixture([wallet]: Wallet[], _: MockProvider): Promise<ContractsFixture> {
  const paymentToken = await deployContract(wallet, ERC20, [name1, symbol1, expandTo18Decimals(10000000000000), wallet.address])
  const idoToken = await deployContract(wallet, ERC20, [name2, symbol2, expandTo18Decimals(100000000000000), wallet.address])
   
  return {  paymentToken,idoToken }
}
