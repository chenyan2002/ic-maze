import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Prim "mo:prim";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Int "mo:base/Int";
//import Error "mo:base/Error";


let N = 10;



// A member of Z/NZ for the above-defined N.
//
// Immutable, all operations return new objects.
class ModularNumber (i : Int) = {
    // The % operator is weird: it returns a negative output when the input is negative.
    // Hence we wrap it into a function
    func moduloN(i : Int) : Nat {
        let j = i%N;
        Int.abs(if (j < 0) { j+N } else { j })
    };
  var val : Nat = moduloN(i); // The actual number. We will maintain as invariant that it should be inside [0, N).
  public func get() : Nat {
     val
  };
  public func add(delta : Int) : ModularNumber {
      ModularNumber ( val + delta)
  };

};


type Pos = { x : ModularNumber; y : ModularNumber };
type Direction = { #left; #right; #up; #down };


func principalEq(x: Principal, y: Principal) : Bool = x == y;

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
                 let pos = { x = ModularNumber(hash); y =ModularNumber(hash + 1234) };
                 state.set(id, pos);
                 map[pos.x.get()][pos.y.get()] := 1;
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
                 case (#left) { x = pos.x; y = pos.y.add(-1); };
                 case (#right) { x = pos.x; y = pos.y.add(+1); };
                 case (#up) { x = pos.x.add(-1); y = pos.y };
                 case (#down) { x = pos.x.add(+1); y = pos.y };                                  
                 };
                 if (map[npos.x.get()][npos.y.get()] == Prim.natToNat8(0)) {
                     state.set(id, npos);
                     map[pos.x.get()][pos.y.get()] := 0;
                     map[npos.x.get()][npos.y.get()] := 1;
                 };
             };
        };
    };

    // Objects of type 'ModularNumber' cannot be serialized because they contain functions,
    // so we need to map them to Nat.
    type SingleUserState = { user:Principal; x:Nat; y:Nat; };
    public query func getState() : async [SingleUserState] {

        Iter.toArray<SingleUserState>(
            Iter.map<(Principal, Pos), SingleUserState>(
                func(u : Principal, pos : Pos) : SingleUserState { {user=u; x=pos.x.get(); y=pos.y.get(); } },
                state.iter())
        )
    };
};
