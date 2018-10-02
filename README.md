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

Install
-------------
Some initial setup
```shell
cd ~
# git clone https://github.com/StakedChain/Knomp
git clone https://github.com/smk762/Knomp 
cd ~/Knomp/install
./buildkomodo.sh
./installdeps.sh
./buildredis.sh
```
To start redis we need to use a screen or a tmux session to put it into the background, so open one of these and then follow this:
```shell
cd ~/Knomp/install/redis-stable/src
./redis-server ../redis.conf
```
Then disconect from that tmux or screen session. 

To generate a pool for every STAKED chain currently active, we need to start all the chains. 
```shell
cd ~/Knomp/install
./startStaked.sh
```

While waiting for the chains to start, we can edit our `gencfg.sh` script with the address you will be solo mining to, and also change the stratum port if you want to do that (alternatively it will start at port 3030 and increment +1 for each coin listed in assetchains.json). 

Once all these chains have synced up we can run our generator script: `./gencfg.sh`

There are 2 files generated in this folder from this script, `stratufwenable` and `stratufwdisable` these scripts unblock and block the stratum ports we will be using. Just run enable, to unblock the ports and disable to block them again.

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

[Further info on config](https://github.com/zone117x/node-open-mining-portal)

License
-------

Forked from @webworker01's great work who forked it from:

Forked from ComputerGenie repo (deleted)

Released under the GNU General Public License v2
http://www.gnu.org/licenses/gpl-2.0.html

_Forked from [z-classic/z-nomp](https://github.com/z-classic/z-nomp) which is licensed under MIT License (See Old/LICENSE file)_
