import { expect } from 'chai'
import { Wallet } from 'ethers'
import { ethers } from 'hardhat'

import { MyToken__factory, MyGovernor__factory } from '../typechain-types'

describe('Airdrop', () => {
  it('Full Cycle', async () => {
    const [signer, guy] = await ethers.getSigners();

    const token = await new MyToken__factory(signer).deploy();

    // const governor = await new MyGovernor__factory(signer).deploy();

    
  })
})