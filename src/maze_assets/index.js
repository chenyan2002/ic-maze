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
  canister.move(dir);
  const tmp = await canister.fakeMove(dir);
  tmpState.update(tmp);
  e.preventDefault();
}

async function render() {
  const res = await canister.getState();
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

class State {
  constructor() {
    this._state = [];
  };
  update(state) {
    const new_state = state.map(e => {
      const pos = Pos.fromPos(e._1_);
      return [e._0_, pos];
    });
    for (const [id, pos] of this._state) {
      grids[pos].classList.remove('hero');
    }
    for (const [id, pos] of new_state) {
      grids[pos].classList.add('hero');
    }
    this._state = new_state;
  }
}

// global states
// HTMLElements for maze, indexed by Pos class
const grids = [];

let state = new State();
let tmpState = new State();
let myid;

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
      const id = await canister.join();
      myid = id;
      render();
    })();
  });
}

init();

setInterval(render, 100);
