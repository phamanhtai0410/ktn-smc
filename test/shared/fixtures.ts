import { Contract, Wallet } from 'ethers'
import { Web3Provider } from 'ethers/providers'
import { deployContract } from 'ethereum-waffle'
import { AddressZero } from 'ethers/constants'

import { expandTo18Decimals } from './utilities'

import KatanaNftFactory from '../../build/contracts/KatanaNftFactory.json'

interface FactoryFixture {
  factory: Contract
}

const overrides = {
  gasLimit: 9999999
}

export async function factoryFixture(_: Web3Provider, [wallet]: Wallet[]): Promise<FactoryFixture> {
  const factory = await deployContract(wallet, KatanaNftFactory, [AddressZero], overrides)
  return { factory }
}
