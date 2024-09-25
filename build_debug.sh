#!/usr/bin/env bash

mkdir -p build

odin build extras/main_release -out:build/game_debug.bin -strict-style -vet -debug
