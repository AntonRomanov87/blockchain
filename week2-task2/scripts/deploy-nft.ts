import { ethers, run } from 'hardhat'

import { FractalNFT__factory } from '../typechain-types'

async function main() {
  const [signer] = await ethers.getSigners()

  const fractalNFT = await new FractalNFT__factory(signer).deploy()

  await fractalNFT.deployed()

  console.log('FractalNFT deployed to:', fractalNFT.address)

  await fractalNFT.safeMint(
    signer.address,
    'https://bafybeiak2bn6dcucitmpyhxce2oksyi66fw2f7iycy7b3zbj5dm7wb4nau.ipfs.infura-ipfs.io/'
  )

  await run('verify:verify', {
    address: fractalNFT.address,
    contract: 'contracts/FractalNFT.sol:FractalNFT'
  })
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
