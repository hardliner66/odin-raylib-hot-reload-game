@echo off

if not exist "build" (
    mkdir build
)

odin build extras/main_release -out:build/game_release.exe -strict-style -vet -no-bounds-check -o:speed -subsystem:windows
