#!/bin/bash

# Any coins you would like to skip go here
# -ac_perc coins are unminable at this stage
# declare -a skip=("BEER" "PIZZA" "STAKEDPERC" "STAKEDCF")


daemon_stopped () {
  stopped=0
  while [[ ${stopped} -eq 0 ]]; do
    #pgrep -af "$1" > /dev/null 2>&1
    pgrep -af "$1" 
    outcome=$(echo $?)
    if [[ ${outcome} -ne 0 ]]; then
      stopped=1
    fi
    sleep 2
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
komodod > /dev/null 2>&1 &
#Get Asset Chain Names from json file
ac_json=$(curl https://raw.githubusercontent.com/StakedChain/StakedNotary/master/assetchains.json 2>/dev/null)
num_chains=$(echo "${ac_json}" | jq  -r '. | length');
for chain_params in $(echo "${ac_json}" | jq  -c -r '.[]'); do
    ac_name=$(echo $chain_params | jq -r '.ac_name')
      daemon_stopped "komodod.*\-ac_name=${ac_name}"
    echo "setting ${ac_name}.conf"
    mkdir ~/.komodo/${ac_name}
	rpcuser="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-8};echo;)"
	rpcpass="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-64};echo;)"
	echo "rpcuser=${rpcuser}" > ~/.komodo/${ac_name}/${ac_name}.conf
	echo "rpcpassword=${rpcpass}" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "rpcport=${rpcport}" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "server=1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "txindex=1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "listen=1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "daemon=1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "rpcworkqueue=256" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "rpcallowip=127.0.0.1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "bind=127.0.0.1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	echo "rpcbind=127.0.0.1" >> ~/.komodo/${ac_name}/${ac_name}.conf
	cat ~/.komodo/${ac_name}/${ac_name}.conf

    echo "getting $ac_name chain parameters"
    acName_flag="-ac_name=${ac_name}"
    ac_supply=$(echo $chain_params | jq -r '.ac_supply')
    ac_reward=$(echo $chain_params | jq -r '.ac_reward')
    ac_staked=$(echo $chain_params | jq -r '.ac_staked')
    ac_end=$(echo $chain_params | jq -r '.ac_end')
    ac_cc=$(echo $chain_params | jq -r '.ac_cc')
    ac_perc=$(echo $chain_params | jq -r '.ac_perc')
    ac_pubkey=$(echo $chain_params | jq -r '.ac_pubkey')
    nodes=$(echo $chain_params | jq -r '.addnode')
    branch=$(echo $chain_params | jq -r '.branch')
    echo "branch: $branch"
    ac_params="-ac_name=$ac_name -ac_supply=$ac_supply -ac_reward=$ac_reward -ac_staked=$ac_staked -ac_end=$ac_end -ac_cc=$ac_cc -ac_perc=$ac_perc -ac_pubkey=$ac_pubkey"
	echo "ac_params: ${ac_params[@]}"
	sleep 7
    for node in $(echo $nodes | jq -r '.[]'); do
		ac_params+=" -ac_node=$node"
    done
	ac_params+=" -ac_node=149.28.8.219"
	if [ ! -f ~/wallets/.${ac_name}_poolwallet ]; then
		echo -e "\e[91m ** Addresses not yet set, run ./genaddr.sh first ** \e[39m"
	elif [ $ac_perc != null ]; then
		echo -e "\e[91m ** [${ac_name}] ac_perc coin detected - incompatible with pool, omitting. ** \e[39m"
	else
		echo -e "${col_green}Getting Pool Wallet info${col_default}"
	    pool_address=$(cat ~/wallets/.${ac_name}_poolwallet | jq  -r '.ac_addr')
		pool_pk=$(cat ~/wallets/.${ac_name}_poolwallet | jq  -r '.ac_pk')
		pool_pub=$(cat ~/wallets/.${ac_name}_poolwallet | jq  -r '.ac_pub')
		echo "address: $pool_address"
		echo "pubkey: $pool_pub"
		sleep 7
		echo -e "${col_green}Starting $ac_name Daemon${col_default}"

	if [[ $branch == "null" ]]; then
		komodod ${ac_params[@]} -pubkey=${pool_pub} > /dev/null 2>&1 &
	else
		/home/$USER/StakedNotary/komodo/$branch/komodod ${ac_params[@]} -pubkey=${pool_pub} > /dev/null 2>&1 &
	fi
		notarizedhash=$(komodo-cli -ac_name=$ac_name getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
		while [[ ${#notarizedhash} -ne 64 ]]; do
			echo "waiting for $ac_name to sync, trying again in 10 seconds"
			notarizedhash=$(komodo-cli -ac_name=$ac_name getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
			sleep 10
		done
	    echo "Configuring $ac_name with address: ${pool_address}"
		komodo-cli -ac_name=${ac_name} importprivkey $pool_pk
	    string=$(printf '%08x\n' $(komodo-cli -ac_name=${ac_name} getinfo | jq '.magic'))
	    magic=${string: -8}
	    magicrev=$(echo ${magic:6:2}${magic:4:2}${magic:2:2}${magic:0:2})
	    p2pport=$(komodo-cli -ac_name=${ac_name} getinfo | jq '.p2pport')
	    rpcport=$(komodo-cli -ac_name=${ac_name} getinfo | jq '.rpcport')

	    echo "$cointemplate" | sed "s/COINNAMEVAR/${ac_name}/" | sed "s/MAGICREVVAR/$magicrev/"  | sed "s/STAKEDVAR/$ac_staked/" > $coinsdir/${ac_name}.json
	    echo "p2pport / ac_name / pool_address / stratumport / rpcport / rpcuser / rpcpass"
	    echo "$p2pport / ${ac_name} / $pool_address / $stratumport / $rpcport / $rpcuser / $rpcpass"
	    echo "$pooltemplate" | sed "s/P2PPORTVAR/$p2pport/" | sed "s/COINNAMEVAR/${ac_name}/" | sed "s/WALLETADDRVAR/$pool_address/" | sed "s/STRATUMPORTVAR/$stratumport/" | sed "s/RPCPORTVAR/$rpcport/" | sed "s/RPCUSERVAR/$rpcuser/" | sed "s/RPCPASSVAR/$rpcpass/" > $poolconfigdir/${ac_name}.json


	    echo "sudo ufw allow $p2pport" >> $ufwenablefile
	    echo "sudo ufw allow $stratumport" >> $ufwenablefile
	    echo "sudo ufw delete allow $stratumport" >> $ufwdisablefile
	    let "stratumport = $stratumport + 1"
	    let "rpcport = $rpcport + 1"
	fi
done
komodod -pubkey=${pool_pub} > /dev/null 2>&1 &
notarizedhash=$(komodo-cli getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
while [[ ${#notarizedhash} -ne 64 ]]; do
	echo "waiting for komodo to sync, trying again in 10 seconds"
	notarizedhash=$(komodo-cli getinfo | jq -c -r '.notarizedhash') > /dev/null 2>&1
	sleep 10
done
komodo-cli -ac_name=${ac_name} importprivkey $pool_pk

chmod +x $ufwenablefile
$ufwenablefile
