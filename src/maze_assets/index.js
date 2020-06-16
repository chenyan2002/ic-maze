import canister from 'ic:canisters/maze';
import './maze.css';

// util for creating maze

var N;

const symbols = [ "", "wall", "hero" ];

async function generateMaze(dom) {
  console.log("generateMaze");
  let f = await canister.getMap();
  N = f[1].c[0];
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
  sparse.forEach(function (cellEntry) {
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
  // update map and draw the diff
  update(g) {
    processedSeq = g[1];
    const new_grids = [];    
    g[0].forEach(grid => {
      const pos = Pos.fromPos(grid._0_);
      new_grids[pos] = Map.getGridType(grid._1_);
    });

    for (const pos in this._grids) {
      const type = this._grids[pos];
      grids[pos].classList.remove(type);
      if (!this._isFinal) {
        grids[pos].classList.remove("temp");
      }
    }
    for (const pos in new_grids) {
      const type = new_grids[pos];
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

const score = document.createElement('div');
score.id = "maze_score";

async function init() {
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
      myid = res[0];
      myseq = res[1].toNumber();
      setInterval(render, 200);
    })();
  });
}

init();

