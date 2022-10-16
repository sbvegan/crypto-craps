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

            it("should update the game state after player1 joins", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                const gameState = await craps.getGameState()
                assert.equal(gameState, 1) // ONE_PLAYER
            })

            it("should emit a PlayerJoined event after player1 joins", async () => {
                craps = crapsContract.connect(player1)
                txResponse = await craps.joinGame({ value: ante})
                txReceipt = await txResponse.wait(1)
                const player1EmittedAddress = txReceipt.events[0].args.player
                assert.equal(player1.address, player1EmittedAddress)
            })

            it("should not override s_player1 if it's already set", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                const contractPlayer1 = await craps.getPlayer1()
                assert.equal(player1.address, contractPlayer1)
            })
            
            it("should allow a second player to join the game", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                const contractPlayer2 = await craps.getPlayer2()
                assert.equal(player2.address, contractPlayer2)
            })

            it("should update the game state after player2 joins", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                const gameState = await craps.getGameState()
                assert.equal(gameState, 2) // TWO_PLAYERS
            })

            it("should emit a PlayerJoined event after player2 joins", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                txResponse = await craps.joinGame({ value: ante})
                txReceipt = await txResponse.wait(1)
                const player2EmittedAddress = txReceipt.events[0].args.player
                assert.equal(player2.address, player2EmittedAddress)
            })

            it("should revert on a full game (2 players already joined)", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                await expect(crapsContract.joinGame({ value: ante })).to.be.revertedWith(
                    "Craps__GameFull"
                )
            })

            it("should not allow existing players join again", async () => {
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                await expect(craps.joinGame({ value: ante })).to.be.revertedWith(
                    "Craps__PlayerAlreadyJoined"
                )
            })

            it("should not allow players to join without ante", async () => {
                craps = crapsContract.connect(player1)
                await expect(craps.joinGame()).to.be.revertedWith(
                    "Craps__IncorrectAnte"
                )
            })

            it("should not allow players to join with incorrect ante", async () => {
                craps = crapsContract.connect(player1)
                const incorrectAnte = ethers.utils.parseEther("1000")
                await expect(craps.joinGame({ value: incorrectAnte })).to.be.revertedWith(
                    "Craps__IncorrectAnte"
                )
            })
        })

        describe("selecting the shooter", () => {

            beforeEach(async () => {
                accounts = await ethers.getSigners()
                player1 = accounts[1]
                player2 = accounts[2]
                await deployments.fixture(["mocks", "craps"])
                vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
                crapsContract = await ethers.getContract("Craps")
                ante = await crapsContract.getAnte()
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
            })

            it("should update the state when the shooter is being selected", async () => {
                await crapsContract.selectShooter()
                const gameState = await craps.getGameState()
                assert.equal(gameState, 3) // SELECTING_SHOOTER
            })

            // todo: finish
            it("should revert if shooter has already been called", async () => {
                await crapsContract.selectShooter()
                const gameState = await craps.getGameState()
                assert.equal(gameState, 3) // SELECTING_SHOOTER
            })
        })
    })
