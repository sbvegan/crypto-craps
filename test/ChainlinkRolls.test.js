const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Craps Unit Tests", () => {
        let craps, 
            crapsContract, 
            vrfCoordinatorV2Mock, 
            ante, 
            player1, 
            player2, 
            shooter,
            nonShooter,
            shooterAddress, 
            gameState, 
            die1,
            die2,
            dieSum,
            value

        beforeEach(async () => {
            accounts = await ethers.getSigners()
            player1 = accounts[1]
            player2 = accounts[2]
            await deployments.fixture(["mocks", "craps"])
            vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
            crapsContract = await ethers.getContract("Craps")
            ante = await crapsContract.getAnte()
        })

        describe("handling the come out", () => {

            beforeEach(async () => {
                // setup game contract
                ante = await crapsContract.getAnte()
                craps = crapsContract.connect(player1)
                await craps.joinGame({ value: ante})
                gameState = await crapsContract.getGameState()
                craps = crapsContract.connect(player2)
                await craps.joinGame({ value: ante })
                await crapsContract.selectShooter()
                await vrfCoordinatorV2Mock.fulfillRandomWords(1, crapsContract.address)
                shooterAddress = await crapsContract.getShooter()
                if (player1.address == shooterAddress) {
                    shooter = player1
                    nonShooter = player2
                } else {
                    shooter = player2 
                    nonShooter = player1
                }
            })

            it("should not let non-shooter roll", async () => {
                craps = crapsContract.connect(nonShooter)
                await expect(craps.rollTheComeOut()).to.be.revertedWith(
                    "Only shooters."
                )
            })

            it("should initially have invalid dice [0,0]", async () => {
                craps = crapsContract.connect(shooter)
                die1 = await craps.getDie1()
                die2 = await craps.getDie2()
                sum = await craps.getDiceSum()
                assert.equal(die1, 0)
                assert.equal(die2, 0)
                assert.equal(sum, 0)
            })

            it("should update emit a ComeOutRequested event", async () => {
                craps = crapsContract.connect(shooter)
                await expect(craps.rollTheComeOut())
                    .to.emit(crapsContract, "ComeOutRequested")
            })

            it("should update the dice to valid values after randomness is fulfilled", async () => {
                craps = crapsContract.connect(shooter)
                craps.rollTheComeOut()
                await vrfCoordinatorV2Mock.fulfillRandomWords(2, crapsContract.address)
                die1 = await craps.getDie1()
                die2 = await craps.getDie2()
                assert.isAbove(die1, 0)
                assert.isAbove(die2, 0)
                assert.isBelow(die1, 7)
                assert.isBelow(die2, 7)
            })
        })
    })
