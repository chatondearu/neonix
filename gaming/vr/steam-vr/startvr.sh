#!/usr/bin/env bash

steamapps="$HOME/.steam/steam/steamapps"

# == end config ==
steam_dir=$(dirname $steamapps)

if ! grep 'alvr_server' $steamapps/common/SteamVR/resources/safe_mode_driver_whitelist.json >/dev/null 2>&1; then
	cat $steamapps/common/SteamVR/resources/safe_mode_driver_whitelist.json |
		jq '.drivers |= (. + ["alvr_server"] | unique)' |
		jq '.drivers |= (. + ["01spacecalibrator"] | unique)' \
			>/tmp/safe_mode_driver_whitelist.json

        # whitelist alvr + spacecal to prevent potential blocking
	cp /tmp/safe_mode_driver_whitelist.json $steamapps/common/SteamVR/resources/safe_mode_driver_whitelist.json

        # apply steamvr dashboard spam patch
	wget -O /tmp/patch-bindings.sh https://raw.githubusercontent.com/alvr-org/ALVR-Distrobox-Linux-Guide/main/patch_bindings_spam.sh
	bash /tmp/patch-bindings.sh $steamapps/common/SteamVR
fi

if ! getcap $steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher | grep cap_sys_nice=eip; then
	sudo setcap CAP_SYS_NICE=eip $steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
fi

cleanup() {
	for vrp in vrdashboard vrcompositor vrserver vrmonitor vrwebhelper vrstartup; do
		pkill -f $vrp
	done

	sleep 2

	for vrp in vrdashboard vrcompositor vrserver vrmonitor vrwebhelper vrstartup; do
		pkill -f -9 $vrp
	done
}

startup() {
	cleanup
	rm $steam_dir/logs/vrmonitor.txt 2>/dev/null
	sleep 1
	steam steam://rungameid/250820 &
	sleep 20
}

while true; do
	if ! pidof vrcompositor; then
		startup
	elif ! pidof vrserver; then
		startup
	elif grep 'SteamVR Fail' $steam_dir/logs/vrmonitor.txt; then
		startup
	fi

	sleep 5
done
