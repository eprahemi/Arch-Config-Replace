#!/usr/bin/env bash
quickshell -p "$HOME/.config/hypr/scripts/quickshell/Main.qml" ipc call main forceReload
quickshell -p "$HOME/.config/hypr/scripts/quickshell/TopBar.qml" ipc call topbar forceReload
quickshell -p "$HOME/.config/hypr/scripts/quickshell/Floating.qml" ipc call floating forceReload
