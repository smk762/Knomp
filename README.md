## Mining stratum for Komodo and Komodo assetchains.
### (READY FOR TESTING - Share distribution needs testing)

Requirements
------------
* node v10+
* libsodium
* boost
* Redis (see https://redis.io/topics/quickstart for details)

Differences between this and Z-NOMP
------------
* This is meant for Komodo mining
* Founders, Treasury, and other ZEC/ZEN specific stuff is removed

Install
-------------
Some initial setup
```shell
# The following packages are needed to build both Komodo and this stratum:
sudo apt-get update
sudo apt-get install build-essential pkg-config libc6-dev m4 g++-multilib autoconf libtool ncurses-dev unzip git python python-zmq zlib1g-dev wget libcurl4-openssl-dev bsdmainutils automake curl libboost-dev libboost-system-dev libsodium-dev -y
```
Now, let's build Komodo
```shell
git clone https://github.com/jl777/komodo -b dev
cd komodo
zcutil/fetch-params.sh
zcutil/build.sh -j8
strip src/komodod
strip src/komodo-cli
```
 Now, let's run the assets.
 - This will start ALL of the assets might take a day or so to sync, depending on system speed/network connection.
```shell
cd ~/komodo/src
./assetchains.old
```

 Once all these chains have synced up we can configure the stratum.

 We need node and npm installed

```shell
cd ~
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
```
Now, let's build our stratum and run it (this stage assumes you already have Redis properly installed and running)
This will install the stratum and configure it for all the assetchains on your system automatically. It must be run from the same user as the coin deamons were launched, as it pulls the rpcuser/pass from the conf file in the home directory.
```shell
git clone https://github.com/webworker01/knomp
cd knomp
./gencfg.sh
npm install
npm start
```

[Further info on config](https://github.com/zone117x/node-open-mining-portal)

License
-------

Forked from ComputerGenie repo (deleted)

Released under the GNU General Public License v2
http://www.gnu.org/licenses/gpl-2.0.html

_Forked from [z-classic/z-nomp](https://github.com/z-classic/z-nomp) which is licensed under MIT License (See Old/LICENSE file)_
