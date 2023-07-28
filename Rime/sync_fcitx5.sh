#!/usr/bin/env bash

fcitx5_is_running=$(pidof -q fcitx5)

if ${fcitx5_is_running} ; then
	killall -9 fcitx5
fi

pushd ~/.local/share/fcitx5/rime/
rime_dict_manager -s

fcitx5 -d > /dev/null 2>&1
