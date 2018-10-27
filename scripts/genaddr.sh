#!/bin/bash

daemon_stopped () {
  outcome=$(pgrep -af "$1")
  stopped=0;
  if [[ ${outcome} == "" ]]; then
    stopped=1;
  fi
  while [[ ${stopped} -eq 0 ]]; do
    #pgrep -af "$1" > /dev/null 2>&1
    outcome=$(pgrep -af "$1")
    if [[ ${outcome} != "" ]]; then
      stopped=1;
      echo "Stopping $1"
    fi
    echo "outcome: $outcome"
    sleep 2
  done
}

init_chain () {
  echo "starting $1 $2"
  komodod -ac_name=$1 $2 > /dev/null 2>&1 &
  notarizedhash=$(komodo-cli -ac_name=$1 getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
  while [[ ${#notarizedhash} -ne 64 ]]; do
    echo "waiting for STAKEDB1 to sync, trying again in 10 seconds"
    notarizedhash=$(komodo-cli -ac_name=$1 getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
    sleep 10
  done
}

# Stratum port to start
stratumport=3030

#set config dirs
coinsdir=/home/$USER/Knomp/coins
poolconfigdir=/home/$USER/Knomp/pool_configs
rm -rf $coinsdir
rm -rf $poolconfigdir
mkdir -p $coinsdir
mkdir -p $poolconfigdir

#prepare template
coinstpl=/home/$USER/Knomp/coins.template
pooltpl=/home/$USER/Knomp/poolconfigs.template
cointemplate=$(<$coinstpl)
pooltemplate=$(<$pooltpl)

#setup firewall files
ufwenablefile=/home/$USER/Knomp/stratufwenable
rm $ufwenablefile
touch $ufwenablefile
ufwdisablefile=/home/$USER/Knomp/stratufwdisable
chmod +x $ufwdisablefile
$ufwdisablefile
rm $ufwdisablefile
touch $ufwdisablefile

cd /home/smk762/Knomp/scripts
ac_jsonfile="$HOME/.komodo/assetchains.json"
Radd=$(./printkey.py Radd)
privkey=$(./printkey.py wif)
pubkey=$(./printkey.py pub)
startKMD () {
  echo "[master] Checking for updates and building if required..."
  result=$(./update_komodo.sh master)
  if [[ $result = "updated" ]]; then
    echo "[master] Updated to latest"
    master_updated=1
    echo "[KMD] Stopping ..."
    komodo-cli stop > /dev/null 2>&1
    daemon_stopped "komodod.*"
    echo "[KMD] Stopped."
  elif [[ $result = "update_failed" ]]; then
    echo -e "\033[1;31m [master] ABORTING!!! failed to update, Help Human! \033[0m"
    exit
  else
    echo "[master] No update required"
  fi
  komodod -pubkey=$pubkey > /dev/null 2>&1 &
  notarizedhash=$(komodo-cli -ac_name=$1 getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
  while [[ ${#notarizedhash} -ne 64 ]]; do
    echo "waiting for KMD to sync, trying again in 10 seconds"
    notarizedhash=$(komodo-cli -ac_name=$1 getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
    sleep 10
  done
  ./validateaddress.sh "KMD"
}
startKMD
echo -e "\e[91m WARNING: This script creates addresses to be used in pool config and payment processing"
echo " The address, privkey, and pubkey are stored in a owner read-only file"
echo -e " make sure to encrypt, backup, or delete as required \e[39m"
sleep 7
if [ ! -d ~/wallets  ]; then
  mkdir ~/wallets
fi
    
init_chain "STAKEDB1" "-ac_supply=100000 -ac_reward=1000000000 -ac_cc=667 -addnode=195.201.137.5 -addnode=195.201.20.230 "
./validateaddress.sh "STAKEDB1"
komodo-cli -ac_name=STAKEDB1 importprivkey $privkey > /dev/null 2>&1
komodo-cli -ac_name=STAKEDB1 stop > /dev/null 2>&1
daemon_stopped "komodod.*\-ac_name=STAKEDB1"
sleep 7
init_chain "STAKEDB1" "-ac_supply=100000 -ac_reward=1000000000 -ac_cc=667 -addnode=195.201.137.5 -addnode=195.201.20.230 -pubkey=$pubkey"
sleep 7
orclid=01c542e1c65724007b2a42d16d4b8a7b5d38acdc6e3be190f14f9afd1449a160
sub=03159df1aa62f6359aed850b27ce07e47e25c16ef7ea867f7dde1de26813db34d8
oracleinfo=$(komodo-cli -ac_name=STAKEDB1 oraclesinfo $orclid)
result=$(echo $oracleinfo | jq -r -c '.result')
while [[ $result != "success" ]]; do
  echo "awkening oracle"
  sleep 3
  oracleinfo=$(komodo-cli -ac_name=STAKEDB1 oraclesinfo $orclid)
  result=$(echo $oracleinfo | jq -r -c '.result')
done
echo "oracle responded"
pubs=$(komodo-cli -ac_name=STAKEDB1 oraclesinfo $orclid | jq -r '.registered | .[] | .publisher')
pubsarray=(${pubs///n/ })
batons=$(komodo-cli -ac_name=STAKEDB1 oraclesinfo $orclid | jq -r '.registered | .[] | .batontxid')
batonarray=(${batons///n/ })
len=$(komodo-cli -ac_name=STAKEDB1 oraclesinfo $orclid | jq -r '[.registered | .[] | .publisher] | length')

for i in $(seq 0 $(( $len - 1 ))); do
  if [ $sub = ${pubsarray[$i]} ]; then
    komodo-cli -ac_name=STAKEDB1 oraclessamples $orclid ${batonarray[$i]} 1 | jq -r '.samples[0][0]' | jq . > $HOME/.komodo/assetchains.json
  fi
done
ac_json=$(cat "$HOME/.komodo/assetchains.json")
sleep 7
echo $ac_json > $ac_jsonfile

#Get Asset Chain Names from json file

./listbranches.py "$ac_jsonfile" | while read branch; do
  if [[ $branch != "master" ]]; then
    echo "[$branch] Checking for updates and building if required..."
    result=$(./update_komodo.sh $branch)
    if [[ $result = "updated" ]]; then
      echo "[$branch] Updated to latest"
      updated_chain=$(echo "${ac_json}" | jq  -r .[$i].ac_name)
    komodo-cli -ac_name=$updated_chain importprivkey $privkey > /dev/null 2>&1
      echo "[$updated_chain] Stopping ..."
    komodo-cli -ac_name=$updated_chain stop > /dev/null 2>&1
    daemon_stopped "komodod.*\-ac_name=${updated_chain}"
      echo "[$updated_chain] Stopped."
    elif [[ $result = "update_failed" ]]; then
      echo -e "\033[1;31m [$branch] ABORTING!!! failed to update, Help Human! \033[0m"
      exit
    else
      echo "[$branch] No update required"
    fi
  elif [[ $master_updated = 1 ]]; then
    updated_chain=$(echo "${ac_json}" | jq  -r .[$i].ac_name)
    komodo-cli -ac_name=$updated_chain importprivkey $privkey > /dev/null 2>&1
    echo "[$updated_chain] Stopping ..."
    komodo-cli -ac_name=$updated_chain stop > /dev/null 2>&1
    daemon_stopped "komodod.*\-ac_name=${updated_chain}"
    echo "[$updated_chain] Stopped."
  fi
  i=$(( $i +1 ))
done
for chain_params in $(echo "${ac_json}" | jq  -c -r '.[]'); do
  echo "getting $ac_name chain parameters"
  ac_name=$(echo $chain_params | jq -r '.ac_name')
  ac_supply=$(echo $chain_params | jq -r '.ac_supply')
  ac_reward=$(echo $chain_params | jq -r '.ac_reward')
  ac_staked=$(echo $chain_params | jq -r '.ac_staked')
  ac_end=$(echo $chain_params | jq -r '.ac_end')
  ac_cc=$(echo $chain_params | jq -r '.ac_cc')
  ac_perc=$(echo $chain_params | jq -r '.ac_perc')
  ac_pubkey=$(echo $chain_params | jq -r '.ac_pubkey')
  nodes=$(echo $chain_params | jq -r '.addnode')
  branch=$(echo $chain_params | jq -r '.branch')
  acName_flag="-ac_name=${ac_name}"
  ac_params="-ac_supply=$ac_supply -ac_reward=$ac_reward -ac_staked=$ac_staked -ac_end=$ac_end -ac_cc=$ac_cc -ac_perc=$ac_perc -ac_pubkey=$ac_pubkey"
  for node in $(echo $nodes | jq -r '.[]'); do
    ac_params+=" -ac_node=$node"
  done
  ac_params+=" -ac_node=149.28.8.219"
  ac_params+=" -pubkey=$pubkey"
  sleep 7
  if [ $ac_perc != null ]; then
    echo -e "\e[91m ** [${ac_name}] ac_perc coin detected - incompatible with pool, omitting. ** \e[39m"
  else
    if [[ $branch == "null" ]]; then
      init_chain $ac_name "${ac_params[@]}" &
    else
      /home/$USER/StakedNotary/komodo/$branch/komodod -ac_name=${ac_name} "${ac_params[@]}" > /dev/null 2>&1 &
    fi
    echo -e "${col_green}Starting $ac_name Daemon${col_default}"
    notarizedhash=$(komodo-cli -ac_name=$ac_name getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
    while [[ ${#notarizedhash} -ne 64 ]]; do
      echo "waiting for $ac_name with pubkey to sync, trying again in 10 seconds"
      notarizedhash=$(komodo-cli -ac_name=$ac_name getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
      sleep 10
    done
    ./validateaddress.sh $ac_name
    minable=$(komodo-cli -ac_name=$ac_name getblocktemplate | jq -c -r '.previousblockhash')
    if [[ ${#minable} == 64 ]]; then
      echo "Configuring $ac_name with address: ${Radd}"
      touch  ~/wallets/.${ac_name}_poolwallet
      chmod 600  ~/wallets/.${ac_name}_poolwallet
      echo { \"ac_name\":\"${ac_name}\", > ~/wallets/.${ac_name}_poolwallet
      echo \"ac_addr\":\"${Radd}\", >> ~/wallets/.${ac_name}_poolwallet
      echo \"ac_pk\":\"${privkey}\", >> ~/wallets/.${ac_name}_poolwallet
      echo \"ac_pub\":\"${pubkey}\" } >> ~/wallets/.${ac_name}_poolwallet
      string=$(printf '%08x\n' $(komodo-cli -ac_name=${ac_name} getinfo | jq '.magic'))
      magic=${string: -8}
      magicrev=$(echo ${magic:6:2}${magic:4:2}${magic:2:2}${magic:0:2})
      p2pport=$(komodo-cli -ac_name=${ac_name} getinfo | jq '.p2pport')

      rpcuser=$(cat $HOME/.komodo/${ac_name}/${ac_name}.conf | grep rpcuser | sed 's/rpcuser=//')
      rpcpass=$(cat $HOME/.komodo/${ac_name}/${ac_name}.conf | grep rpcpass | sed 's/rpcpassword=//')
      rpcport=$(cat $HOME/.komodo/${ac_name}/${ac_name}.conf | grep rpcport | sed 's/rpcport=//')

      echo "$cointemplate" | sed "s/COINNAMEVAR/${ac_name}/" | sed "s/MAGICREVVAR/$magicrev/"  | sed "s/STAKEDVAR/$ac_staked/" > $coinsdir/${ac_name}.json
     # echo "p2pport / ac_name / Radd / stratumport / rpcport / rpcuser / rpcpass"
     # echo "$p2pport / ${ac_name} / $Radd / $stratumport / $rpcport / $rpcuser / $rpcpass"
      echo "$pooltemplate" | sed "s/P2PPORTVAR/$p2pport/" | sed "s/COINNAMEVAR/${ac_name}/" | sed "s/WALLETADDRVAR/$Radd/" | sed "s/STRATUMPORTVAR/$stratumport/" | sed "s/RPCPORTVAR/$rpcport/" | sed "s/RPCUSERVAR/$rpcuser/" | sed "s/RPCPASSVAR/$rpcpass/" > $poolconfigdir/${ac_name}.json

      echo "sudo ufw allow $rpcport" >> $ufwenablefile
      echo "sudo ufw allow $stratumport" >> $ufwenablefile
      echo "sudo ufw delete allow $stratumport" >> $ufwdisablefile
      let "stratumport = $stratumport + 1"
    else
      echo "$ac_name is unminable!"
      komodo-cli -ac_name=$ac_name stop > /dev/null 2>&1
      daemon_stopped "komodod.*\-ac_name=${ac_name}"
    fi
  fi
done
echo -e "\e[92m Finished: Your address info is located in ~/wallets/.${ac_name}_poolwallet \e[39m"

sleep 10
echo "restarting KMD with pubkey"
komodod -pubkey=$pubkey > /dev/null 2>&1 &
chmod +x $ufwenablefile
$ufwenablefile
