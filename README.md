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
cd ~
git clone https://github.com/StakedChain/knomp
cd ~/Knomp/install
./buildkomodo.sh
./installdeps.sh
./buildredis.sh
```

To generate a pool for every STAKED chain currently active, we need to start all the chains. To do this we run `./startStaked.sh`

Once all these chains have synced up we can run our generator script: `./gencfg.sh`

```shell
cd ~/Knomp
npm install
npm start
```
Thats it. You pool is configured for solo mining. For a public pool, you would need to edit the template files to configure a payment processor manually.

To check which coin has which port:
```shell
cd ~/Knomp/pool_configs
ls (to list the coins)
cat <coin name> (to print the config file, from there find the port parameter)
```

[Further info on config](https://github.com/zone117x/node-open-mining-portal)

License
-------

Forked from ComputerGenie repo (deleted)

Released under the GNU General Public License v2
http://www.gnu.org/licenses/gpl-2.0.html

_Forked from [z-classic/z-nomp](https://github.com/z-classic/z-nomp) which is licensed under MIT License (See Old/LICENSE file)_
