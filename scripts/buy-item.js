const { ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID = 3

async function buyItem() {
    
    const nftMarketplace = await ethers.getContract("NftMarketplace")
    const basicNft = await ethers.getContract("BasicNft")
    const listing = await nftMarketplace.getListing(basicNft.address, TOKEN_ID)
    const price = listing.price.toString()   
    console.log(11111111111111111111111)
    const tokenOwner = await basicNft.ownerOf(TOKEN_ID);
    console.log(222222222222222222)
    if (tokenOwner == ethers.constants.AddressZero) {
      console.log(`NFT with ID ${TOKEN_ID} does not exist`);
    } else {
      console.log(`NFT with ID ${TOKEN_ID} exists and is owned by ${tokenOwner}`);
    }

    const tx = await nftMarketplace.buyItem(basicNft.address, TOKEN_ID, { value: price })
    await tx.wait(1)
    console.log("NFT Bought!")
    if ((network.config.chainId == "31337")) {
        await moveBlocks(2, (sleepAmount = 1000))
    }
}


buyItem()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })