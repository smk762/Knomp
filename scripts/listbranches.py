#!/usr/bin/env python2
import os
import json
import sys

# main
ac_jsonfile=sys.argv[1]

with open(ac_jsonfile) as file:
    assetchains = json.load(file)

for chain in assetchains:
    try:
        print(chain['branch'])
    except Exception as e:
        print("master")