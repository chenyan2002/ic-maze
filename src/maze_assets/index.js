import canister from 'ic:canisters/maze';
import './maze.css';

// util for creating maze

const N = 10;

const symbols = [ "", "wall", "hero" ];

async function generateMaze(dom) {
  let f = await canister.getMap();
  // First create the empty map
  for (let i = 0; i < N; i++) {
    const row = document.createElement('div');
    for (let j = 0; j < N; j++) {
      const grid = document.createElement('div');
      const pos = new Pos(i,j);
      grids[pos] = grid;
      row.appendChild(grid);
    }
    dom.appendChild(row);
  }
  // Then populate it
  let sparse = f[0];
  sparse.forEach((cellEntry) => {
    let pos = cellEntry._0_;
    let content = cellEntry._1_;
    if (typeof content.wall !== 'undefined') {
      grids[new Pos(pos.x.c[0], pos.y.c[0])].className = "wall";
    }
  })
}

let pendingMoves = [];

async function mazeKeyPressHandler(e) {
  let dir;
  switch(e.keyCode) {
  case 37: // left
    dir = {left:null};
    break;
  case 38: // up
    dir = {up:null};
    break;
  case 39: // right
    dir = {right:null};
    break;
  case 40: //  down
    dir = {down:null};
    break;
  default:
    return;
  }
  // Assign seq number to move msg
  const msg = {};
  msg.seq = myseq++;
  msg.dir = dir;
  // Call move without waiting for reply
  canister.move(msg);
  // Query move with pendingMoves
  pendingMoves.push(msg);
  const tmp = await canister.fakeMove(pendingMoves);
  tmpState.update(tmp);
  // Remove processed moves
  pendingMoves = pendingMoves.filter(m => m.seq >= processedSeq);
  // send p2p msgs
  const others = state.getOtherPlayers();
  others.forEach(id => {
    const conn = peer.connect(id, { debug: 2 });
    conn.send(pendingMoves);
    conn.on('data', data => {
      console.log(data);
    });
    //console.log(conn);
    /*conn.on('open', () => {
      console.log(id, pendingMoves);
      conn.send(pendingMoves);
    });*/
    //conn.close();
  });
  
  
  await render();
  e.preventDefault();
}


async function render() {
  const res = await canister.getMap();
  state.update(res);
  const pending = myseq - processedSeq;
  score.innerText = processedSeq.toString();
  if (pending > 0)
    score.innerText += " pending: " + pending.toString();
}

class Pos {
  constructor(x,y) {
    this.x = x;
    this.y = y;
  }
  static fromPos(pos) {
    return new Pos(pos.x.toNumber(), pos.y.toNumber());
  };
  toString() {
    return this.x + "," + this.y;
  }
}

class Map {
  constructor(isFinal) {
    this._grids = [];
    this._isFinal = isFinal;
  };
  static getGridType(content) {
    if (content.hasOwnProperty("wall")) {
      return "wall"
    } else if (content.hasOwnProperty("person")) {
      return "hero"
    } else
      return ""
  }
  getOtherPlayers() {
    const list = [];
    for (const pos in this._grids) {
      const person = this._grids[pos].person;
      if (typeof person !== 'undefined') {
        const id = person.toText().slice(3);
        if (id != myid) {
          list.push(id);
        }
      }
    }
    return list;
  }
  // update map and draw the diff
  update(g) {
    processedSeq = g[1];
    const new_grids = [];    
    g[0].forEach(grid => {
      const pos = Pos.fromPos(grid._0_);
      new_grids[pos] = grid._1_;
    });

    for (const pos in this._grids) {
      const type = Map.getGridType(this._grids[pos]);
      grids[pos].classList.remove(type);
      if (!this._isFinal) {
        grids[pos].classList.remove("temp");
      }
    }
    for (const pos in new_grids) {
      const type = Map.getGridType(new_grids[pos]);
      grids[pos].classList.add(type);
      if (!this._isFinal) {
        grids[pos].classList.add("temp");
      } else {
        grids[pos].classList.remove("temp");        
      }
    }

    this._grids = new_grids;
  }
}

// global states
// HTMLElements for maze, indexed by Pos class
const grids = [];

let state = new Map(true);
let tmpState = new Map(false);
let myid;
let myseq;
let processedSeq;
let peer;

const score = document.createElement('div');
score.id = "maze_score";

function init() {
  const link = document.createElement('script');
  link.setAttribute('src', 'https://cdn.jsdelivr.net/npm/peerjs@1.2.0/dist/peerjs.min.js');
  link.setAttribute('type', 'text/javascript');
  document.getElementsByTagName("head")[0].appendChild(link);
  
  const container = document.createElement('div');
  container.id = "maze_container";
  const maze = document.createElement('div');
  maze.id = "maze";  
  generateMaze(maze);
  container.appendChild(maze);
  document.body.replaceChild(container, document.getElementById('app'));

  document.body.appendChild(score);

  let div = document.createElement('div');
  div.id = "maze_message";
  document.body.appendChild(div);

  document.addEventListener("keydown", mazeKeyPressHandler, false);
  
  const join = document.createElement('button');
  join.innerText = 'Join';
  document.body.appendChild(join);

  join.addEventListener('click', () => {
    (async () => {
      const res = await canister.join();
      myid = res[0].toText().slice(3);
      myseq = res[1].toNumber();
      // create p2p object
      peer = new Peer(myid, {
        host: 'localhost',
        port: 9000,
        path: '/myapp',
        debug: 2
      });
      // set timer
      setInterval(render, 200);
    })();
  });
}

init();

