#!/bin/bash
. functions.sh

IS_GAMESCOPE=$(pgrep gamescope > /dev/null && echo true || echo false)
if [ $IS_GAMESCOPE = true ]; then
  echo "d3d9.shaderModel = 1" > dxvk.conf
else
  [ -f "dxvk.conf" ] && rm dxvk.conf
fi

IS_STEAMOS=@STEAMOS@
if [ $IS_STEAMOS = true ] ; then
  export STEAM_COMPAT_DATA_PATH=${HOME}/.steam/steam/steamapps/compatdata/39150
else
  export STEAM_COMPAT_DATA_PATH=$(LIBRARY=$(getSteamLibrary 39150) && [ -n "$LIBRARY" ] && echo "$LIBRARY/steamapps/compatdata/39150" || echo "NONE")
fi

export STEAM_COMPAT_APP_ID=39150
export STEAM_COMPAT_CLIENT_INSTALL_PATH=$(readlink -f "$HOME/.steam/root")
export STEAM_COMPAT_MOUNTS="$(getSteamLibrary 2805730):$(getSteamLibrary 1628350):${STEAM_COMPAT_DATA_PATH%/steamapps/compatdata/39150}"
export WINEDLLOVERRIDES="dinput=n,b"
export DXVK_HDR=0
export PATH=$(echo "${PATH}" | sed -e "s|:$HOME/dotnet||")
unset DOTNET_ROOT

LIBRARY=$(getSteamLibrary 1628350)
if [ -n "$LIBRARY" ]; then
  for path in \
    "$LIBRARY/steamapps/common/SteamLinuxRuntime_sniper/run" \
    "$LIBRARY/steamapps/common/SteamLinuxRuntime_sniper-arm64/run"
  do
    [ -f "$path" ] && RUNTIME="$path" && break
  done
fi
PROTON=$(LIBRARY=$(getSteamLibrary 2805730) && [ -n "$LIBRARY" ] && echo "$LIBRARY/steamapps/common/Proton 9.0 (Beta)/proton")

[ ! -d "$STEAM_COMPAT_DATA_PATH" ] && { promptUser  "FF8 prefix not found!"; exit 1; }
[ -z "$RUNTIME" ] && { promptUser  "Steam Linux Runtime not found!"; exit 1; }
[ -z "$PROTON" ] && { promptUser  "Proton not found!"; exit 1; }

echo "39150" > "$PWD/steam_appid.txt"

"$RUNTIME" -- "$PROTON" waitforexitandrun "$PWD/Junction VIII.exe" $*
