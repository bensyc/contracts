source .env && forge script ./script/BENSYC.s.sol --rpc-url $RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv RUST_BACKTRACE=full
