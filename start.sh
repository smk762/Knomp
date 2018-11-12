#!/bin/bash


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


longestchain () {
  chain=$1
  if [[ $chain == "KMD" ]]; then
    chain=""
  fi
  tries=0
  longestchain=0
  while [[ $longestchain -eq 0 ]]; do
    info=$(komodo-cli $chain getinfo)
    longestchain=$(echo ${info} | jq -r '.longestchain')
    tries=$(( $tries +1 ))
    if (( $tries > 60)); then
      echo "0"
      return 0
    fi
    sleep 1
  done
  echo $longestchain
  return 1
}

checksync () {
  if [[ $1 == "KMD" ]]; then
    chain=""
  else
    chain="-ac_name=$1"
  fi
  lc=$(longestchain $1)
  if [[ $lc = "0" ]]; then
    connections=$(komodo-cli $chain getinfo | jq -r .connections)
    if [[ $connections = "0" ]]; then
      echo -e "\033[1;31m  [$1] ABORTING - $1 has no network connections, Help Human! \033[0m"
      komodo-cli $chain stop
      return 0
    else
      lc=$(longestchain $1)
    fi
  fi
  if [[ $lc = "0" ]]; then
    blocks=$(komodo-cli $chain getblockcount)
    tries=0
    while (( $blocks < 128 )) && (( $tries < 90 )); do
      echo "[$1] $blocks blocks"
      blocks=$(komodo-cli $chain getblockcount)
      tries=$(( $tries +1 ))
      lc=$(longestchain $1)
      if (( $blocks = $lc )); then
        echo "[$1] Synced on block: $lc"
        return 1
      fi
    done
    if (( blocks = 0 )) && (( lc = 0 )); then
      # this chain is just not syncing even though it has network connections we will stop its deamon and abort for now. Myabe next time it will work.
      komodo-cli $chain stop
      echo -e "\033[1;31m  [$1] ABORTING no blocks or longest chain found, Help Human! \033[0m"
      return 0
    elif (( blocks = 0 )) && (( lc != 0 )); then
      # This chain has connections and knows longest chain, but will not sync, we will kill it. Maybe next time it will work.
      echo -e "\033[1;31m [$1] ABORTING - No blocks synced of $lc. Help Human! \033[0m"
      komodo-cli $chain stop
      return 0
    elif (( blocks > 128 )) && (( lc = 0 )); then
      # This chain is syncing but does not have longest chain. Myabe next time the prcess runs it will work, so we will leave it running but not add it to iguana.
      echo -e "\033[1;31m [$1] ABORTING - Synced to $blocks, but no longest chain is found. Help Human! \033[0m"
      return 0
    fi
  fi
  blocks=$(komodo-cli $chain getblockcount)
  while (( $blocks < $lc )); do
    sleep 60
    lc=$(longestchain $1)
    blocks=$(komodo-cli $chain getblockcount)
    progress=$(echo "scale=3;$blocks/$lc" | bc -l)
    echo "[$1] $(echo $progress*100|bc)% $blocks of $lc"
  done
  echo "[$1] Synced on block: $lc"
  return 1
}

daemon_stopped () {
  stopped=0
  while [[ ${stopped} -eq 0 ]]; do
    pgrep -af "$1" > /dev/null 2>&1
    outcome=$(echo $?)
    if [[ ${outcome} -ne 0 ]]; then
      stopped=1
    fi
    sleep 2
  done
}

echo "Starting Redis"
/home/$USER/Knomp/install/redis-stable/src/redis-server /home/$USER/Knomp/install/redis-stable/redis.conf > /dev/null 2>&1 &
sudo ufw allow 6379
cd /home/$USER/StakedNotary
git pull
pubkey=$(./printkey.py pub)
Radd=$(./printkey.py Radd)
privkey=$(./printkey.py wif)

