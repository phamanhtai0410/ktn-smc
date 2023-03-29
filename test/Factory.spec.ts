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

describe('KatanaNftFactory', () => {
    const provider = new MockProvider({
        hardfork: 'istanbul',
        mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
        gasLimit: 9999999
    })
    const [wallet, other] = provider.getWallets()
    const loadFixture = createFixtureLoader(provider, [wallet, other])

    let factory: Contract

    beforeEach(async () => {
        const fixture = await loadFixture(factoryFixture)
        factory = fixture.factory
    })

    it('create_new_collection', async () => {

    })
})