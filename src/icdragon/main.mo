import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Random "mo:base/Random";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Bool "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Time "mo:base/Time";
//import Tokens "mo:base/Tokens";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Char "mo:base/Char";
import { now } = "mo:base/Time";
import { abs } = "mo:base/Int";
import Account = "./account";
import { setTimer; cancelTimer; recurringTimer } = "mo:base/Timer";
import T "types";

import ICPLedger "canister:icp_ledger_canister";
//import ICPLedger "canister:icp_test";
import Eyes "canister:eyes";
//import CKBTC "canister:ckbtc_ledger";
//import LBTC "canister:lbtc";

shared ({ caller = owner }) actor class ICDragon({
  admin : Principal;
}) = this {
  //indexes

  private var siteAdmin : Principal = admin;
  private var dappsKey = "0xSet";

  stable var devPool : Principal = admin;
  stable var rewardPool : Principal = admin;

  //@dev--users
  private stable var gameIndex = 0;
  private stable var firstGameStarted = false;
  private stable var transactionIndex = 0;
  private stable var betIndex = 0;
  private stable var ticketIndex = 0;
  private stable var pause = false : Bool;
  private stable var ticketPrice = 50000000;
  private stable var eyesToken = false;
  private stable var eyesTokenDistribution = 10000000;
  private stable var eyesDays = 0;
  private stable var initialReward = 500000000;
  private stable var initialBonus = 50000000;
  private stable var timerId = 0;
  stable var nextTicketPrice = 50000000;
  private stable var startHalvingTimeStamp : Int = 0;
  private stable var nextHalvingTimeStamp : Int = 0;

  private var aliasHash = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);

  private var userTicketQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userListBackup = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userFirstHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userDoubleRollQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketPurchaseHash = HashMap.HashMap<Text, [T.PaidTicketPurchase]>(0, Text.equal, Text.hash);
  private var userClaimableHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimableBonusHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimHistoryHash = HashMap.HashMap<Text, [T.ClaimHistory]>(0, Text.equal, Text.hash);
  private var userBetHistoryHash = HashMap.HashMap<Text, [T.Bet]>(0, Text.equal, Text.hash);
  var bonusPoolbyWallet = HashMap.HashMap<Text, [Nat]>(0, Text.equal, Text.hash);
  private var blistHash = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);

  //@dev--variables and history
  var games = Buffer.Buffer<T.Game>(0);
  var ticketPurchaseHistory = Buffer.Buffer<T.TicketPurchase>(0);
  var betHistory = Buffer.Buffer<T.Bet>(0);

  //upgrade temp params
  stable var games_ : [T.Game] = []; // for upgrade
  stable var ticketPurchaseHistory_ : [T.TicketPurchase] = []; // for upgrade
  stable var betHistory_ : [T.Bet] = [];
  stable var currentHighestDice = 0;
  stable var currentHighestRoller = admin;
  stable var counter = 0;
  stable var rewardMilestone = 1000000000;
  stable var currentMilestone = 0;
  stable var currentTotalWins = 0;
  stable var currentHighestReward = 0;
  stable var currentReward = 0;

  stable var userTicketQuantityHash_ : [(Text, Nat)] = [];
  stable var blistHash_ : [(Text, Bool)] = [];
  stable var userFirstHash_ : [(Text, Nat)] = [];
  stable var userDoubleRollQuantityHash_ : [(Text, Nat)] = [];
  stable var userTicketPurchaseHash_ : [(Text, [T.PaidTicketPurchase])] = [];
  stable var userClaimableHash_ : [(Text, Nat)] = [];
  stable var userClaimableBonusHash_ : [(Text, Nat)] = [];
  stable var userClaimHistoryHash_ : [(Text, [T.ClaimHistory])] = [];
  stable var userBetHistoryHash_ : [(Text, [T.Bet])] = [];
  stable var timerStarted = false;
  stable var bonusPoolbyWallet_ : [(Text, [Nat])] = [];
  stable var aliasHash_ : [(Text, Text)] = [];
  stable var userListBackup_ : [(Text, Nat)] = [];

  //stable var transactionHash

  system func preupgrade() {
    games_ := Buffer.toArray<T.Game>(games);
    ticketPurchaseHistory_ := Buffer.toArray<T.TicketPurchase>(ticketPurchaseHistory);
    betHistory_ := Buffer.toArray<T.Bet>(betHistory);
    timerStarted := false;

    userTicketQuantityHash_ := Iter.toArray(userTicketQuantityHash.entries());
    userFirstHash_ := Iter.toArray(userFirstHash.entries());
    userDoubleRollQuantityHash_ := Iter.toArray(userDoubleRollQuantityHash.entries());
    userTicketPurchaseHash_ := Iter.toArray(userTicketPurchaseHash.entries());
    userClaimableHash_ := Iter.toArray(userClaimableHash.entries());
    userClaimableBonusHash_ := Iter.toArray(userClaimableBonusHash.entries());
    userClaimHistoryHash_ := Iter.toArray(userClaimHistoryHash.entries());
    userBetHistoryHash_ := Iter.toArray(userBetHistoryHash.entries());
    bonusPoolbyWallet_ := Iter.toArray(bonusPoolbyWallet.entries());
    blistHash_ := Iter.toArray(blistHash.entries());
    aliasHash_ := Iter.toArray(aliasHash.entries());
    userListBackup_ := Iter.toArray(userListBackup.entries());

  };
  system func postupgrade() {
    games := Buffer.fromArray<T.Game>(games_);
    ticketPurchaseHistory := Buffer.fromArray<T.TicketPurchase>(ticketPurchaseHistory_);
    betHistory := Buffer.fromArray<T.Bet>(betHistory_);

    userTicketQuantityHash := HashMap.fromIter<Text, Nat>(userTicketQuantityHash_.vals(), 1, Text.equal, Text.hash);
    userFirstHash := HashMap.fromIter<Text, Nat>(userFirstHash_.vals(), 1, Text.equal, Text.hash);
    userDoubleRollQuantityHash := HashMap.fromIter<Text, Nat>(userDoubleRollQuantityHash_.vals(), 1, Text.equal, Text.hash);
    userTicketPurchaseHash := HashMap.fromIter<Text, [T.PaidTicketPurchase]>(userTicketPurchaseHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableHash := HashMap.fromIter<Text, Nat>(userClaimableHash_.vals(), 1, Text.equal, Text.hash);
    userClaimableBonusHash := HashMap.fromIter<Text, Nat>(userClaimableBonusHash_.vals(), 1, Text.equal, Text.hash);
    userClaimHistoryHash := HashMap.fromIter<Text, [T.ClaimHistory]>(userClaimHistoryHash_.vals(), 1, Text.equal, Text.hash);
    userBetHistoryHash := HashMap.fromIter<Text, [T.Bet]>(userBetHistoryHash_.vals(), 1, Text.equal, Text.hash);
    bonusPoolbyWallet := HashMap.fromIter<Text, [Nat]>(bonusPoolbyWallet_.vals(), 1, Text.equal, Text.hash);
    blistHash := HashMap.fromIter<Text, Bool>(blistHash_.vals(), 1, Text.equal, Text.hash);
    aliasHash := HashMap.fromIter<Text, Text>(aliasHash_.vals(), 1, Text.equal, Text.hash);
    userListBackup := HashMap.fromIter<Text, Nat>(userListBackup_.vals(), 1, Text.equal, Text.hash);
  };

  public query (message) func getTimeNow() : async Int {
    assert (_isAdmin(message.caller));
    let tm = now() / 1000000;
    return tm;
  };

  public query (message) func getTicketPurchaseHash() : async [(Text, [T.PaidTicketPurchase])] {
    //assert (_isAdmin(message.caller));
    let a_ = Iter.toArray(userTicketPurchaseHash.entries());
    return a_;
  };

  /* MIGRATION FUNCTIONS */ ////////////////////////////////////////////
  public shared (message) func createBaseAddress() : async () {
    assert (_isAdmin(message.caller));
    var temp = Iter.toArray(userFirstHash.entries());
    userListBackup := HashMap.fromIter<Text, Nat>(temp.vals(), 1, Text.equal, Text.hash);
  };

  public shared (message) func isMigrateable(p : Text) : async T.Migrateable {
    if (Principal.toText(message.caller) == p) return #none(1);
    switch (userListBackup.get(p)) {
      case (?n) {
        return #ok(await getUserDataByWallet(p));
      };
      case (null) {
        return #none(1);
      };
    };
  };

  public shared (message) func getUserBets(p_ : Text) : async {
    #none : Nat;
    #ok : [T.Bet];
  } {
    assert (_isAdmin(message.caller));
    switch (userBetHistoryHash.get(p_)) {
      case (?x) {
        return #ok(x);
      };
      case (null) {
        return #none(1);
      };
    };
  };

  func _isMigrateable(p : Text) : async T.Migrateable {
    switch (userListBackup.get(p)) {
      case (?n) {
        return #ok(await getUserDataByWallet(p));
      };
      case (null) {
        return #none(1);
      };
    };
  };

  public shared (message) func getList() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userListBackup.entries());
  };

  public shared (message) func deleteAlias(p : Text) : async Bool {
    assert (_isAdmin(message.caller));
    aliasHash.delete(p);
    true;
  };
  public shared (message) func migrate(p : Text) : async Bool {
    if (Principal.toText(message.caller) == p) return false;
    switch (userListBackup.get(p)) {
      case (?n) {
        var a = await addAlias(p, Principal.toText(message.caller));
        var b = userListBackup.delete(p);
        return a;
      };
      case (null) {
        return false;
      };
    };

  };

  func addAlias(old_ : Text, new_ : Text) : async Bool {
    switch (userListBackup.get(old_)) {
      case (?n) {
        var newAddr = new_;
        switch (aliasHash.get(newAddr)) {
          case (?a) {
            return false;
          };
          case (null) {
            aliasHash.put(newAddr, old_);
            return true;
          };
        };

      };
      case (null) {
        return false;
      };
    };

  };

  public shared (message) func getAliasP(t : Text) : async Principal {
    var p = Principal.fromText(t);
    switch (aliasHash.get(Principal.toText(p))) {
      case (?a) {
        return Principal.fromText(a);
      };
      case (null) {
        //aliasHash.put(newAddr,old_);
        return p;
      };
    };

  };

  func getAlias(p : Principal) : Principal {
    switch (aliasHash.get(Principal.toText(p))) {
      case (?a) {
        return Principal.fromText(a);
      };
      case (null) {
        //aliasHash.put(newAddr,old_);
        return p;
      };
    };

  };
  //END OF MIGRATION FUNCTIONS ///////////////////////////////////

  public query (message) func getCounter() : async Nat {
    assert (_isAdmin(message.caller));
    return counter;
  };

  public query (message) func getNextHalving() : async Int {
    return nextHalvingTimeStamp;
  };

  public shared (message) func alterHalving(a : Int) : async Int {
    assert (_isAdmin(message.caller));
    nextHalvingTimeStamp := a;
    return nextHalvingTimeStamp;
  };

  //public shared (message) func migrate(old_ : Text, new_ : Text) : async () {
  //change value in
  /*

    if user exist in userList Backup

private var userTicketQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userListBackup = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userFirstHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userDoubleRollQuantityHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userTicketPurchaseHash = HashMap.HashMap<Text, [T.PaidTicketPurchase]>(0, Text.equal, Text.hash);
  private var userClaimableHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimableBonusHash = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
  private var userClaimHistoryHash = HashMap.HashMap<Text, [T.ClaimHistory]>(0, Text.equal, Text.hash);
  private var userBetHistoryHash = HashMap.HashMap<Text, [T.Bet]>(0, Text.equal, Text.hash);
  var bonusPoolbyWallet = HashMap.HashMap<Text, [Nat]>(0, Text.equal, Text.hash);
  private var blistHash = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
      */

  //@dev timers initialization, must be called every canister upgrades
  public shared (message) func startHalving(n : Int) : async Nat {

    assert (_isAdmin(message.caller));
    cancelTimer(timerId);
    startHalvingTimeStamp := n;
    nextHalvingTimeStamp := startHalvingTimeStamp;
    // Debug.print("stamp " #Int.toText(nextTimeStamp));
    if (startHalvingTimeStamp == 0) return 0;
    timerId := recurringTimer(
      #seconds(1),
      func() : async () {
        if (counter < 100) { counter += 10 } else { counter := 0 };
        let time_ = now() / 1000000;
        if (time_ >= nextHalvingTimeStamp) {
          //var n_ = now() / 1000000;
          nextHalvingTimeStamp := nextHalvingTimeStamp + (24 * 60 * 60 * 10 * 1000);
          eyesTokenDistribution := eyesTokenDistribution / 2;
          //counter := 200;
          //let res = halving();

          //schedulerSecondsInterval := 24 * 60 * 60;
          //cancelTimer(timerId);
          //halvingExecution();
          //timerId := halving();

        };
      },
    );

    timerId;
  };
  //timer : halving every 10 days
  func halving() : Nat {
    //cancelTimer(timerId);
    var n = recurringTimer(
      #seconds(24 * 60 * 60),
      func() : async () {
        if (counter < 300) { counter += 1 } else { counter := 0 };
        halvingExecution();
      },
    );
    timerStarted := true;
    timerId := n;
    return n;
  };

  func halvingExecution() {
    eyesDays += 1;
    if (eyesToken and eyesDays == 10) {
      eyesTokenDistribution := eyesTokenDistribution / 2;
      eyesDays := 0;
      var n_ = now() / 1000000;
      nextHalvingTimeStamp := n_ + (24 * 60 * 60 * 10 * 1000);
      //if(EyesDays==30)EyesToken:=false;
    };
  };

  public query (message) func blacklist(p : Text) : async Bool {
    assert (_isAdmin(message.caller));
    blistHash.put(p, true);
    true;
  };

  public query (message) func getUserTicketList() : async [(Text, Nat)] {
    assert (_isAdmin(message.caller));
    return Iter.toArray(userTicketQuantityHash.entries());
  };

  public query (message) func getHalving() : async Nat {
    return eyesDays;
  };

  public shared (message) func setHalving(d : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    eyesDays := d;
    return eyesDays;
  };

  public query (message) func getTimerStatus() : async Bool {
    return timerStarted;
  };

  private func natToFloat(nat_ : Nat) : Float {
    let toNat64_ = Nat64.fromNat(nat_);
    let toInt64_ = Int64.fromNat64(toNat64_);
    let amountFloat_ = Float.fromInt64(toInt64_);
    return amountFloat_;
  };

  func _isAdmin(p : Principal) : Bool {
    return (p == siteAdmin);
  };

  func _isApp(key : Text) : Bool {
    return (key == dappsKey);
  };

  func _isNotPaused() : Bool {
    if (pause) return false;
    true;
  };

  public query func isNotPaused() : async Bool {
    if (pause) return false;
    true;
  };

  public shared (message) func setDevPool(vault_ : Principal) : async Principal {
    assert (_isAdmin(message.caller));
    devPool := vault_;
    vault_;
  };

  public shared (message) func setRewardPool(vault_ : Principal) : async Principal {
    assert (_isAdmin(message.caller));
    rewardPool := vault_;
    vault_;
  };

  public shared (message) func setEyesToken(active_ : Bool) : async Bool {
    assert (_isAdmin(message.caller));
    eyesToken := active_;
    eyesToken;
  };

  public query (message) func getDevPool() : async Principal {
    devPool;
  };

  public query (message) func getRewardPool() : async Principal {
    rewardPool;
  };

  public query (message) func getTicketPrice() : async Nat {
    ticketPrice;
  };

  public query (message) func getNextTicketPrice() : async Nat {
    nextTicketPrice;
  };

  public shared (message) func setTicketPrice(price_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    ticketPrice := price_;
    nextTicketPrice := price_;
    ticketPrice;
  };

  public query (message) func getCurrentReward() : async Nat {
    //assert (_isAdmin(message.caller));
    let game_ = games.get(gameIndex);
    game_.reward;
  };

  public query (message) func getCurrentBonus() : async Nat {
    //assert (_isAdmin(message.caller));
    let game_ = games.get(gameIndex);
    game_.bonus;
  };

  public query (message) func getEyesDistribution() : async Nat {
    eyesTokenDistribution;
  };

  public shared (message) func setNextTicketPrice(price_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    nextTicketPrice := price_;
    price_;
  };

  public shared (message) func setAdmin(admin_ : Principal) : async Principal {
    assert (_isAdmin(message.caller));
    siteAdmin := admin_;
    siteAdmin;
  };

  public query (message) func getCurrentIndex() : async Nat {
    gameIndex;
  };

  public shared (message) func getUserByWallet(p_ : Text) : async T.UserV2 {
    assert (_isAdmin(message.caller));
    return await getUserDataByWallet(p_);
  };

  func getUserDataByWallet(p__ : Text) : async T.UserV2 {
    var p_ = Principal.toText(getAlias(Principal.fromText(p__)));
    var claimHistory_ = userClaimHistoryHash.get(p_);
    var claimHistory : [T.ClaimHistory] = [];
    switch (claimHistory_) {
      case (?c) {
        claimHistory := c;
      };
      case (null) {
        claimHistory := [];
      };
    };
    var claimable_ = userClaimableHash.get(p_);
    var claimable : Nat = 0;
    switch (claimable_) {
      case (?c) {
        claimable := c;
      };
      case (null) {
        claimable := 0;
      };
    };
    var purchase_ = userTicketPurchaseHash.get(p_);
    var purchase : [T.PaidTicketPurchase] = [];
    switch (purchase_) {
      case (?p) {
        purchase := p;
      };
      case (null) {
        //Debug.print("no purchase yet");
      };
    };
    var bets_ = userBetHistoryHash.get(p_);
    var bets : [T.Bet] = [];
    switch (bets_) {
      case (?b) {
        bets := b;
      };
      case (null) {
        //Debug.print("no bet yet");
      };
    };
    var remaining : Nat = 0;
    switch (userTicketQuantityHash.get(p_)) {
      case (?x) {
        remaining := x;
      };
      case (null) {
        remaining := 0;
        userTicketQuantityHash.put(p_, 0);
      };
    };
    var doubleRollRemaining : Nat = 0;
    switch (userDoubleRollQuantityHash.get(p_)) {
      case (?x) {
        doubleRollRemaining := x;
      };
      case (null) {
        doubleRollRemaining := 0;
        userDoubleRollQuantityHash.put(p_, 0);
      };
    };

    var bonusReward_ = 0;
    let userReward_ = userClaimableBonusHash.get(p_);
    switch (userReward_) {
      case (?r) {
        bonusReward_ := r;
      };
      case (null) {
        userClaimableBonusHash.put(p_, 0);
      };
    };

    let userData_ : T.UserV2 = {
      walletAddress = Principal.fromText(p_);
      claimableReward = claimable;
      claimHistory = claimHistory;
      purchaseHistory = purchase;
      gameHistory = bets;
      availableDiceRoll = remaining + doubleRollRemaining;
      claimableBonus = bonusReward_;
      alias = getAlias(Principal.fromText(p_));
    };
    //return user data
    userData_;
  };

  public shared (message) func getUserData() : async T.UserV2 {
    var p = getAlias(message.caller);
    var claimHistory_ = userClaimHistoryHash.get(Principal.toText(p));
    var claimHistory : [T.ClaimHistory] = [];
    switch (claimHistory_) {
      case (?c) {
        claimHistory := c;
      };
      case (null) {
        claimHistory := [];
      };
    };
    var claimable_ = userClaimableHash.get(Principal.toText(p));
    var claimable : Nat = 0;
    switch (claimable_) {
      case (?c) {
        claimable := c;
      };
      case (null) {
        claimable := 0;
      };
    };
    var purchase_ = userTicketPurchaseHash.get(Principal.toText(p));
    var purchase : [T.PaidTicketPurchase] = [];
    switch (purchase_) {
      case (?p) {
        purchase := p;
      };
      case (null) {
        //Debug.print("no purchase yet");
      };
    };
    var bets_ = userBetHistoryHash.get(Principal.toText(p));
    var bets : [T.Bet] = [];
    switch (bets_) {
      case (?b) {
        bets := b;
      };
      case (null) {
        //Debug.print("no bet yet");
      };
    };
    var remaining : Nat = 0;
    switch (userTicketQuantityHash.get(Principal.toText(p))) {
      case (?x) {
        remaining := x;
      };
      case (null) {
        remaining := 0;
        userTicketQuantityHash.put(Principal.toText(p), 0);
      };
    };
    var doubleRollRemaining : Nat = 0;
    switch (userDoubleRollQuantityHash.get(Principal.toText(p))) {
      case (?x) {
        doubleRollRemaining := x;
      };
      case (null) {
        doubleRollRemaining := 0;
        userDoubleRollQuantityHash.put(Principal.toText(p), 0);
      };
    };

    var bonusReward_ = 0;
    let userReward_ = userClaimableBonusHash.get(Principal.toText(p));
    switch (userReward_) {
      case (?r) {
        bonusReward_ := r;
      };
      case (null) {
        userClaimableBonusHash.put(Principal.toText(p), 0);
      };
    };

    let userData_ : T.UserV2 = {
      walletAddress = message.caller;
      claimableReward = claimable;
      claimHistory = claimHistory;
      purchaseHistory = purchase;
      gameHistory = bets;
      availableDiceRoll = remaining + doubleRollRemaining;
      claimableBonus = bonusReward_;
      alias = getAlias(message.caller);
    };
    //return user data
    userData_;
  };

  public query (message) func getCurrentGame() : async T.GameCheck {
    //return game data
    if (firstGameStarted == false) return #none;
    let currentGame_ = games.get(gameIndex);
    Debug.print("current game reward " #Nat.toText(currentGame_.reward));

    let game_ : T.CurrentGame = {
      bets = currentGame_.bets;
      id = currentGame_.id;
      reward = currentGame_.reward;
      reward_text = Nat.toText(currentGame_.reward);
      time_created = currentGame_.time_created;
      time_ended = currentGame_.time_ended;
      winner = currentGame_.winner;
      bonus = currentGame_.bonus;
      highestRoller = currentHighestRoller;
      highestDice = currentHighestDice;
      highestReward = currentHighestReward;
      totalReward = currentReward;
      users = userFirstHash.size();
    };
    #ok(game_);
  };
  public shared (message) func calculateRewards() : async Nat {
    assert (_isAdmin(message.caller));
    var reward_ = 0;
    currentReward := 0;
    currentHighestReward := 0;
    Buffer.iterate<T.Game>(
      games,
      func(game) {
        if (game.id < gameIndex) {
          if (game.reward > currentHighestReward) currentHighestReward := game.reward;
          reward_ += game.reward + game.bonus;
        };

      },
    );
    currentReward := reward_;
    reward_;
  };

  public query (message) func getGameByIndex(id_ : Nat) : async T.GameCheck {
    //return game data
    if (firstGameStarted == false) return #none;
    let currentGame_ = games.get(id_);
    Debug.print("current game reward " #Nat.toText(currentGame_.reward));

    let game_ : T.CurrentGame = {
      bets = currentGame_.bets;
      id = currentGame_.id;
      reward = currentGame_.reward;
      reward_text = Nat.toText(currentGame_.reward);
      time_created = currentGame_.time_created;
      time_ended = currentGame_.time_ended;
      winner = currentGame_.winner;
      bonus = currentGame_.bonus;
      highestRoller = currentHighestRoller;
      highestDice = currentHighestDice;
      highestReward = currentHighestReward;
      totalReward = currentReward;
      users = userFirstHash.size();
    };
    #ok(game_);
  };

  public shared (message) func pauseCanister(pause_ : Bool) : async Bool {
    assert (_isAdmin(message.caller));
    pause := pause_;
    pause_;
  };

  //@dev--to buy ticket, user should call approve function on icrc2
  public shared (message) func buy_ticket(quantity_ : Nat, ticket_Price_ : Nat, totalPrice_ : Nat) : async T.BookTicketResult {
    //set teh variable
    var p = getAlias(message.caller);
    assert (_isNotBlacklisted(p));
    assert (_isNotBlacklisted(message.caller));
    assert (_isNotPaused());
    //Pay by calling icrc2 transfer from
    let transferRes_ = await transferFrom(message.caller, quantity_ * ticketPrice);
    var transIndex_ = 0;
    switch transferRes_ {
      case (#success(x)) { transIndex_ := x };
      case (#error(txt)) {
        Debug.print("error " #txt);
        return #transferFailed(txt);
      };
    };
    //assert(transIndex_!=0);
    //write to ticket book history
    let ticketBook_ : T.TicketPurchase = {
      id = ticketIndex;
      walletAddress = ?message.caller;
      time = now();
      quantity = quantity_;
      totalPrice = quantity_ * ticketPrice;
      var icp_index = transIndex_;
    };
    let ticketBookPaid_ : T.PaidTicketPurchase = {
      id = ticketIndex;
      walletAddress = ?message.caller;
      time = now();
      quantity = quantity_;
      totalPrice = quantity_ * ticketPrice;
      icp_index = transIndex_;
    };
    ticketPurchaseHistory.add(ticketBook_);
    let ticketBookNow_ = ticketPurchaseHistory.get(ticketIndex);
    ticketIndex += 1;
    //write to users hash, both history and remaining ticket hash
    let userTickets_ = userTicketPurchaseHash.get(Principal.toText(p));
    switch (userTickets_) {
      case (?x) {
        userTicketPurchaseHash.put(Principal.toText(p), Array.append<T.PaidTicketPurchase>(x, [ticketBookPaid_]));
      };
      case (null) {
        userTicketPurchaseHash.put(Principal.toText(p), [ticketBookPaid_]);
      };
    };
    let userRemainingTicket_ = userTicketQuantityHash.get(Principal.toText(p));
    switch (userRemainingTicket_) {
      case (?x) {
        userTicketQuantityHash.put(Principal.toText(p), x +quantity_);
      };
      case (null) {
        userTicketQuantityHash.put(Principal.toText(p), quantity_);
      };
    };
    if (quantity_ >= 5) {
      var n = await notifyDiscord("Here comes " #Principal.toText(message.caller) # " with " #Nat.toText(quantity_) # " ticket(s)!%0AGo get that Dragon Eyes, warrior!!");

    };

    #success(quantity_);
  };

  //@dev-- called to start game for the first time by admin
  public shared (message) func firstGame() : async Bool {
    assert (_isAdmin(message.caller));
    ticketPrice := 500000;
    initialReward := ticketPrice * 10;
    initialBonus := ticketPrice;

    assert (gameIndex == 0);
    assert (firstGameStarted == false);
    Debug.print("Starting new game ");
    let newGame : T.Game = {
      id = gameIndex;
      var totalBet = 0;
      var winner = siteAdmin;
      time_created = now();
      var time_ended = 0;
      var reward = initialReward;
      var bets = [];
      var bonus = initialBonus;
      var bonus_winner = siteAdmin;
      var bonus_claimed = false;
    };
    games.add(newGame);
    firstGameStarted := true;
    let allgame = games.size();
    true;
  };

  func startNewGame() {
    gameIndex += 1;
    ticketPrice := nextTicketPrice;
    currentHighestRoller := siteAdmin;
    initialReward := ticketPrice * 10;
    currentMilestone := rewardMilestone;
    currentHighestDice := 0;
    let newGame : T.Game = {
      id = gameIndex;
      var totalBet = 0;
      var winner = siteAdmin;
      time_created = now();
      var time_ended = 0;
      var reward = initialReward;
      var bets = [];
      var bonus = ticketPrice;
      var bonus_winner = siteAdmin;
      var bonus_claimed = false;
    };
    games.add(newGame);

  };

  func roll() : async Nat8 {
    var count_ = 0;
    var check : Nat8 = 0;
    while (check == 0 and count_ < 5) {
      let random = Random.Finite(await Random.blob());
      let dice_ = random.range(20);
      switch (dice_) {
        case (?x) {
          var r_ = Nat.rem(x, 6) +1;
          check := 1;
          return Nat8.fromNat(r_);
        };
        case (null) {
          count_ += 1;
          //return 0;
        };
      };
    };
    return 0;
  };

  public shared (message) func testRoll() : async Nat8 {
    assert (_isAdmin(message.caller));
    var count_ = 0;
    var check : Nat8 = 0;
    while (check == 0 and count_ < 5) {
      let random = Random.Finite(await Random.blob());
      let dice_ = random.range(20);
      switch (dice_) {
        case (?x) {
          var r_ = Nat.rem(x, 6) +1;
          check := 1;
          return Nat8.fromNat(r_);
        };
        case (null) {
          count_ += 1;
          //return 0;
        };
      };
    };
    return 0;

  };

  public query (message) func getHashDoubleRoll(t : Text) : async ?Nat {
    return let u = userDoubleRollQuantityHash.get(t);
  };

  public query (message) func getHashTicket(t : Text) : async ?Nat {
    return let u = userTicketQuantityHash.get(t);
  };

  public shared (message) func sendToDiscord(msg : Text) : async Bool {
    assert (_isAdmin(message.caller));
    let id_ = Int.toText(now());
    let message_ = Text.replace(msg, #char ' ', "%20");
    let url = "https://api.lokamining.com/sendDiscord?id=" #id_ # "&message=" #message_;

    let decoded_text = await send_http(url);
    true;
  };

  func notifyDiscord(msg : Text) : async Bool {
    let id_ = Int.toText(now());
    let message = Text.replace(msg, #char ' ', "%20");
    let url = "https://api.lokamining.com/sendDiscord?id=" #id_ # "&message=" #message;

    let decoded_text = await send_http(url);
    true;
  };

  public shared (message) func initialEyesTokenCheck() : async Nat {
    assert (_isNotPaused());
    var p = getAlias(message.caller);
    switch (userFirstHash.get(Principal.toText(p))) {
      case (?x) {

        return 0;
      };
      case (null) {

        userFirstHash.put(Principal.toText(p), 0);
        if (eyesToken) {
          let res_ = transferEyesToken(message.caller, 2);
          return eyesTokenDistribution * 2;
        };
      };
    };
    1;
  };
  func _isBlacklisted(p : Principal) : Bool {
    switch (blistHash.get(Principal.toText(p))) {
      case (?a) {
        return a;
      };
      case (null) {
        return false;
      };
    };
  };

  func _isNotBlacklisted(p : Principal) : Bool {
    if (_isBlacklisted(p)) {
      return false;
    } else {
      return true;
    };
  };

  public shared (message) func setCurrentMilestone(i_ : Nat) : async Nat {
    assert (_isAdmin(message.caller));
    currentMilestone := i_;
    return currentMilestone;
  };

  public shared (message) func roll_dice(game_id : Nat) : async T.DiceResult {
    //get game dataassert
    assert (_isNotPaused());
    assert (_isNotBlacklisted(message.caller));
    var p = getAlias(message.caller);
    assert (_isNotBlacklisted(p));
    let game_ = games.get(game_id);
    let gameBets_ = game_.bets;
    var remaining_ : Nat = 0;
    var doubleRollRemaining_ : Nat = 0;
    Debug.print("check remaining");
    //get remaining dice roll ticket
    switch (userTicketQuantityHash.get(Principal.toText(p))) {
      case (?x) {
        remaining_ := x;
      };
      case (null) {
        remaining_ := 0;
        userTicketQuantityHash.put(Principal.toText(p), 0);
      };
    };
    let u = userDoubleRollQuantityHash.get(Principal.toText(p));
    switch (u) {
      case (?x) {
        doubleRollRemaining_ := x;
        // return #noroll([1, x]);
      };
      case (null) {
        //return #noroll([2, doubleRollRemaining_]);
        doubleRollRemaining_ := 0;
        userDoubleRollQuantityHash.put(Principal.toText(p), 0);
      };
    };
    //return #noroll([3, doubleRollRemaining_]);

    //check if the game is already won and closed
    if (game_.time_ended != 0) return #closed;
    //check if there is a ticket remaining including free double roll
    let total_ = remaining_ + doubleRollRemaining_;
    if (total_ == 0) return #noroll([remaining_, doubleRollRemaining_]);
    //return #noroll([remaining_, doubleRollRemaining_]);

    var extraRoll_ = false;
    //ICP send 50% of ticket price to holder
    if (doubleRollRemaining_ == 0) {
      let devFeeAmt = (ticketPrice / 2) -10000;
      Debug.print("transferring to dev" #Nat.toText(devFeeAmt));
      let transferResult_ = await transfer(devFeeAmt, devPool);
      var transferred = false;
      switch transferResult_ {
        case (#success(x)) { transferred := true };
        case (#error(txt)) {
          Debug.print("error " #txt);
          return #transferFailed(txt);
        };
      };
      //substract ticket
      userTicketQuantityHash.put(Principal.toText(p), remaining_ -1);
      extraRoll_ := true;
    } else {
      //substract ticket
      userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ -1);
    };
    //ROLL!==============================================================================================
    var isZero = false;
    var dice_1_ = await roll();
    if (dice_1_ == 0) isZero := true;
    var dice_2_ = await roll();
    if (dice_2_ == 0) isZero := true;
    let totalDice_ = dice_1_ + dice_2_;
    if (isZero) {
      userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ +1);
      return #zero;
    };
    let isHighest_ = (Nat8.toNat(totalDice_) > currentHighestDice);
    if (isHighest_) {
      currentHighestRoller := p;
      currentHighestDice := Nat8.toNat(totalDice_);
    };

    //check if Token started, mint Eyes to address based on emission halving
    if (eyesToken) {
      let res_ = transferEyesToken(message.caller, Nat8.toNat(dice_1_ + dice_2_));
    };

    //write bet history to : history variable, user hash, and to game object (thats 3 places)
    let bet_ : T.Bet = {
      id = betIndex;
      game_id = gameIndex;
      dice_1 = dice_1_;
      dice_2 = dice_2_;
      walletAddress = message.caller;
      time = now();
    };
    betIndex += 1;
    var userBets_ = userBetHistoryHash.get(Principal.toText(p));
    switch (userBets_) {
      case (?u) {
        userBetHistoryHash.put(Principal.toText(p), Array.append<T.Bet>(u, [bet_]));
      };
      case (null) {
        userBetHistoryHash.put(Principal.toText(p), [bet_]);
      };
    };
    betHistory.add(bet_);
    game_.bets := Array.append<T.Bet>(gameBets_, [bet_]);
    //check roll result
    if (dice_1_ == dice_2_ and dice_1_ == 1) {
      Debug.print("win!");
      if (game_.reward > currentHighestReward) currentHighestReward := game_.reward;
      currentReward := currentReward + game_.reward;
      //distribute reward
      let userReward_ = userClaimableHash.get(Principal.toText(p));
      switch (userReward_) {
        case (?r) {
          userClaimableHash.put(Principal.toText(p), r +game_.reward);
        };
        case (null) {
          userClaimableHash.put(Principal.toText(p), game_.reward);
        };
      };
      let bonusReward_ = userClaimableBonusHash.get(Principal.toText(currentHighestRoller));
      switch (bonusReward_) {
        case (?b) {
          userClaimableBonusHash.put(Principal.toText(currentHighestRoller), b + game_.bonus);
        };
        case (null) {
          userClaimableBonusHash.put(Principal.toText(currentHighestRoller), game_.bonus);
        };
      };
      game_.winner := message.caller;
      game_.bonus_winner := currentHighestRoller;
      currentTotalWins += game_.reward + game_.bonus;

      game_.time_ended := now();
      var currentBonus_ : Float = natToFloat(game_.bonus) / 100000000;
      var cB_ = Float.toText(currentBonus_);
      var currentReward_ : Float = natToFloat(game_.reward) / 100000000;
      var cR_ = Float.toText(currentReward_);

      if (isHighest_) {
        var n = await notifyDiscord("WINNER!! A legendary warrior has appeared!%0ABoth Dragon Chest AND the Dwarf's bonus have been obtained!%0A" #Principal.toText(message.caller) # " has just won the Dragon's Chest worth " #cR_ # " ICP%0AAnd also won the Dwarf's bonus worth " #cB_ # " ICP!%0AGame is now restarting");
        return #legend;
      };
      var n = await notifyDiscord("WINNER!! The King has obtained the Dragon Eyes!!%0A" #Principal.toText(message.caller) # " has just won the Dragon's Chest worth " # cR_ # " ICP%0AAnd " #Principal.toText(currentHighestRoller) # " won the Dwarf's bonus worth " #cB_ # "!%0AGame is now restarting");
      startNewGame();
      return #win;
    };

    //return if lost and detect if win extra roll
    if (extraRoll_) {

      game_.reward += (ticketPrice / 10) * 4;
      game_.bonus += (ticketPrice / 10) * 1;

      var currentBonus_ : Float = natToFloat(game_.bonus) / 100000000;
      var cB_ = Float.toText(currentBonus_);
      var currentReward_ : Float = natToFloat(game_.reward) / 100000000;
      var cR_ = Float.toText(currentReward_);
      var remR_ = Float.rem(natToFloat(game_.reward) / 100000000.0, 10.0);
      if (game_.reward >= currentMilestone) {
        var n = await notifyDiscord(cR_ # " ICP reached!! Dragon's Chest is getting bigger!%0ACurrent Dragon Chest : " #cR_ # " ICP | Current Dwarf's bonus : " #cB_ # " ICP");
        currentMilestone += rewardMilestone;
      };
      /*if (game_.totalBet < 10) {
        let userBonus_ = bonusPoolbyWallet.get(Principal.toText(message.caller));
        switch (userBonus_) {
          case (?r) {
            bonusPoolbyWallet.put(Principal.toText(message.caller), Array.append<Nat>(r, [game_.id]));
          };
          case (null) {
            bonusPoolbyWallet.put(Principal.toText(message.caller), [game_.id]);
          };
        };

      }; */
      if (dice_1_ == dice_2_) {
        if (dice_1_ < 6) userDoubleRollQuantityHash.put(Principal.toText(p), doubleRollRemaining_ +1);
        if (isHighest_ and dice_1_ == 6) {
          var n = await notifyDiscord("DWARF'S BONUS WINNER!! The absolute warrior is here!%0ADwarf's bonus for this round is officially won by " #Principal.toText(message.caller) # "%0ADwarf's bonus will keep increasing until the game is won, and then it can be claimed by the winner%0ACurrent Dragon Chest : " #cR_ # " ICP | Current Dwarf's bonus : " #cB_ # " ICP");
          return #absoluteHighest;
        };
        if (isHighest_) {
          //var n = await notifyDiscord("HIGHEST ROLLER!! A great warrior has just rolled the highest dice so far with " #Nat8.toText(dice_1_) # " and " #Nat8.toText(dice_2_) # "!%0ADwarf's bonus for this round is currently owned by " #Principal.toText(message.caller) # "%0ADwarf's bonus will keep increasing until the game is won, and then it can be claimed by the highest roller%0ACurrent Dragon Chest : " #cR_ # " ICP | Current Dwarf's bonus : " #cB_ # " ICP");
          return #highestExtra([dice_1_, dice_2_]);
        };
        return #extra([dice_1_, dice_2_]);
      };
    };
    var currentBonus_ : Float = natToFloat(game_.bonus) / 100000000;
    var cB_ = Float.toText(currentBonus_);
    var currentReward_ : Float = natToFloat(game_.reward) / 100000000;
    var cR_ = Float.toText(currentReward_);
    if (isHighest_) {
      //var n = await notifyDiscord("HIGHEST ROLLER!! A great warrior has just rolled the highest dice so far with " #Nat8.toText(dice_1_) # " and " #Nat8.toText(dice_2_) # "!%0ADwarf's bonus for this round is currently owned by " #Principal.toText(message.caller) # "%0ADwarf's bonus will keep increasing until the game is won, and then it can be claimed by the highest roller%0ACurrent Dragon Chest : " #cR_ # " ICP | Current Dwarf's bonus : " #cB_ # " ICP");
      return #highest([dice_1_, dice_2_]);
    };

    #lose([dice_1_, dice_2_]);

  };

  func log_history() {

  };

  public shared (message) func claimReward() : async Bool {
    var p = getAlias(message.caller);
    let reward_ = userClaimableHash.get(Principal.toText(p));

    switch (reward_) {
      case (?r) {
        if (r < 10000) return false;
        let transferResult_ = await transfer(r -10000, message.caller);
        switch transferResult_ {
          case (#success(x)) {
            userClaimableHash.put(Principal.toText(p), 0);

            let claimHistory_ : T.ClaimHistory = {
              time = now();
              icp_transfer_index = x;
              reward_claimed = r;
            };
            let claimArray_ = userClaimHistoryHash.get(Principal.toText(p));
            switch (claimArray_) {
              case (?c) {
                userClaimHistoryHash.put(Principal.toText(p), Array.append<T.ClaimHistory>(c, [claimHistory_]));
              };
              case (null) {
                userClaimHistoryHash.put(Principal.toText(p), [claimHistory_]);
              };
            };
            return true;
          };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return false;
          };
        };
      };
      case (null) {
        return false;
      };
    };
    false;
  };

  public shared (message) func claimBonusPool() : async Bool {
    var p = getAlias(message.caller);
    let reward_ = userClaimableBonusHash.get(Principal.toText(p));

    switch (reward_) {
      case (?r) {
        if (r < 10000) return false;
        let transferResult_ = await transfer(r -10000, message.caller);
        switch transferResult_ {
          case (#success(x)) {
            userClaimableBonusHash.put(Principal.toText(p), 0);

            let claimHistory_ : T.ClaimHistory = {
              time = now();
              icp_transfer_index = x;
              reward_claimed = r;
            };
            let claimArray_ = userClaimHistoryHash.get(Principal.toText(p));
            switch (claimArray_) {
              case (?c) {
                userClaimHistoryHash.put(Principal.toText(p), Array.append<T.ClaimHistory>(c, [claimHistory_]));
              };
              case (null) {
                userClaimHistoryHash.put(Principal.toText(p), [claimHistory_]);
              };
            };
            return true;
          };
          case (#error(txt)) {
            Debug.print("error " #txt);
            return false;
          };
        };
      };
      case (null) {
        return false;
      };
    };
    false;
  };

  func transferEyesToken(to_ : Principal, quantity_ : Nat) : async T.TransferResult {

    let transferResult = await Eyes.icrc1_transfer({
      amount = eyesTokenDistribution * quantity_;
      fee = null;
      created_at_time = null;
      from_subaccount = null;
      to = { owner = to_; subaccount = null };
      memo = null;
    });
    var res = 0;
    switch (transferResult) {
      case (#Ok(number)) {
        return #success(number);
      };
      case (#Err(msg)) {

        Debug.print("transfer error  ");
        switch (msg) {
          case (#BadFee(number)) {
            Debug.print("Bad Fee");
            return #error("Bad Fee");
          };
          case (#GenericError(number)) {
            Debug.print("err " #number.message);
            return #error("Generic");
          };
          case (#InsufficientFunds(number)) {
            Debug.print("insufficient funds");
            return #error("insufficient funds");

          };
          case _ {
            Debug.print("err");
          };
        };
        return #error("Other");
      };
    };
  };

  public shared (message) func getBalance({ te : Blob }) : async T.Tokens {
    //let address_blob : Blob = Text.encodeUtf8(t_);
    //address_blob;
    let ICPL = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai") : actor {
      account_balance : ({ account : Blob }) -> async T.Tokens;
    };
    let res = await ICPL.account_balance({ account = te });
    //let a = Nat64.toText(res);
    //Debug.print("aa ")
    return res;
  };

  public shared (message) func toText({ te : Text }) : async Blob {
    //let address_blob : Blob = Text.encodeUtf8(t_);
    //address_blob;
    let res = Text.encodeUtf8(te);
    //let res = Hex.decode(te);
    return res;
  };

  //func transfer(amount_ : Nat, to_ : Principal) : async T.TransferResult {

  func transfer(amount_ : Nat, to_ : Principal) : async T.TransferResult {
    //public shared (message) func transfer(amount_ : Nat, to_ : Principal) : async T.TransferResult {

    let transferResult = await ICPLedger.icrc1_transfer({
      amount = amount_;
      fee = null;
      created_at_time = null;
      from_subaccount = null;
      to = { owner = to_; subaccount = null };
      memo = null;
    });
    var res = 0;
    switch (transferResult) {
      case (#Ok(number)) {
        return #success(number);
      };
      case (#Err(msg)) {

        Debug.print("ICP transfer error  ");
        switch (msg) {
          case (#BadFee(number)) {
            Debug.print("Bad Fee");
            return #error("Bad Fee");
          };
          case (#GenericError(number)) {
            Debug.print("err " #number.message);
            return #error("Generic");
          };
          case (#InsufficientFunds(number)) {
            Debug.print("insufficient funds");
            return #error("insufficient funds");

          };
          case _ {
            Debug.print("ICP error err");
          };
        };
        return #error("ICP error Other");
      };
    };
  };

  func transferFrom(owner_ : Principal, amount_ : Nat) : async T.TransferResult {
    Debug.print("transferring from " #Principal.toText(owner_) # " by " #Principal.toText(Principal.fromActor(this)) # " " #Nat.toText(amount_));
    let transferResult = await ICPLedger.icrc2_transfer_from({
      from = { owner = owner_; subaccount = null };
      amount = amount_;
      fee = null;
      created_at_time = null;
      from_subaccount = null;
      to = { owner = Principal.fromActor(this); subaccount = null };
      spender_subaccount = null;
      memo = null;
    });
    var res = 0;
    switch (transferResult) {
      case (#Ok(number)) {
        return #success(number);
      };
      case (#Err(msg)) {

        Debug.print("transfer error  ");
        switch (msg) {
          case (#BadFee(number)) {
            return #error("Bad Fee");
          };
          case (#GenericError(number)) {
            return #error("Generic");
          };
          case (#BadBurn(number)) {
            return #error("BadBurn");
          };
          case (#InsufficientFunds(number)) {
            return #error("Insufficient Funds");
          };
          case (#InsufficientAllowance(number)) {
            return #error("Insufficient Allowance ");
          };
          case _ {
            Debug.print("ICP err");
          };
        };
        return #error("ICP transfer other error");
      };
    };
  };

  public query func transform(raw : T.TransformArgs) : async T.CanisterHttpResponsePayload {
    let transformed : T.CanisterHttpResponsePayload = {
      status = raw.response.status;
      body = raw.response.body;
      headers = [
        {
          name = "Content-Security-Policy";
          value = "default-src 'self'";
        },
        { name = "Referrer-Policy"; value = "strict-origin" },
        { name = "Permissions-Policy"; value = "geolocation=(self)" },
        {
          name = "Strict-Transport-Security";
          value = "max-age=63072000";
        },
        { name = "X-Frame-Options"; value = "DENY" },
        { name = "X-Content-Type-Options"; value = "nosniff" },
      ];
    };
    transformed;

  };

  func send_http(url_ : Text) : async Text {
    let ic : T.IC = actor ("aaaaa-aa");

    let url = url_;

    let request_headers = [
      { name = "User-Agent"; value = "icdragon_canister" },
      { name = "Content-Type"; value = "application/json" },
      { name = "x-api-key"; value = "2021LokaInfinity" },

    ];
    Debug.print("accessing " #url);
    let transform_context : T.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    let http_request : T.HttpRequestArgs = {
      url = url;
      max_response_bytes = null; //optional for request
      headers = request_headers;
      body = null; //optional for request
      method = #get;
      transform = ?transform_context;
    };

    Cycles.add(30_000_000_000);

    let http_response : T.HttpResponsePayload = await ic.http_request(http_request);
    let response_body : Blob = Blob.fromArray(http_response.body);
    let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
      case (null) { "No value returned" };
      case (?y) { y };
    };
    decoded_text;
  };

};
