#!/bin/bash


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



cd /home/$USER/StakedNotary
git pull

ac_json=$(curl https://raw.githubusercontent.com/StakedChain/StakedNotary/master/assetchains.json 2>/dev/null)
# Here we will update/add the master branch of StakedNotary/komodo StakedNotary/komodo/<branch>
# and stop komodo if it was updated
echo "[master] Checking for updates and building if required..."
result=$(./update_komodo.sh master)
if [[ $result = "updated" ]]; then
  echo "[master] Updated to latest"
  master_updated=1
  echo "[KMD] Stopping ..."
  komodo-cli stop 
  komodo-cli stop > /dev/null 2>&1
  daemon_stopped "komodod.*\-notary"
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
    result=$(./update_komodo.sh $branch)
    updated_chain=$(echo "${ac_json}" | jq  -r .[$i].ac_name)
  if [[ $branch != "master" ]]; then
    echo "[$branch] Checking for updates and building if required..."
    if [[ $result = "updated" ]]; then
      echo "[$branch] Updated to latest"
    elif [[ $result = "update_failed" ]]; then
      echo -e "\033[1;31m [$branch] ABORTING!!! failed to update, Help Human! \033[0m"
      exit
    else
      echo "[$branch] No update required"
    fi
  fi
    echo "[$updated_chain] Stopping ..."
    komodo-cli -ac_name=$updated_chain stop > /dev/null 2>&1
    sleep 7
    echo "[$updated_chain] Stopped."
 	i=$(( $i +1 ))
done
sleep 7
echo "Starting Redis"
/home/$USER/Knomp/install/redis-stable/src/redis-server /home/$USER/Knomp/install/redis-stable/redis.conf > /dev/null 2>&1 &
sudo ufw allow 6379
cd /home/$USER/Knomp
echo "Generating Pool Addresses"
./genaddr.sh
echo "Generating Pool Configs"
./gencfg.sh
echo "Starting Stomp"
nohup node init &
tail -f nohup.out | grep 2018 &
