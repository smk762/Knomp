#!/bin/bash
# Put the address to mine to here, this is smk762's please change to yours.
walletaddress=RUpV4Mov3Soj34iVNq3hPMCoUFYtB1Jzuf

# Any coins you would like to skip go here
declare -a skip=("BEER" "PIZZA")

# Stratum port to start
stratumport=3030

coinsdir=/home/$USER/Knomp/coins
poolconfigdir=/home/$USER/Knomp/pool_configs

coinstpl=/home/$USER/Knomp/coins.template
pooltpl=/home/$USER/Knomp/poolconfigs.template

ufwenablefile=stratufwenable
ufwdisablefile=stratufwdisable

cointemplate=$(<$coinstpl)
pooltemplate=$(<$pooltpl)

mkdir -p $coinsdir
mkdir -p $poolconfigdir

#clean old up
rm $ufwenablefile
rm $ufwdisablefile

#Get Asset Chain Names from json file
ac_json=$(curl https://raw.githubusercontent.com/blackjok3rtt/StakedNotary/master/assetchains.json 2>/dev/null)
for row in $(echo "${ac_json}" | jq -c -r '.[]'); do
	_jq() {
     		echo ${row} | jq -r ${1}
    	}
	chain=$(_jq '.ac_name')

#Get Asset Chain Names from json file
  if [[ " ${skip[@]} " =~ " ${chain} " ]]; then
   	pointless=0
  else
  	string=$(printf '%08x\n' $(komodo-cli -ac_name=$chain getinfo | jq '.magic'))
    	magic=${string: -8}
	magicrev=$(echo ${magic:6:2}${magic:4:2}${magic:2:2}${magic:0:2})

	p2pport=$(komodo-cli -ac_name=$chain getinfo | jq '.p2pport')
   	thisconf=$(<~/.komodo/$chain/$chain.conf)

   	rpcuser=$(echo $thisconf | grep -Po "rpcuser=(\S*)" | sed 's/rpcuser=//')
   	rpcpass=$(echo $thisconf | grep -Po "rpcpassword=(\S*)" | sed 's/rpcpassword=//')
  	rpcport=$(echo $thisconf | grep -Po "rpcport=(\S*)" | sed 's/rpcport=//')

	echo "$cointemplate" | sed "s/COINNAMEVAR/$chain/" | sed "s/MAGICREVVAR/$magicrev/" > $coinsdir/$chain.json
   	echo "$pooltemplate" | sed "s/P2PPORTVAR/$p2pport/" | sed "s/COINNAMEVAR/$chain/" | sed "s/WALLETADDRVAR/$walletaddress/" | sed "s/STRATUMPORTVAR/$stratumport/" | sed "s/RPCPORTVAR/$rpcport/" | sed "s/RPCUSERVAR/$rpcuser/" | sed "s/RPCPASSVAR/$rpcpass/" > $poolconfigdir/$chain.json

    	echo "sudo ufw allow $stratumport comment 'Stratum $chain'" >> $ufwenablefile
    	echo "sudo ufw delete allow $stratumport" >> $ufwdisablefile
	let "stratumport = $stratumport + 1"
  fi
done

chmod +x $ufwenablefile
chmod +x $ufwdisablefile
