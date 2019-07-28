# Launch a GIN masternode on Ubuntu 18.04

Works on a freshly installed Ubuntu 18.04 like one you would get from Vultr or Digital Ocean. Might work on other versions of Ubuntu but was not tested.

No dependency is required, as the script will install `docker`, `docker-compose` and `jq` which are the only dependencies.

It then launches a docker container with your node using the official image `gincoin/gincoin-core`. The node fully syncs with the network, this can take around half an hour, then outputs a `masternode.conf` line that you can use with any collateral transaction you have in your wallet.

**A bootstrap is not currently added, so a full sync is required. We'll add one if the script is used.**

## How to use

```bash
curl -s https://raw.githubusercontent.com/GIN-coin/node-script/master/node.sh | sudo bash -
```
