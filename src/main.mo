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

type Content = { #person: Principal; #wall; #trophy; #beast; #coffee; #plant; #olive };

type Msg = { seq: Nat; dir: Direction };
func msgOrd(x: Msg, y: Msg) : {#lt;#gt} { if (x.seq < y.seq) #lt else #gt };
type PlayerState = { pos: Pos; seq: Nat; msgs: Heap.Heap<Msg>  };

type OutputState = (Principal, { pos: Pos; seq: Nat; msgs: [Msg] });
type OutputGrid = (Pos, Content);

func principalEq(x: Principal, y: Principal) : Bool = x == y;
func posEq(x: Pos, y: Pos) : Bool = x.x == y.x and x.y == y.y;
func posHash(x: Pos) : Hash.Hash = Hash.hashOfIntAcc(Hash.hashOfInt(x.x), x.y);
func nat2Dir(x: Nat) : Direction {
    let dir = switch (x % 4) {
        case (0) { #left };
        case (1) { #right };
        case (2) { #up };
        case (_) { #down };                              
    };
    dir
};

object Random {
    //stolen from https://github.com/dfinity-lab/Life-Demo/blob/master/src/lifer/main.mo#L5
  var x = 1;
  public func next() : Nat {
    x := (123138118391*x + 133489131) % 9999;
    x
  };
};

class Maze() {
    let MAZE_INPUT : [ [ Nat ] ] =
       [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,2,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,1,0,1,1,1,0,1,1,1,0,1,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1,1,0,1,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,1,1,1,1,1,0,1,1,1,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,1,1,1],
        [1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,0,1,1,1,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,1,1,0,1,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,0,1,1,1,0,1,1,1,0,0,0,0,0,1,1,0,1,1,1,1,1,1,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,0,1,1,1,0,1,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,0,1,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0,0,0,3,0,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]];
    
    public let N1 = 18;
    public let N2 = 39;
    
    public var beast_pos = {x = 5; y = 15};

    public let players = H.HashMap<Principal, PlayerState>(3, principalEq, Principal.hash);

    func createInitialMap() : H.HashMap<Pos, Content> {
        var m = H.HashMap<Pos, Content>(3, posEq, posHash);
        for (i in Iter.range(0, N1-1)) {
            for (j in Iter.range(0, N2-1)) {
                if (MAZE_INPUT[i][j] == 1) {
                    m.set({x=i; y=j}, #wall);
                };
                if (MAZE_INPUT[i][j] == 2) {
                    m.set({x=i; y=j}, #trophy);
                };
                if (MAZE_INPUT[i][j] == 3) {
                    m.set({x=i; y=j}, #coffee);
                };
                if (MAZE_INPUT[i][j] == 4) {
                    m.set({x=i; y=j}, #plant);
                };
                if (MAZE_INPUT[i][j] == 5) {
                    m.set({x=i; y=j}, #olive);
                };
            };
        };
        m.set(beast_pos, #beast);
        m
    };
    public let map = createInitialMap();
    
    public func join(id: Principal) : PlayerState {
        switch (players.get(id)) {
            case (?state) { state };
            case null {
                var npos = { x = Random.next() % N1; y = Random.next() % N2 };
                label L loop {
                    switch (map.get(npos)) {
                      case (?content) {
                            //blocked
                            npos := { x = Random.next() % N1; y = Random.next() % N2 };
                        };
                        case null { 
                            break L 
                        };
                    };
                };  
                let state = { pos = npos; seq = 0; msgs = Heap.Heap<Msg>(msgOrd) };
                players.set(id, state);
                map.set(npos, #person(id));
                state      
            };
        };
    };

    func newPos(pos:Pos, dir:Direction) : Pos {
        let npos = switch (dir) {
            case (#left) { x = pos.x; y = (pos.y - 1) % N2 };
            case (#right) { x = pos.x; y = (pos.y + 1) % N2 };
            case (#up) { x = (pos.x - 1) % N1; y = pos.y };
            case (#down) { x = (pos.x + 1) % N1; y = pos.y };                                  
        };
        npos
    };

    public func move(id: Principal, msg: Msg) {
        let state = Option.unwrap(players.get(id));
        if (state.seq <= msg.seq) {
            state.msgs.add(msg);
        };
        processState(id);
    };
    public func moveBeast() {
        let npos = newPos(beast_pos, nat2Dir(Random.next()));
        switch (map.get(npos)) {
            case (?content) {
                //blocked
            };
            case null { 
            // empty
                map.set(npos, #beast);
                ignore map.remove(beast_pos);
                beast_pos := npos;  
            };
        };
    };
    public func processState(id: Principal) {
        loop {
            let state = Option.unwrap(players.get(id));
            switch (state.msgs.peekMin()) {
                case null return;
                case (?msg) {
                     if (state.seq > msg.seq) Prelude.unreachable();
                     if (state.seq < msg.seq) return;
                     moveBeast();
                     state.msgs.removeMin();
                     // seq matches, try move the position
                     let npos = newPos(state.pos, msg.dir);   
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
        switch (players.get(id)) {
        case null 0;
        case (?state) state.seq;
        };
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
    // Not needed. For debugging only
    public query func getState() : async [OutputState] {
        maze.outputState()
    };
    // Output:
    // - Array of non-empty cells
    // - Processed sequence number
    public query(msg) func getMap() : async ([OutputGrid], Nat) {
        (maze.outputMap(), maze.getSeq(msg.caller))
    };
    // query move takes pending moves from all players
    public query(msg) func fakeMove(dirs : [(Principal, [Msg])]) : async ([OutputGrid], Nat) {
        let processedSeq = maze.getSeq(msg.caller);
        for ((id, msgs) in dirs.vals()) {
            for (m in msgs.vals()) {
                maze.move(id, m);
            };
        };
        (maze.outputMap(), processedSeq)
    };
};