if [[ ${#pubkey} != 66 ]]; then
  echo -e "\033[1;31m ABORTING!!! pubkey invalid: Please check your config.ini \033[0m"
  exit
fi

if [[ ${#Radd} != 34 ]]; then
  echo -e "\033[1;31m [$1] ABORTING!!! R-address invalid: Please check your config.ini \033[0m"
  exit
fi

if [[ ${#privkey} != 52 ]]; then
  echo -e "\033[1;31m [$1] ABORTING!!! WIF-key invalid: Please check your config.ini \033[0m"
  exit
fi

ac_json=$(cat assetchains.json)
echo $ac_json | jq .[] > /dev/null 2>&1
outcome=$(echo $?)
if [[ $outcome != 0 ]]; then
  echo -e "\033[1;31m ABORTING!!! assetchains.json is invalid, Help Human! \033[0m"
  exit
fi

# Here we will update/add the master branch of StakedNotary/komodo StakedNotary/komodo/<branch>
# and stop komodo if it was updated
echo "[master] Checking for updates and building if required..."
result=$(./update_komodo.sh master)
if [[ $result = "updated" ]]; then
  echo "[master] Updated to latest"
  master_updated=1
  echo "[KMD] Stopping ..."
  komodo-cli stop > /dev/null 2>&1
 # daemon_stopped "komodod.*\-notary"
  echo "[KMD] Stopped."
elif [[ $result = "update_failed" ]]; then
  echo -e "\033[1;31m [master] ABORTING!!! failed to update, Help Human! \033[0m"
  exit
else
  echo "[master] No update required"
fi

# Here we will extract all branches in assetchain.json and build them and move them to StakedNotary/komodo/<branch>
# and stop any staked chains that use master branch if it was updated
i=0
./listbranches.py | while read branch; do
  if [[ $branch != "master" ]]; then
    echo "[$branch] Checking for updates and building if required..."
    result=$(./update_komodo.sh $branch)
    if [[ $result = "updated" ]]; then
      echo "[$branch] Updated to latest"
      updated_chain=$(echo "${ac_json}" | jq  -r .[$i].ac_name)
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
    echo "[$updated_chain] Stopping ..."
    komodo-cli -ac_name=$updated_chain stop > /dev/null 2>&1
    daemon_stopped "komodod.*\-ac_name=${updated_chain}"
    echo "[$updated_chain] Stopped."
  fi
  i=$(( $i +1 ))
done

# Start KMD
echo "[KMD] : Starting KMD"
#komodod -notary -pubkey=$pubkey > /dev/null 2>&1 &
komodod -pubkey=$pubkey > /dev/null 2>&1 &

# Start assets
if [[ $(./assetchains) = "finished" ]]; then
  echo "Started Assetchains"
else
  echo -e "\033[1;31m Starting Assetchains Failed: help human! \033[0m"
  exit
fi

# Validate Address on KMD + AC, will poll deamon until started then check if address is imported, if not import it.
echo "[KMD] : Checking your address and importing it if required."
varesult=$(./validateaddress.sh KMD)
if [[ $varesult = "not_started" ]]; then
  echo -e "\033[1;31m Starting KMD Failed: help human! \033[0m"
  exit
fi
echo "[KMD] : $varesult"

./listassetchains.py | while read chain; do
  # Move our auto generated coins file to the iguana coins dir
  chmod +x "$chain"_7776
  mv "$chain"_7776 iguana/coins
  varesult=$(./validateaddress.sh $chain)
  if [[ $varesult = "not_started" ]]; then
    echo -e "\033[1;31m Starting $chain Failed: help human! \033[0m"
    exit
  fi
  echo "[$chain] : $varesult"
done

cd ~/SuperNET
returnstr=$(git pull)
cd /home/$USER/StakedNotary
if [[ $returnstr = "Already up-to-date." ]]; then
  echo "No Iguana update detected"
else
  rm iguana/iguana
fi

if [[ ! -f iguana/iguana ]]; then
  echo "Building iguana"
  ./build_iguana
  pkill -15 iguana
fi

echo "Checking chains are in sync..."

abort=0
checksync KMD
outcome=$(echo $?)
if [[ $outcome = 0 ]]; then
  abort=1
fi

for chain_params in $(echo "${ac_json}" | jq  -c -r '.[]'); do
  echo "getting $ac_name chain parameters"
  ac_name=$(echo $chain_params | jq -r '.ac_name')
  ac_perc=$(echo $chain_params | jq -r '.ac_perc')
  ac_private=$(echo $chain_params | jq -r '.ac_private')
	checksync $row
	outcome=$(echo $?)
	if [[ $outcome = 0 ]]; then
		abort=1
	fi
	minable=$(komodo-cli -ac_name=$ac_name getblocktemplate | jq -c -r '.previousblockhash')
  if [ $ac_perc != null ]; then
    echo -e "\e[91m ** [${ac_name}] ac_perc coin detected - incompatible with pool, omitting. ** \e[39m"
  elif [ $ac_private -eq 1 ]; then
    echo -e "\e[91m ** [${ac_name}] ac_private coin detected - incompatible with pool, omitting. ** \e[39m"
  elif [[ ${#minable} == 64 ]]; then
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
	fi
done

chmod +x $ufwenablefile
$ufwenablefile


echo "Starting Stomp"
cd $HOME/Knomp
nohup npm start &
tail -f nohup.out | grep 2018 &
