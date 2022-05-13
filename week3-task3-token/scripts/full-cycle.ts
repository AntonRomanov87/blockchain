import { ethers, run } from "hardhat";

import { MyToken__factory, MyGovernor__factory } from "../typechain-types";

async function main() {
  const accounts = await ethers.getSigners();
  const signer   = accounts[0];

  console.log("Deploying token...");
  const token = await new MyToken__factory(signer).deploy();
  console.log("Waiting to be deployed...");
  await token.deployed();
  console.log('Token deployed to: ', token.address);
  console.log("Signer balance of MyTokens:", await token.provider.getBalance(signer.address));
  console.log("\n\n");

  console.log("Deploying governor...");
  const governor = await new MyGovernor__factory(signer).deploy(token.address);
  await governor.deployed();
  console.log("Governor deployed to: ", governor.address);
  console.log("\n\n");

  console.log("Creating proposal...");
  const tokenByAddr = await ethers.getContractAt("ERC20", token.address);
  const teamAddress = accounts[1];
  const grantAmount = 1000000;
  const transferCalldata = tokenByAddr.interface.encodeFunctionData("transfer", [teamAddress, grantAmount]);
  
  const addProposalResult = await governor.propose(
    [token.address],
    [0],
    [transferCalldata],
    'Proposal #1: Give grant to team',
  );

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
