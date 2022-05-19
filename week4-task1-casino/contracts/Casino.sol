pragma solidity ^0.4.20;

contract Casino {
    address public owner;
    uint256 public minimumBet;
    uint256 public totalBet;
    uint256 public numberOfBets;
    uint256 public maxAmountOfBets = 3;

    address[] public players;

    struct Player {
        uint256 amountBet;
        uint256 numberSelected;
    }

    // The address of the player and => the user info
    mapping(address => Player) public playerInfo;

    event BetAccepted(address from, uint256 bet, uint totalValue);
    event WinNumber(uint256 winNumber);
    event WinAddress(address from, uint256 winnerEtherAmount);
 
    constructor(uint256 _minimumBet) public {
        owner = msg.sender;
        if(_minimumBet != 0 ) minimumBet = _minimumBet;
    }

    function kill() public {
        if(msg.sender == owner) selfdestruct(owner);
    }

    // To bet for a number between 1 and 10 both inclusive
    function bet(uint256 numberSelected) public payable {
        require(!checkPlayerExists(msg.sender));
        require(numberSelected >= 1 && numberSelected <= 10);
        require(msg.value >= minimumBet);
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].numberSelected = numberSelected;
        numberOfBets++;
        players.push(msg.sender);
        totalBet += msg.value;
        emit BetAccepted(msg.sender, numberSelected, totalBet);
        if(numberOfBets >= maxAmountOfBets) generateNumberWinner();
    }

    function checkPlayerExists(address player) public constant returns(bool){
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
    }

    // Generates a number between 1 and 10 that will be the winner
    function generateNumberWinner() public {
        uint256 numberGenerated = block.number % 10 + 1; // This isn't secure
        emit WinNumber(numberGenerated);          
        distributePrizes(numberGenerated);
    }

    // Sends the corresponding ether to each winner depending on the total bets
    function distributePrizes(uint256 numberWinner) public {
        address[100] memory winners; // We have to create a temporary in memory array with fixed size
        uint256 count = 0; // This is the count for the array of winners
        for(uint256 i = 0; i < players.length; i++){
            address playerAddress = players[i];
            if(playerInfo[playerAddress].numberSelected == numberWinner){
                winners[count] = playerAddress;
                count++;
            }
            delete playerInfo[playerAddress]; // Delete all the players
        }
        players.length = 0; // Delete all the players array  
        uint256 winnerEtherAmount = totalBet / winners.length; // How much each winner gets
        uint256 remainder = totalBet - winnerEtherAmount * winners.length;
        for(uint256 j = 0; j < count; j++){
            if(winners[j] != address(0)) // Check that the address in this fixed array is not empty
            winners[j].transfer(winnerEtherAmount);
            emit WinAddress(winners[j],winnerEtherAmount);
        }
        if (remainder != 0) {
          owner.transfer(remainder);
        }
        resetData();
    }

    function resetData() private {
        players.length = 0; // Delete all the players array
        totalBet = 0;
        numberOfBets = 0;
    }

    function() public payable {}
}