import "@stdlib/deploy";

message Withdraw{
    amount: Int as coins;
}

message Payout{
    amount: Int as coins;

}

message Enter{
    fee: Int as coins;
    
}


contract Lottery with Deployable {
   owner: Address;  
   entryFee: Int as coins;
   maxParticipants: Int as int256;
   lotteryEndTime: Int;
   participants: map<Int, Address> = emptyMap();
   counter: Int as uint32;

    init() {
        self.owner = sender();
        self.entryFee = ton("0.5");
        self.maxParticipants = 10;
        self.lotteryEndTime = now() + (60*60);
        self.counter =0;
    }

    fun resetLottery(){
       require(sender() == self.owner, "sender is not owner"); 
       self.lotteryEndTime = now() + (60 * 60); // 1hour
       self.participants = emptyMap();
       self.counter = 0;
    }

    receive (msg: Enter) {
       require(now() < self.lotteryEndTime, "Lottery is over");  
       require(self.counter < self.maxParticipants, "Max Participants");  
       require(msg.fee == self.entryFee, "Please send the correct amount of TON");  
       self.participants.set(self.counter, sender());
       self.counter += 1;

        send(
            SendParameters{
                to: sender(),
                value: msg.fee,
                mode: SendIgnoreErrors,
                body: "entered Lottery"

            }
        )

    }

        receive (msg: Payout) {
        require(now() >= self.lotteryEndTime, "Lottery is over");
        require(self.counter > 0, "There are 0 participants");
        let totalAmount = self.entryFee * self.counter;
        let randomIndex = randomInt();
        let winner: Address = self.participants.get(randomIndex);
        send(
            SendParameters{
                to: winner,
                value: totalAmount,
                mode: SendIgnoreErrors,
                body: "Payout sent"

            }
        )
    }
        

    get fun ownerAddress(): Address {
        return self.owner;
    }
    get fun allItems(): map<Int, Address> {
        return self.participants;
    }
    get fun balance(): String {
        return myBalance().toCoinsString();
    }
}
