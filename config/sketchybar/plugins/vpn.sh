#!/bin/bash

VPN_ACTIVE=$(ifconfig 2>/dev/null | awk '/^utun/{iface=$1} /inet [0-9]/{if(iface) print iface}' | wc -l | tr -d ' ')

if [ "$VPN_ACTIVE" -gt 0 ]; then
    sketchybar --set vpn label="VPN ON" label.drawing=on
else
    sketchybar --set vpn label="VPN OFF" label.drawing=on
fi
