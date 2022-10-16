const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Craps Unit Tests", () => {
        let crapsContract, vrfCoordinatorV2Mock, ante, player1, player2

        beforeEach(async () => {
            accounts = await ethers.getSigners()
            player1 = accounts[1]
            player2 = accounts[2]
            await deployments.fixture(["mocks", "craps"])
            vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
            crapsContract = await ethers.getContract("Craps")
            ante = await crapsContract.getAnte()
        })

        describe("constructor", () => {
            it("initializes the ante correctly", async () => {
                assert.equal(ante.toString(), networkConfig[network.config.chainId]["ante"])
            })
        })
    })
