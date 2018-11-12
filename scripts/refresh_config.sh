Radd=$(komodo-cli getnewaddress)
pubkey=$(komodo-cli validateaddress $Radd | jq -r '.pubkey')
privkey=$(komodo-cli dumpprivkey $Radd)
echo "New address, wif and pubkey created"
stamp=$SECONDS
if [[ ! -d $HOME/Knomp/scripts/conf_bk ]]; then
	mkdir $HOME/Knomp/scripts/conf_bk
fi	

mv $HOME/Knomp/scripts/config.ini $HOME/Knomp/scripts/conf_bk/knomp_config_${SECONDS}.ini 
mv $HOME/StakedNotary/config.ini $HOME/Knomp/scripts/conf_bk/notary_config_${SECONDS}.ini 
echo "Old configs backed up to $HOME/Knomp/scripts/conf_bk/"
balances=($(staked-cli getbalance | tr '\n' ' '))
num_acs=$(echo ${#balances[@]}/2|bc)
echo "$num_acs active asset chains detected. Moving half your funds to the new address..."
echo "WARNING: Does not yet move ac_perc funds via z-addr !!!"
for (( i = 0; i < $num_acs; i++ )); do
	j=$(($i*2))
	sum=$(echo ${balances[$j+1]}/2|bc)
	sum=${sum%.*}
	echo "Sending $sum to $Radd [${balances[$j]}]"
	komodo-cli -ac_name=${balances[$j]} sendtoaddress $Radd ${balances[$j+1]} "" "" true
done

configtemplate="$HOME/Knomp/scripts/example_config.ini"
cat "$configtemplate" | sed "s/btcpubkey =/btcpubkey = ${pubkey}/" | sed "s/wifkey = /wifkey = ${privkey}/"  | sed "s/Radd  =/Radd  = ${Radd}/" > $HOME/Knomp/scripts/config.ini
cp $HOME/Knomp/scripts/config.ini $HOME/StakedNotary/config.ini

