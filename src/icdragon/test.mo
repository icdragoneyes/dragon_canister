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

shared ({ caller = owner }) actor class Test({
    admin : Principal;
}) = this {
    //indexes
    public shared (message) func testNem(i_ : Nat) : async Nat {
        return Nat.rem(i_ / 100000000, 10);
    };

    public shared (message) func testNum(i_ : Nat) : async Nat {
        return Nat.rem(i_, 10);
    };

    public shared (message) func tfloat(i_ : Float) : async Float {
        return Float.rem(i_ / 100000000, 10);
    };

};
