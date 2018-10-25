#!/bin/bash
echo "Starting Redis"
/home/$USER/Knomp/install/redis-stable/src/redis-server /home/$USER/Knomp/install/redis-stable/redis.conf > /dev/null 2>&1 &
sudo ufw allow 6379
cd /home/$USER/Knomp
echo "Generating Pool Addresses"
./scripts/genaddr.sh
echo "Starting Stomp"
cd $HOME/Knomp
nohup npm start &
tail -f nohup.out | grep 2018 &
