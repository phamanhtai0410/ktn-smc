import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { AddressZero } from 'ethers/constants'
import { bigNumberify } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'

import { getCreate2Address } from './shared/utilities'
import { factoryFixture } from './shared/fixtures'

import KatanaNftFactory from '../build/contracts/KatanaNftFactory.json'

chai.use(solidity)

const overrides = {
    gasLimit: 9999999
}

describe('KatanaNftFactory', async () => {
    it('')
})