# Fight My Maze

[![Gitpod Ready-to-Code](https://img.shields.io/badge/Gitpod-Ready--to--Code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/chenyan2002/ic-maze)

Click the above icon to play online!

Fight My Maze is a multiplayer game where you're a monster character and compete against other monsters to reach the Tungsten trophy first.

This game show cases 

* how to use multiple identities
* the IC persisting data so players can take a break and continue their game later
* a design pattern for real-time interaction with potential conflicts
* what does it mean to build a p2p achitecture on top of IC

A brief introduction into the game and the high-level code structure can be found in this [slide set](https://docs.google.com/presentation/d/1PDUw0olB2Cz3AlXzajVfTdnjjSpwa8iaJ6QPr-9LLiQ/edit#slide=id.g88f8de98b7_1_189).

# Future work

* webRTC + synchronization with IC: https://github.com/chenyan2002/ic-maze/pull/13 (can see peer moves from console log, but have high CPU usage)

# Steps to build locally

Start two terminal windows

### In terminal window 1
```bash
git clone git@github.com:chenyan2002/ic-maze.git

cd ic-maze && npm install

dfx start

```

### In terminal window 2

```bash

cd ic-maze && dfx build && dfx canister install --all

```

### In browser
Visit `127.0.0.1:8000/?canisterId={maze_assets_canister_id}`
