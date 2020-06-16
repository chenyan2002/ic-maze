import canister from 'ic:canisters/maze';
import './maze.css';

// util for creating maze

const N = 10;

const board = [[1,1,1,1,1,1,1,1,1,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,1],
               [1,1,1,1,1,1,1,1,1,1]];               

const symbols = [ "", "wall", "hero" ];

function generateMaze(dom) {
  for (let i = 0; i < N; i++) {
    const row = document.createElement('div');
    for (let j = 0; j < N; j++) {
      const grid = document.createElement('div');
      grid.className = symbols[board[i][j]];
      const pos = new Pos(i,j);
      grids[pos] = grid;
      row.appendChild(grid);
    }
    dom.appendChild(row);
  }
}

const pendingMoves = [];

async function mazeKeyPressHandler(e) {
  let dir;
  switch(e.keyCode) {
  case 37: // left
    maze.classList.remove('face-right');
    dir = {left:null};
    break;
  case 38: // up
    dir = {up:null};
    break;
  case 39: // right
    maze.classList.add('face-right');
    dir = {right:null};
    break;
  case 40: //  down
    dir = {down:null};
    break;
  default:
    return;
  }
  const msg = {};
  msg.seq = myseq++;
  msg.dir = dir;
  canister.move(msg);
  pendingMoves.push(msg);
  //console.log(pendingMoves);
  const tmp = await canister.fakeMove(pendingMoves);
  tmpState.update(tmp);
  await render();
  e.preventDefault();
}

async function render() {
  const res = await canister.getMap();
  state.update(res);
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
  constructor() {
    this._grids = [];
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
    const new_grids = [];    
    g.forEach(grid => {
      const pos = Pos.fromPos(grid._0_);
      new_grids[pos] = Map.getGridType(grid._1_);
    });

    for (const pos in this._grids) {
      const type = this._grids[pos];
      grids[pos].classList.remove(type);
    }
    for (const pos in new_grids) {
      const type = new_grids[pos];
      grids[pos].classList.add(type);
    }

    this._grids = new_grids;
  }
}

// global states
// HTMLElements for maze, indexed by Pos class
const grids = [];

let state = new Map();
let tmpState = new Map();
let myid;
let myseq;

const maze = document.createElement('div');
maze.id = "maze";

async function init() {
  const container = document.createElement('div');
  container.id = "maze_container";
  generateMaze(maze);
  container.appendChild(maze);
  document.body.replaceChild(container, document.getElementById('app'));

  document.addEventListener("keydown", mazeKeyPressHandler, false);
  
  const join = document.createElement('button');
  join.innerText = 'Join';
  document.body.appendChild(join);

  join.addEventListener('click', () => {
    (async () => {
      const res = await canister.join();
      myid = res[0];
      myseq = res[1].toNumber();
      render();
    })();
  });
}

init();

setInterval(render, 200);
