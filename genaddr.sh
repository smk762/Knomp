#!/bin/bash

checkSync () {
	ac_name=$1
}

#Get Asset Chain Names from json file
echo -e "\e[91m WARNING: This script creates addresses to be use in pool config and payment processing"
echo " The address, privkey, and pubkey are stored in a owner read-only file"
echo -e " make sure to encrypt, backup, or delete as required \e[39m"
if [ ! -d ~/wallets  ]; then
	mkdir ~/wallets
fi
ac_json=$(curl https://raw.githubusercontent.com/StakedChain/StakedNotary/master/assetchains.json 2>/dev/null)
for row in $(echo "${ac_json}" | jq -c -r '.[]'); do
	_jq() {
		echo ${row} | jq -r ${1}
	}
	ac_name=$(_jq '.ac_name')
	if [ ! -d ~/.komodo/${ac_name}  ]; then
		echo -e "\e[91m [ $ac_name ] CONF FILE DOES NOT EXIST!"
                echo -e "Run ~/Knomp/startStaked.sh first \e[39m"
		exit 1
	fi
	if [ ! -f  ~/wallets/.${ac_name}_poolwallet ]; then
		komodod -ac_name=$ac_name > /dev/null 2>&1 &
		sleep 15
		echo "getting address for $ac_name"
		address=$(komodo-cli -ac_name=$ac_name getnewaddress) > /dev/null 2>&1
		while [[ ${#address} -ne 34 ]]; do
			echo "trying to get address for $ac_name again in 10 seconds"
			address=$(komodo-cli -ac_name=$ac_name getnewaddress) > /dev/null 2>&1
			sleep 10
		done
		echo "New address $address created for $ac_name"
		touch  ~/wallets/.${ac_name}_poolwallet
		chmod 600  ~/wallets/.${ac_name}_poolwallet
		echo { \"ac_name\":\"${ac_name}\", > ~/wallets/.${ac_name}_poolwallet
		echo \"ac_addr\":\"${address}\", >> ~/wallets/.${ac_name}_poolwallet
		echo \"ac_pk\":\"$(komodo-cli -ac_name=${ac_name} dumpprivkey $address)\", >> ~/wallets/.${ac_name}_poolwallet
		echo \"ac_pub\":\"$(komodo-cli -ac_name=${ac_name} validateaddress $address | jq -r '.pubkey')\" } >> ~/wallets/.${ac_name}_poolwallet
	else
		echo "ADDRESS FOR $ac_name ALREADY CREATED";
		cat  ~/wallets/.${ac_name}_poolwallet;
	fi
done
echo -e "\e[92m Finished: Your address info is located in ~/wallets/.${ac_name}_poolwallet \e[39m"
