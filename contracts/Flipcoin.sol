import "./Ownable.sol";
import "./provableAPI.sol";

pragma solidity 0.5.16;

contract Flipcoin is Ownable, usingProvable {

    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;    
    bytes32 queryId;
    uint256 public latestNumber;

    constructor() public {
        provable_setProof(proofType_Ledger);
    }

    struct Bet {                                        
        address payable player;                         
        uint betValue;                                    
        bool result;                                   
    }

    uint public contractBalance;

    mapping(address => uint) public balances;
    mapping (bytes32 => Bet) public betList; 
    mapping(address => bool) public waitingList;

    // Events

    event StartBetEvent(address player, uint betValue, bytes32 Id);
    event EndBetEvent(address player, uint betValue, bytes32 Id, bool result);
    event LogNewProvableQuery(string description);
    event latestNumberEvent (uint256 latestNumber);

    modifier costs(uint cost){
        require(msg.value >= cost);
        _;
    }

    function payToPlay() public payable costs(0.1 ether) {
        require(msg.value != 0);
        contractBalance += msg.value;
    }

    function bet() public payable costs(0.001 ether) {

        //before to play requirements
        require(contractBalance!=0, "Nothing to win")
        require(msg.value/2 <= contractBalance, "Not enough funds to pay out");

        //player still waiting?
        require(waitingList[msg.sender] == false);

        // Step 1 //

        //Player start to wait the result
        waitingList[msg.sender] = true;

        // Step 2 //

        //ask oracle for random number
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;

        queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        //====> Step 3

        // New Bet added to betList // waiting for query resolved

        betList[queryId] = Bet(msg.sender,  msg.value, false);  

        emit StartBetEvent(msg.sender, msg.value, queryId);
        emit LogNewProvableQuery("Provable query was sent, standing by for answer...");

    }

    function __callback(bytes32 _queryId,string memory _result, bytes memory _proof) public {
        //Step 3
        require(msg.sender == provable_cbAddress());
        
        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            
        } else {

            uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;

            //Now we have the result //Betting is done //

            latestNumber = randomNumber;

            if(latestNumber == 0){
                betList[_queryId].result = false; // LOST
                contractBalance += betList[_queryId].betValue;
            }

            else if(latestNumber == 1){
                betList[_queryId].result = true; // WIN
                contractBalance -= betList[_queryId].betValue*2;
                balances[betList[_queryId].player] += betList[_queryId].betValue * 2;
            }

        }

        //Player stop waiting
        waitingList[betList[_queryId].player] = false;

        //Emit event to front end
        emit latestNumberEvent(latestNumber);
        emit EndBetEvent(betList[_queryId].player,betList[_queryId].betValue, _queryId, betList[_queryId].result);
    }

    function withDraw() public {
        require(waitingList[msg.sender] == false, "Still waiting...");
        require(balances[msg.sender] > 0, "No funds to withdraw");
        uint balanceToTransfer = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balanceToTransfer);
   }

   function withdrawAll() public onlyOwner returns(uint) {
        require(waitingList[msg.sender] == false);
        require(contractBalance > 0, "No funds to withdraw");
        uint toTransfer = contractBalance;
        contractBalance = 0;
        msg.sender.transfer(toTransfer);
        return toTransfer;
   }

}