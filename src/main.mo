import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Prim "mo:prim";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Hash "mo:base/Hash";
//import Error "mo:base/Error";

type Pos = { x : Nat; y : Nat };
type Direction = { #left; #right; #up; #down };
type State = (Principal, Pos);
type Content = { #person: Principal; };

func principalEq(x: Principal, y: Principal) : Bool = x == y;
func PosEq(x: Pos, y: Pos) : Bool = x.x == y.x and x.y == y.y;
func PosHash(x: Pos) : Hash.Hash = Hash.hashOfIntAcc(Hash.hashOfInt(x.x), x.y);

class Maze() {
    let N = 10;
    let state = H.HashMap<Principal, Pos>(3, principalEq, Principal.hash);
    var map = H.HashMap<Pos, Content>(3, PosEq, PosHash);
    
    public func join(id: Principal) {
        switch (state.get(id)) {
        case (?pos) ();
        case null {
                 // TODO better random and check
                 let hash = Prim.abs(Prim.word32ToInt(Principal.hash(id)));
                 let pos = { x = hash % N; y = (hash + 1234) % N };
                 state.set(id, pos);
                 map.set(pos, #person(id));
             };
        };
    };
    public func move(id: Principal, dir: Direction) {
        switch (state.get(id)) {
        case null Prelude.unreachable(); //throw Error.error "call join first";
        case (?pos) {
                 let npos = switch dir {
                 case (#left) { x = pos.x; y = (pos.y - 1) % N };
                 case (#right) { x = pos.x; y = (pos.y + 1) % N };
                 case (#up) { x = (pos.x - 1) % N; y = pos.y };
                 case (#down) { x = (pos.x + 1) % N; y = pos.y };                                  
                 };
                 switch (map.get(npos)) {
                 case (?content) ();
                 case null {
                          state.set(id, npos);
                          ignore map.remove(pos);
                          map.set(npos, #person(id));
                      };
                 };
             };
        };
    };
    public func outputState() : [State] {
        Iter.toArray<State>(state.iter())
    }
};


actor {
    let maze = Maze();
    public shared(msg) func join() : async Principal {
        let id = msg.caller;
        maze.join(id);
        id
    };
    public shared(msg) func move(dir : Direction) : async () {
        let id = msg.caller;
        maze.move(id, dir);
    };
    public query func getState() : async [State] {
        maze.outputState()
    };
    public query(msg) func fakeMove(dir : Direction) : async [State] {
        let id = msg.caller;
        maze.move(id, dir);
        maze.outputState()
    };    
};
