#!/bin/bash
# Fetch assetchains.json
wget -qO assetchains.json https://raw.githubusercontent.com/blackjok3rtt/StakedNotary/master/assetchains.json
overide_args="$@"

./listassetchainparams.py | while read args; do
  komodod $args $overide_args -pubkey=$pubkey & #> /dev/null 2>&1 &
  sleep 2
done

# Start assets

