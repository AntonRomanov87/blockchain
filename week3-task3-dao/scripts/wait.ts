import { ethers, network } from "hardhat"
import {
  FUNC,
  NEW_STORE_VALUE,
  PROPOSAL_DESCRIPTION,
  MIN_DELAY,
  developmentChains,
} from "../helper-hardhat-config"
import { moveBlocks } from "../utils/move-blocks"
import { moveTime } from "../utils/move-time"

export async function queueAndExecute() {
  const box = await ethers.getContract("Box")
  await moveTime(MIN_DELAY + 1)
  await moveBlocks(1)
  const value = await box.retrieve(); 
  console.log(value.toString());
}

queueAndExecute()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
