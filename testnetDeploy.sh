
#!/usr/bin/env bash

source .env

forge script script/DeployNewRender.s.sol:BlitkinScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvv