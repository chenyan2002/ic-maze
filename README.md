# maze

[![Gitpod Ready-to-Code](https://img.shields.io/badge/Gitpod-Ready--to--Code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/chenyan2002/ic-maze)

Click the above icon to play online!

# Steps to build locally

Start two terminal windows

### In terminal window 1
```bash
git clone git@github.com:chenyan2002/ic-maze.git

cd ic-maze && npm install

cd ic-maze && dfx start

```

### In terminal window 2

```bash

cd ic-maze && dfx build && dfx canister install --all

```

### In browser
Visit `127.0.0.1:8000/?canisterId={maze_assets_canister_id}`
