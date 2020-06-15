import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Prim "mo:prim";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
//import Error "mo:base/Error";

type Pos = { x : Nat; y : Nat };
type Direction = { #left; #right; #up; #down };
type State = (Principal, Pos);

func principalEq(x: Principal, y: Principal) : Bool = x == y;

let N = 10;

actor {
    let state = H.HashMap<Principal, Pos>(3, principalEq, Principal.hash);
    var map = Array.tabulate<[var Nat8]>(N, func _ = Array.init<Nat8>(N, 0));
    
    public shared(msg) func join() : async Principal {
        let id = msg.caller;
        switch (state.get(id)) {
        case (?pos) { id };
        case null {
                 // TODO better random and check
                 let hash = Prim.abs(Prim.word32ToInt(Principal.hash(id)));
                 let pos = { x = hash % N; y = (hash + 1234) % N };
                 state.set(id, pos);
                 map[pos.x][pos.y] := 1;
                 id
             };
        };        
    };
    public shared(msg) func move(dir : Direction) : async () {
        let id = msg.caller;
        switch (state.get(id)) {
        case null Prelude.unreachable(); //throw Error.error "call join first";
        case (?pos) {
                 let npos = switch dir {
                 case (#left) { x = pos.x; y = (pos.y - 1) % N };
                 case (#right) { x = pos.x; y = (pos.y + 1) % N };
                 case (#up) { x = (pos.x - 1) % N; y = pos.y };
                 case (#down) { x = (pos.x + 1) % N; y = pos.y };                                  
                 };
                 if (map[npos.x][npos.y] == Prim.natToNat8(0)) {
                     state.set(id, npos);
                     map[pos.x][pos.y] := 0;
                     map[npos.x][npos.y] := 1;
                 };
             };
        };
    };
    public query func getState() : async [State] {
        Iter.toArray<State>(state.iter())
    };
};
