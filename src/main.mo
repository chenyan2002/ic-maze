import H "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Prim "mo:prim";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Hash "mo:base/Hash";
import Heap "mo:base/Heap";
import Option "mo:base/Option";
import Buf "mo:base/Buf";
//import Error "mo:base/Error";

type Pos = { x : Nat; y : Nat };
type Direction = { #left; #right; #up; #down };

//type State = (Principal, Pos);
type Content = { #person: Principal; #wall };

type Msg = { seq: Nat; dir: Direction };
func msgOrd(x: Msg, y: Msg) : {#lt;#gt} { if (x.seq < y.seq) #lt else #gt };
type PlayerState = { pos: Pos; seq: Nat; msgs: Heap.Heap<Msg>  };

type OutputState = (Principal, { pos: Pos; seq: Nat; msgs: [Msg] });
type OutputGrid = (Pos, Content);

func principalEq(x: Principal, y: Principal) : Bool = x == y;
func posEq(x: Pos, y: Pos) : Bool = x.x == y.x and x.y == y.y;
func posHash(x: Pos) : Hash.Hash = Hash.hashOfIntAcc(Hash.hashOfInt(x.x), x.y);

class Maze() {
    let N = 10;
    public let players = H.HashMap<Principal, PlayerState>(3, principalEq, Principal.hash);
    public let map = H.HashMap<Pos, Content>(3, posEq, posHash);
    
    public func join(id: Principal) : PlayerState {
        switch (players.get(id)) {
        case (?state) { state };
        case null {
                 // TODO better random and check
                 let hash = Prim.abs(Prim.word32ToInt(Principal.hash(id)));
                 let new_pos = { x = hash % N; y = (hash + 1234) % N };
                 let state = { pos = new_pos; seq = 0; msgs = Heap.Heap<Msg>(msgOrd) };
                 players.set(id, state);
                 map.set(new_pos, #person(id));
                 state
             };
        };
    };
    public func move(id: Principal, msg: Msg) {
        let state = Option.unwrap(players.get(id));
        if (state.seq <= msg.seq) {
            state.msgs.add(msg);
        };
        processState(id);
    };
    public func processState(id: Principal) {
        loop {
            let state = Option.unwrap(players.get(id));
            switch (state.msgs.peekMin()) {
            case null return;
            case (?msg) {
                     if (state.seq > msg.seq) Prelude.unreachable();
                     if (state.seq < msg.seq) return;
                     state.msgs.removeMin();
                     // seq matches, try move the position
                     let npos = switch (msg.dir) {
                     case (#left) { x = state.pos.x; y = (state.pos.y - 1) % N };
                     case (#right) { x = state.pos.x; y = (state.pos.y + 1) % N };
                     case (#up) { x = (state.pos.x - 1) % N; y = state.pos.y };
                     case (#down) { x = (state.pos.x + 1) % N; y = state.pos.y };                                  
                     };
                     switch (map.get(npos)) {
                     case (?content) {
                              // blocked
                              let new_state = { pos = state.pos; seq = msg.seq + 1; msgs = state.msgs };
                              players.set(id, new_state);
                          };
                     case null {
                              // empty
                              map.set(npos, #person(id));
                              ignore map.remove(state.pos);
                              let new_state = { pos = npos; seq = msg.seq + 1; msgs = state.msgs };
                              players.set(id, new_state);
                          };
                     };
                 };
            };
        };
    };
    public func getSeq(id: Principal) : Nat {
        let state = Option.unwrap(players.get(id));
        state.seq
    };
    func outputHeap(x: Heap.Heap<Msg>) : [Msg] {
        let buf = Buf.Buf<Msg>(3);
        label L loop {
            switch (x.peekMin()) {
            case null { break L };
            case (?msg) {
                     buf.add(msg);
                     x.removeMin();
                 };
            };
        };
        buf.toArray()
    };
    public func outputState() : [OutputState] {
        let array = Iter.toArray<(Principal, PlayerState)>(players.iter());
        Array.map<(Principal, PlayerState), OutputState>(
          func ((id, state)) {
              (id, { pos = state.pos; seq = state.seq; msgs = outputHeap(state.msgs) })
          },
          array)
    };
    public func outputMap() : [OutputGrid] {
        Iter.toArray<OutputGrid>(map.iter())
    };
};


actor {
    let maze = Maze();
    public shared(msg) func join() : async (Principal, Nat) {
        let id = msg.caller;
        let state = maze.join(id);
        (id, state.seq)
    };
    public shared(msg) func move(dir : Msg) : async () {
        let id = msg.caller;
        maze.move(id, dir);
    };
    public query func getState() : async [OutputState] {
        maze.outputState()
    };
    public query(msg) func getMap() : async ([OutputGrid], Nat) {
        (maze.outputMap(), maze.getSeq(msg.caller))
    };
    public query(msg) func fakeMove(dirs : [Msg]) : async ([OutputGrid], Nat) {
        let id = msg.caller;
        for (dir in dirs.vals()) {
            maze.move(id, dir);
        };
        (maze.outputMap(), maze.getSeq(id))
    };
};
