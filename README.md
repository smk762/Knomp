## Mining stratum for Komodo and Komodo assetchains.
### (READY FOR TESTING - Share distribution needs testing)

If starting a fresh VPS, use https://github.com/webworker01/freshubuntu to get you started.

On a low RAM VPS (less than 4gb), it's a good idea to add some swap memory (see https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04)

Requirements (install scripts below)
------------
* node v10+
* libsodium
* boost
* Redis (see https://redis.io/topics/quickstart for details)

Differences between this and Z-NOMP
------------
* This is meant for Komodo mining
* Founders, Treasury, and other ZEC/ZEN specific stuff is removed

Upgrade
-------------
* Please be sure to backup your `./coins` and `./pool_configs` directory before upgrading

Install
-------------
Some initial setup
```shell
<<<<<<< HEAD
# The following packages are needed to build both Komodo and this stratum:
sudo apt-get update
sudo apt-get install build-essential pkg-config libc6-dev m4 g++-multilib autoconf libtool ncurses-dev unzip git python python-zmq zlib1g-dev wget libcurl4-openssl-dev bsdmainutils automake curl libboost-dev libboost-system-dev libsodium-dev jq redis-server -y
=======
cd ~
# git clone https://github.com/StakedChain/Knomp
git clone https://github.com/smk762/Knomp 
cd ~/Knomp/install
./buildkomodo.sh
./installdeps.sh
./buildredis.sh
cd ..
npm install bignum
```
To start redis we need to use a screen or a tmux session to put it into the background, so open one of these and then follow this:
```shell
cd ~/Knomp/install/redis-stable/src
./redis-server ../redis.conf
>>>>>>> master
```
Then disconect from that tmux or screen session. 

To generate a pool for every STAKED chain currently active, we need to start all the chains. 
```shell
<<<<<<< HEAD
git clone https://github.com/jl777/komodo -b FSM
cd komodo
zcutil/fetch-params.sh
zcutil/build.sh -j8
```

We need to generate the coins files (coin daemon must be running!): `gencfg.sh <coin name>`

You can run just gencfg.sh with no coin name to use the assetchains.json in komodo/src directory for all coins. Make sure you edit the template with the correct values you want before running the config generator.

We need node and npminstalled
=======
cd ~/Knomp/install
./startStaked.sh
```

While waiting for the chains to start, we can edit our `gencfg.sh` script with the address you will be solo mining to, and also change the stratum port if you want to do that (alternatively it will start at port 3030 and increment +1 for each coin listed in assetchains.json). 

Once all these chains have synced up we can run our generator script: `./gencfg.sh`

There are 2 files generated in this folder from this script, `stratufwenable` and `stratufwdisable` these scripts unblock and block the stratum ports we will be using. Just run enable, to unblock the ports and disable to block them again.
>>>>>>> master

Here we will install and run the stratum.
```shell
cd ~/Knomp
npm install
```

To run Knomp, you need to have a config.json file in the ~/Knomp directory. For basic use, the default example is fine.

`cp config_example.json config.json`

Now we can start Knomp!

`npm start`

Thats it. You pool is configured for solo mining. For a public pool, you would need to edit the template files and run `gencfg.sh` again or edit each pool_config generate file manually.

To check which coin has which port:
```shell
cd ~/Knomp/pool_configs
ls (to list the coins)
cat <coin name> (to print the config file, from there find the port parameter)
```

## Disable Coinbase Mode 
This mode is enabled by default in the coins.template with`"disablecb" : true` 

To disable it, change the value to false. This mode uses -pubkey to tell the daemon where the coinbase should be sent, and uses the daemons coinbase transaction rather then having the pool create the coinabse transaction. This enables special coinbase transactions, such as ac_founders and ac_script or new modes with CC vouts in the coinbase not yet created, it will work with all coins, except Full Z support described below. 

The pool fee is taken in the payment processor using this mode, and might not be 100% accurate down to the single satoshi, so the pool address may end up with some small amount of coins over time. To use the pool fee, just change `rewardRecipents` value in the `poolconfig.template` before running the `gencfg.sh` script as you normally would for the standard mode.


Full Z Transaction Support
-------------
This is an option to force miners to use a Z address as their username for payouts

In your coins file add: 
```
"privateChain": true,
"burnFees": true
```

For the moment a different dependency is required, in package.json change the last dependency to: 
Edit: *This may be resolved and unneccesary now*
```
"stratum-pool": "git+https://github.com/webworker01/node-stratum-pool.git#notxfee"
```

Do this before running `npm install` above or stop your running instance and run `npm install` `npm start` again after making this change.

[Further info on config](https://github.com/zone117x/node-open-mining-portal)

License
-------

Forked from @webworker01's great work who forked it from:

Forked from ComputerGenie repo (deleted)

Released under the GNU General Public License v2
http://www.gnu.org/licenses/gpl-2.0.html

_Forked from [z-classic/z-nomp](https://github.com/z-classic/z-nomp) which is incorrectly licensed under MIT License - see [zone117x/node-open-mining-portal](https://github.com/zone117x/node-open-mining-portal)_ 
