#!/bin/bash
set -e
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit 1
fi

IMAGE="gincoin/gincoin-core"
CLI="gincoin-cli"
CONF="gincoin.conf"
PORT="10111"
DATADIR="/root/.gincoincore"
ADDNODES="https://masternodes.online/addnodes/GIN"
IP=$(dig @resolver1.opendns.com ANY myip.opendns.com +short -4)

read -p "Enter node name (e.g. MN1): " ID </dev/tty
ID=${ID:-MN}
DATA="/data/${ID}"

if [[ -z ${IP} ]]; then
  echo "Could not resolve externa IPv4"
  exit 1
fi

apt-get update && apt-get install -y docker.io docker-compose jq
mkdir -p ${DATA}
docker stop ${ID} && docker rm ${ID} || echo "Daemon wasn't running, starting for the first time..."
docker run --name=${ID} -d -p ${PORT}:${PORT} -v ${DATA}:${DATADIR} ${IMAGE} > /dev/null

ASSET_ID="0"
BLOCKS="0"
HEADERS="0"

if [[ ! -z ${ADDNODES} ]]; then
  echo " Adding nodes..."
  sleep 10
  curl -s ${ADDNODES} | grep addnode= | head -n -1 | tail -n +2 | sed -e 's/addnode=//g' | tail -n 30 | xargs -t -I{} docker exec ${ID} ${CLI} addnode {} onetry
fi

echo ""

until [ ${ASSET_ID} -eq 999 ]
do
  echo -ne " Waiting for node to sync (BLOCKS=${BLOCKS}/${HEADERS}, ASSET_ID=${ASSET_ID})...\r"
  sleep 5
  BLOCKS=$(docker exec ${ID} ${CLI} getinfo | jq -r '.blocks')
  ASSET_ID=$(docker exec ${ID} ${CLI} mnsync status | jq -r '.AssetID')
  HEADERS=$(docker exec ${ID} ${CLI} getblockchaininfo | jq -r '.headers')
done

PK=$(docker exec ${ID} ${CLI} masternode genkey)

echo " Writing conf file"
sed -i '/(masternode=|externalip=|masternodeprivkey=)/d' ${DATA}/${CONF}
echo "masternode=1" >> ${DATA}/${CONF}
echo "externalip=${IP}" >> ${DATA}/${CONF}
echo "masternodeprivkey=${PK}" >> ${DATA}/${CONF}

echo " Restarting daemon..."

ASSET_ID="0"
until [ ${ASSET_ID} -eq 999 ]
do
  echo -ne " Waiting for node to come back online (ASSET_ID=${ASSET_ID})...\r"
  sleep 20
  ASSET_ID=$(docker exec ${ID} ${CLI} mnsync status | jq -r '.AssetID')
done

echo "Add the following line to your masternode.conf (replacing <TXID> and <TXINDEX> with your collateral TX values) and start from wallet"
echo "################################################################################################################"
echo "${ID} ${IP}:${PORT} ${PK} <TXID> <TXINDEX>"
echo "################################################################################################################"
echo ""
echo ""
echo "After the node is started you can check its status here with"
echo "############################################################"
echo "docker exec ${ID} ${CLI} masternode status"
echo "############################################################"
