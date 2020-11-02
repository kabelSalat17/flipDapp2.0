const web3 = new Web3(Web3.givenProvider);
let contractInstance;
const address = "0x0119B8D503E325270CeaA92F5e63E5Cec6F0773f"

$(document).ready(function() {
    window.ethereum.enable().then(( accounts )=> {
        contractInstance = new web3.eth.Contract(abi, address, {from: accounts[0]});
        console.log(contractInstance);
        getContractBalance(address)
        getAddressBalance(accounts[0])

    });

    $("#payToPlay_button").click(payToPlay)
    $("#bet_button").click( () => {
        $(".coin").addClass("animate");
        bet()
    })
    $("#withdrawAll_button").click(withDrawAll)
    $("#withdraw_button").click(withDraw)
    
});

function getAddressBalance( account ) {
    contractInstance.methods.balances(account)
    .call()
    .then((res) => {
       $("#mybalance").text(web3.utils.fromWei(res, "ether"))
    })
}

function getContractBalance() {
    contractInstance.methods.contractBalance()
    .call()
    .then((res) => {
       $("#balance").text(web3.utils.fromWei(res, "ether"))
    })
}

function payToPlay() {

    const config = {
        value: web3.utils.toWei("0.1", "ether")
    }

    contractInstance.methods.payToPlay()
        .send(config)
        .on("transactionHash", (hash) => {
            console.log(hash)
        })
        .on("confirmation", (confirmationNr) => {
            // console.log(confirmationNr);
        })
        .on("receipt", (receipt) => {
            // console.log(receipt);
            location.reload();
        })
}

function bet() {
    const betValue = $("#bet").val()
    const config = {
        value: web3.utils.toWei( betValue, "ether")
    }

    contractInstance.methods.bet()
        .send(config)
        .on("transactionHash", (hash) => {
            console.log(hash)
        })
        .on("confirmation", (confirmationNr) => {
            // console.log(confirmationNr);
        })
        .on("receipt", (receipt) => {
            // console.log(receipt);
        })

        contractInstance.events.EndBetEvent(function(error, event){ 
            console.log(event.returnValues);
            if(event.returnValues.result) {
                $("#result").append(
                    "<div class='alert alert-success' role='alert'>You Won!</div>"
                )
            } else {
                $("#result").append(
                    "<div class='alert alert-danger' role='alert'>You Lost!</div>"
                )
            }
            $(".coin").removeClass("animate")
            location.reload();
        })

}
function withDraw() {
    contractInstance.methods.withDraw().send()
    .then(()=> {
        location.reload();
    } )
}
function withDrawAll() {
    contractInstance.methods.withdrawAll().send()
    .then(()=> {
        location.reload();
    } )
}
