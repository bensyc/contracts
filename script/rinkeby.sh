source .env && forge script ./script/Rinkeby.s.sol --rpc-url $RINKEBY_RPC_URL  --private-key $RINKEBY_PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv RUST_BACKTRACE=full
