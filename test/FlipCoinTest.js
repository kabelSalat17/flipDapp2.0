const FlipCoin = artifacts.require("FlipCoin");
const truffleAssert = require("truffle-assertions");

contract("FlipCoin", async function(accounts){
    
    let instance;

    before(async () => {
        instance = await FlipCoin.deployed();
    });

    it("should be possible to increase funds with minimum 1 eth", async () => {
        await truffleAssert.passes(instance.payToStart({value: web3.utils.toWei("1","ether"), from:accounts[1]}), truffleAssert.ErrorType.REVERT);
    }); 
    it("shouldn't be possible to increase funds with less than 1 Ether ", async function(){
        await truffleAssert.fails(instance.payToStart({value: web3.utils.toWei("0.9","ether"), from:accounts[1]}), truffleAssert.ErrorType.REVERT);
    });
    it("shouldn't be possible to withdraw contract funds for non contract owner", async function(){
        await truffleAssert.fails(instance.withdrawAll({from:accounts[1]}), truffleAssert.ErrorType.REVERT);
    });
    it("should be possible to withdraw contract funds for contract owner", async function(){
        await truffleAssert.passes(instance.withdrawAll({from:accounts[0]}), truffleAssert.ErrorType.REVERT);
    });

});