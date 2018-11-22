pragma lity ^1.2.4;

contract BettingGame {
    
    address public owner;
    
    struct Bet {
        safeuint choice;
        safeuint amount;
        bool paid;
        bool initialized;
    }
    mapping(address => Bet) bets;
    
    string game_desc;
    safeuint number_of_choices;
    
    safeuint total_bet_amount;
    mapping(safeuint => safeuint) choice_bet_amounts;
    
    safeuint correct_choice;
    string correct_choice_txt;
    
    safeuint game_status; // 0 not started; 1 running; 2 ended
    
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    modifier onlyValidator() {
        require(isValidator(msg.sender));
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        game_status = 0;
    }
    
    function startGame(string _game_desc, safeuint _number_of_choices) external onlyOwner {
        game_desc = _game_desc;
        number_of_choices = _number_of_choices;
        
        total_bet_amount = 0;
        game_status = 1;
    }
    
    function placeBet (safeuint _choice) public payable {
        require (game_status == 1); // game is running
        require (_choice < number_of_choices); // Must be valid choice
        require (msg.value > 0); // Must have bet amount
        require (bets[msg.sender].initialized == false); // Cannot bet twice
        
        Bet memory newBet = Bet(_choice, msg.value, false, true);
        bets[msg.sender] = newBet;
        
        choice_bet_amounts[_choice] = choice_bet_amounts[_choice] + msg.value;
        total_bet_amount = total_bet_amount + msg.value;
    }
    
    function endGame(safeuint _correct_choice, string _correct_choice_txt) external onlyOwner {
        correct_choice = _correct_choice;
        correct_choice_txt = _correct_choice_txt;
        game_status = 2;
    }
    
    function payMe () public {
        require (game_status == 2); // game is done
        require (bets[msg.sender].initialized); // Must have a bet
        require (bets[msg.sender].amount > 0); // More than zero
        require (bets[msg.sender].choice == correct_choice); // chose correctly
        require (bets[msg.sender].paid == false); // chose correctly
        
        safeuint payout = bets[msg.sender].amount * total_bet_amount / choice_bet_amounts[correct_choice];
        if (payout > 0) {
            msg.sender.transfer(uint256(payout));
            bets[msg.sender].paid == true; // cannot claim twice
        }
    }
    
    function checkStatus (address _addr) public view returns (safeuint, safeuint, safeuint, bool) {
        require (game_status == 2); // game is done
        require (bets[_addr].initialized); // Must have a bet
        
        safeuint payout = 0;
        if (bets[_addr].choice == correct_choice) {
            payout = bets[_addr].amount * total_bet_amount / choice_bet_amounts[correct_choice];
        }
        
        return (bets[_addr].choice, bets[_addr].amount, payout, bets[_addr].paid);
    }
    
    function getAnswer() public view returns (safeuint, string) {
        return (correct_choice, correct_choice_txt);
    }
    
    function terminate() external onlyOwner {
        selfdestruct(owner);
    }
}
