const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Craps Unit Tests", () => {
        let craps, crapsContract, vrfCoordinatorV2Mock, ante, player1, player2

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
            it("should initialize the ante correctly", async () => {
                assert.equal(ante.toString(), networkConfig[network.config.chainId]["ante"])
            })

            it("should start in the open state", async () => {
                const gameState = await crapsContract.getGameState()
                assert.equal(gameState, 0) // OPEN
            })
        })

        describe("joining the game", () => {
            it("should set the s_player1 variable", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                const contractPlayer1 = await craps.getPlayer1()
                assert.equal(player1.address, contractPlayer1)
            })

            it("should update the game state after player 1 joins", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                const gameState = await craps.getGameState()
                assert.equal(gameState, 1) // ONE_PLAYER
            })

            it("should not override s_player1 if it's already set", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                const contractPlayer1 = await craps.getPlayer1()
                assert.equal(player1.address, contractPlayer1)
            })
            
            // it("allows the second player to join the game", async () => {})
            
        })
    })
