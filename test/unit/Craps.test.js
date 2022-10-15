const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Craps Unit Tests", () => {
        let crapsContract, ante, player1, player2

        beforeEach(async () => {
            accounts = await ethers.getSigners()
            player0 = accounts[0]
            player1 = accounts[1]
            // todo: deploy contracts
        })
    })
