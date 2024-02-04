import Time "mo:base/Time";
//import Principal "motoko/util/Principal";

module {

    public type Token = Principal;

    public type OrderId = Nat32;

    public type Bet = {
        id : Nat;
        game_id : Nat;
        walletAddress : Principal;
        dice_1 : Nat8;
        dice_2 : Nat8;
        time : Int;
    };

    public type ICPTransferArgs = {

        to : Blob;
        fee : { e8s : Nat64 };
        memo : Nat64;
        ///from_subaccount : Blob;
        //created_at_time : Nat;
        amount : { e8s : Nat64 };
    };
    public type Tokens = { e8s : Nat64 };

    public type TransferError_1 = {
        #TxTooOld : { allowed_window_nanos : Nat64 };
        #BadFee : { expected_fee : Tokens };
        #TxDuplicate : { duplicate_of : Nat64 };
        #TxCreatedInFuture;
        #InsufficientFunds : { balance : Tokens };
    };

    public type ClaimHistory = {
        time : Int;
        icp_transfer_index : Nat;
        reward_claimed : Nat;
    };

    public type Game = {
        id : Nat;
        var winner : Principal;
        var totalBet : Nat;
        time_created : Int;
        var time_ended : Int;
        var reward : Nat;
        var bets : [Bet];
        var bonus : Nat;
        var bonus_claimed : Bool;
        var bonus_winner : Principal;

    };

    public type GameBonus = {
        id : Nat;
        bonus : Nat;
    };

    public type CurrentGame = {
        id : Nat;
        winner : Principal;
        time_created : Int;
        time_ended : Int;
        reward : Nat;
        bets : [Bet];
        bonus : Nat;
        highestRoller : Principal;
        highestDice : Nat;
        totalReward : Nat;
        users : Nat;
        highestReward : Nat;

    };

    public type GameCheck = {
        #none;
        #ok : CurrentGame;
    };

    public type TicketPurchase = {
        id : Nat;
        walletAddress : ?Principal;
        time : Int;
        quantity : Nat;
        totalPrice : Nat;
        var icp_index : Nat;

    };

    public type PaidTicketPurchase = {
        id : Nat;
        walletAddress : ?Principal;
        time : Int;
        quantity : Nat;
        totalPrice : Nat;
        icp_index : Nat;
    };

    public type Migrateable = {
        #none : Nat;
        #ok : UserV2;
    };

    public type DiceResult = {
        #win;
        #lose : [Nat8];
        #extra : [Nat8];
        #closed;
        #noroll : [Nat];
        #transferFailed : Text;
        #highest : [Nat8];
        #absoluteHighest;
        #highestExtra : [Nat8];
        #zero;
        #legend;
    };

    public type TransferResult = {
        #success : Nat;
        #error : Text;

    };

    public type BookTicketResult = {
        #transferFailed : Text;
        #success : Nat;
    };

    public type User = {
        walletAddress : Principal;
        claimableReward : Nat;
        claimHistory : [ClaimHistory];
        purchaseHistory : [PaidTicketPurchase];
        gameHistory : [Bet];
        claimableBonus : [GameBonus];
        availableDiceRoll : Nat;
    };

    public type UserV2 = {
        walletAddress : Principal;
        claimableReward : Nat;
        claimHistory : [ClaimHistory];
        purchaseHistory : [PaidTicketPurchase];
        gameHistory : [Bet];
        claimableBonus : Nat;
        availableDiceRoll : Nat;
        alias : Principal;
    };

    public type Timestamp = Nat64;

    // First, define the Type that describes the Request arguments for an HTTPS outcall.

    public type HttpRequestArgs = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [HttpHeader];
        body : ?[Nat8];
        method : HttpMethod;
        transform : ?TransformRawResponseFunction;
    };

    public type HttpHeader = {
        name : Text;
        value : Text;
    };

    public type HttpMethod = {
        #get;
        #post;
        #head;
    };

    public type HttpResponsePayload = {
        status : Nat;
        headers : [HttpHeader];
        body : [Nat8];
    };

    // HTTPS outcalls have an optional "transform" key. These two types help describe it.
    // The transform function can transform the body in any way, add or remove headers, or modify headers.
    // This Type defines a function called 'TransformRawResponse', which is used above.

    public type TransformRawResponseFunction = {
        function : shared query TransformArgs -> async HttpResponsePayload;
        context : Blob;
    };

    // This Type defines the arguments the transform function needs.
    public type TransformArgs = {
        response : HttpResponsePayload;
        context : Blob;
    };

    public type CanisterHttpResponsePayload = {
        status : Nat;
        headers : [HttpHeader];
        body : [Nat8];
    };

    public type TransformContext = {
        function : shared query TransformArgs -> async HttpResponsePayload;
        context : Blob;
    };

    // Lastly, declare the IC management canister which you use to make the HTTPS outcall.
    public type IC = actor {
        http_request : HttpRequestArgs -> async HttpResponsePayload;
    };

};
