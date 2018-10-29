#Install Deps
sudo apt-get update
sudo apt-get -y install build-essential pkg-config libc6-dev m4 g++-multilib autoconf libtool ncurses-dev unzip git python python-zmq zlib1g-dev wget libcurl4-openssl-dev bsdmainutils automake curl nginx
sudo apt-get install libboost-dev libboost-system-dev libsodium-dev -y
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y nodejs
cd $HOME/Knomp
sudo ufw allow 80
nmp install
#Install Komodo
cd ~
git clone https://github.com/stakedchain/komodo.git
git clone https://github.com/StakedChain/StakedNotary
git clone https://github.com/smk762/kmd_pulp
cd komodo
./zcutil/fetch-params.sh
./zcutil/build.sh -j$(nproc)
cd ~
mkdir .komodo
cd .komodo
touch komodo.conf
echo "rpcuser=user`head -c 32 /dev/urandom | base64`" > komodo.conf
echo "rpcpassword=password`head -c 32 /dev/urandom | base64`" >> komodo.conf
echo "daemon=1" >> komodo.conf
echo "server=1" >> komodo.conf
echo "txindex=1" >> komodo.conf
chmod 0600 komodo.conf
sudo ln -sf /home/$USER/komodo/src/komodo-cli /usr/local/bin/komodo-cli
sudo ln -sf /home/$USER/komodo/src/komodod /usr/local/bin/komodod
