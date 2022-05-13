import { ethers, run } from "hardhat";

import { MyToken__factory } from "../typechain-types";

async function main() {
  const [signer] = await ethers.getSigners();

  console.log("Deploying...");
  const tokenContract = await new MyToken__factory(signer).deploy();
  console.log("Waiting to be deployed...");
  await tokenContract.deployed();
  console.log('tokenContract deployed to:', tokenContract.address);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
