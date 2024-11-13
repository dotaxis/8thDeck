#!/bin/bash
. deps/functions.sh
XDG_DESKTOP_DIR=$(xdg-user-dir DESKTOP)
XDG_DATA_HOME="${XDG_DATA_HOME:=${HOME}/.local/share}"
IS_STEAMOS=$(grep -qi "SteamOS" /etc/os-release && echo true || echo false)

echo "" > "8thDeck.log"
exec > >(tee -ia "8thDeck.log") 2>&1

echo "########################################################################"
echo "#                             8thDeck v0.01                            #"
echo "########################################################################"
echo "#    This script will:                                                 #"
echo "# 1. Apply patches to FF8's proton prefix to accomodate Junction VIII  #"
echo "# 2. Install Junction VIII to a folder of your choosing                #"
echo "# 3. Add Junction VIII to Steam using a custom launcher script         #"
echo "# 4. Add a custom controller config for Steam Deck, to allow mouse     #"
echo "#      control with trackpad without holding down the STEAM button     #"
echo "########################################################################"
echo "#           For support, please open an issue on GitHub,               #"
echo "#   or ask in the #Steamdeck-Proton channel of the Tsunamods Discord   #"
echo "########################################################################"
echo -e "\n"

# Check for Proton
while true; do
  if ! pgrep steam > /dev/null; then nohup steam &> /dev/null; fi
  while ! pgrep steam > /dev/null; do sleep 1; done
  PROTON=$(LIBRARY=$(getSteamLibrary 2805730) && [ -n "$LIBRARY" ] && echo "$LIBRARY/steamapps/common/Proton 9.0 (Beta)/proton" || echo "NONE")
  echo -n "Checking if Proton 9 is installed... "
  if [ "$PROTON" = "NONE" ]; then
    echo -e "\nNot found! Launching Steam to install."
    nohup steam steam://install/2805730 &> /dev/null &
    read -p "Press Enter when Proton 9 is done installing."
    killall -9 steam
    while pgrep steam >/dev/null; do sleep 1; done
    rm $HOME/.steam/steam/steamapps/libraryfolders.vdf &>> "8thDeck.log"
    rm $HOME/.steam/steam/config/libraryfolders.vdf &>> "8thDeck.log"
  else
    echo "OK!"
    echo "Found Proton at $PROTON!"
    echo
    break
  fi
done

# Check for SteamLinuxRuntime
while true; do
  if ! pgrep steam > /dev/null; then nohup steam &> /dev/null; fi
  while ! pgrep steam > /dev/null; do sleep 1; done
  RUNTIME=$(LIBRARY=$(getSteamLibrary 1628350) && [ -n "$LIBRARY" ] && echo "$LIBRARY/steamapps/common/SteamLinuxRuntime_sniper/run" || echo "NONE")
  echo -n "Checking if Steam Linux Runtime is installed... "
  if [ "$RUNTIME" = "NONE" ]; then
    echo -e "\nNot found! Launching Steam to install."
    nohup steam steam://install/1628350 &> /dev/null &
    read -p "Press Enter when Steam Linux Runtime 3.0 (sniper) is done installing."
    killall -9 steam
    while pgrep steam >/dev/null; do sleep 1; done
    rm $HOME/.steam/steam/steamapps/libraryfolders.vdf &>> "8thDeck.log"
    rm $HOME/.steam/steam/config/libraryfolders.vdf &>> "8thDeck.log"
  else
    echo "OK!"
    echo "Found SLR at $RUNTIME!"
    echo
    break
  fi
done

# Check for FF8 and set paths
while true; do
  if ! pgrep steam > /dev/null; then nohup steam &> /dev/null; fi
  while ! pgrep steam > /dev/null; do sleep 1; done
  echo -n "Checking if FF8 is installed... "
  FF8_LIBRARY=$(getSteamLibrary 39150 || echo "NONE")
  if [ "$FF8_LIBRARY" = "NONE" ]; then
    echo -e "\nNot found! Launching Steam to install."
    nohup steam steam://install/39150 &> /dev/null &
    read -p "Press Enter when FINAL FANTASY VIII is done installing."
    killall -9 steam
    while pgrep steam > /dev/null; do sleep 1; done
    rm $HOME/.steam/steam/steamapps/libraryfolders.vdf &>> "8thDeck.log"
    rm $HOME/.steam/steam/config/libraryfolders.vdf &>> "8thDeck.log"
  else
    echo "OK!"
    echo "Found FF8 at $FF8_LIBRARY!"
    echo
    break
  fi
done

# Set paths and compat_mounts after libraries have been properly detected
FF8_DIR="$FF8_LIBRARY/steamapps/common/FINAL FANTASY VIII"
WINEPATH="$FF8_LIBRARY/steamapps/compatdata/39150/pfx"
[ $IS_STEAMOS = true ] && WINEPATH="${HOME}/.steam/steam/steamapps/compatdata/39150/pfx"
export STEAM_COMPAT_MOUNTS="$(getSteamLibrary 2805730):$(getSteamLibrary 1628350):$(getSteamLibrary 39150)"

# Force FF8 under Proton 9
echo "Rebuilding FINAL FANTASY VIII under Proton 9..."
while pidof "steam" > /dev/null; do
  killall -9 steam &>> "8thDeck.log"
  sleep 1
done
cp ${XDG_DATA_HOME}/Steam/config/config.vdf ${XDG_DATA_HOME}/Steam/config/config.vdf.bak
perl -0777 -i -pe 's/"CompatToolMapping"\n\s+{/"CompatToolMapping"\n\t\t\t\t{\n\t\t\t\t\t"39150"\n\t\t\t\t\t{\n\t\t\t\t\t\t"name"\t\t"proton_9"\n\t\t\t\t\t\t"config"\t\t""\n\t\t\t\t\t\t"priority"\t\t"250"\n\t\t\t\t\t}/gs' \
${XDG_DATA_HOME}/Steam/config/config.vdf
[ "${WINEPATH}" = */compatdata/39150/pfx ] && rm -rf "${WINEPATH%/pfx}"/*
echo "Sign into the Steam account that owns FF8 if prompted."
nohup steam steam://rungameid/39150 &> /dev/null &
echo "Waiting for Steam..."
while ! pgrep "FF8_Launcher" > /dev/null; do sleep 1; done
killall -9 "FF8_Launcher.exe"
echo

# Fix infinite loop on "Verifying installed game is compatible"
[ -L "$FF8_DIR/FINAL FANTASY VIII" ] && unlink "$FF8_DIR/FINAL FANTASY VIII"

# Ask for install path
echo "Waiting for you to select an installation path..."
promptUser "Choose an installation path for Junction VIII. The folder must already exist."
while true; do
  INSTALL_PATH=$(promptDirectory "Select Junction VIII Install Folder") || { echo "No directory selected. Exiting."; exit 1; }
  promptYesNo "Junction VIII will be installed to $INSTALL_PATH. Continue?"
  case $? in
    0) echo "Installing to $INSTALL_PATH."; break ;;
    1) echo "Select a different path." ;;
    -1) echo "An unexpected error has occurred. Exiting"; exit 1 ;;
  esac
done
echo

# Download Junction VIII from Github
echo "Downloading Junction VIII..."
#downloadDependency "tsunamods-codes/Junction-VIII" "*.exe" VIII_INSTALLER
VIII_INSTALLER="$HOME/.cache/JunctionVIII.exe"
echo

# Install Junction VIII using EXE
echo "Installing Junction VIII..."
mkdir -p "${WINEPATH}/drive_c/ProgramData" # fix vcredist install - infirit
STEAM_COMPAT_APP_ID=39150 STEAM_COMPAT_DATA_PATH="${WINEPATH%/pfx}" \
STEAM_COMPAT_CLIENT_INSTALL_PATH=$(readlink -f "$HOME/.steam/root") \
"$RUNTIME" -- "$PROTON" waitforexitandrun \
"$VIII_INSTALLER" /VERYSILENT /DIR="Z:$INSTALL_PATH" /LOG="JunctionVIII.log" &>> "8thDeck.log"
echo

# Tweaks to Junction VIII install directory
echo "Applying patches to Junction VIII..."
mkdir -p "$INSTALL_PATH/J8Workshop/profiles"
cp -rf "$INSTALL_PATH/Resources/FF8_1.2_Eng_NVPatch/." "$FF8_DIR/"
cp -f "deps/Junction VIII.sh" "$INSTALL_PATH/"
cp -f "deps/functions.sh" "$INSTALL_PATH/"
cp -f deps/settings.xml "$INSTALL_PATH/J8Workshop/"
[ ! -f "$INSTALL_PATH/J8Workshop/profiles/Default.xml" ] && cp "deps/Default.xml" "$INSTALL_PATH/J8Workshop/profiles/" &>> "8thDeck.log"
sed -i "s|@STEAMOS@|$IS_STEAMOS|" "$INSTALL_PATH/Junction VIII.sh"
sed -i "s|<LibraryLocation>REPLACE_ME</LibraryLocation>|<LibraryLocation>Z:$INSTALL_PATH/mods</LibraryLocation>|" "$INSTALL_PATH/J8Workshop/settings.xml"
sed -i "s|<FF8Exe>REPLACE_ME</FF8Exe>|<FF8Exe>Z:$FF8_DIR/FF8.exe</FF8Exe>|" "$INSTALL_PATH/J8Workshop/settings.xml"
echo

# Tweaks to game
echo "Applying patches to FF8..."
cp -f "deps/timeout.exe" "$WINEPATH/drive_c/windows/system32/"
echo "FF8DISC1" > "$WINEPATH/drive_c/.windows-label"
echo "44000000" > "$WINEPATH/drive_c/.windows-serial"
# [ ! -d "$FF8_DIR/music/vgmstream" ] && mkdir -p "$FF8_DIR/music/vgmstream"
# [ -d "$FF8_DIR/data/music_ogg" ] && cp "$FF8_DIR/data/music_ogg/"* "$FF8_DIR/music/vgmstream/"
# if [ -d "$FF8_DIR/data/lang-en" ]; then
#   files=(
#     "battle/camdat0.bin"
#     "battle/camdat1.bin"
#     "battle/camdat2.bin"
#     "battle/co.bin"
#     "battle/scene.bin"
#     "kernel/KERNEL.BIN"
#     "kernel/kernel2.bin"
#     "kernel/WINDOW.BIN"
#   )
#   for file in "${files[@]}"; do
#     ln -fs "$FF8_DIR/data/lang-en/$file" "$FF8_DIR/data/$file"
#   done
# fi
echo

# SteamOS only
if [ $IS_STEAMOS = true ]; then
  # Steam Deck Auto-Config (mod)
  mkdir -p "$INSTALL_PATH/mods"
  cp -rf deps/SteamDeckSettings "$INSTALL_PATH/mods/"

  # This allows moving and clicking the mouse by using the right track-pad without holding down the STEAM button
  echo "Adding controller config..."
  cp -f deps/controller_neptune_gamepad+mouse+click.vdf ${HOME}/.steam/steam/controller_base/templates/controller_neptune_gamepad+mouse+click.vdf
  for CONTROLLERCONFIG in ${HOME}/.steam/steam/steamapps/common/Steam\ Controller\ Configs/*/config/configset_controller_neptune.vdf ; do
    if grep -q "\"39150\"" "$CONTROLLERCONFIG"; then
      perl -0777 -i -pe 's/"39150"\n\s+\{\n\s+"template"\s+"controller_neptune_gamepad_fps.vdf"\n\s+\}/"39150"\n\t\{\n\t\t"template"\t\t"controller_neptune_gamepad+mouse+click.vdf"\n\t\}\n\t"Junction VIII"\n\t\{\n\t\t"template"\t\t"controller_neptune_gamepad+mouse+click.vdf"\n\t\}/gs' "$CONTROLLERCONFIG"
    else
      perl -0777 -i -pe 's/"controller_config"\n\{/"controller_config"\n\{\n\t"39150"\n\t\{\n\t\t"template"\t"controller_neptune_gamepad+mouse+click.vdf"\n\t\}\n\t"Junction VIII"\n\t\{\n\t\t"template"\t"controller_neptune_gamepad+mouse+click.vdf"\n\t\}/' "$CONTROLLERCONFIG"
    fi
  done
  echo
fi

# Add shortcut to Desktop/Launcher
echo "Adding Junction VIII to Desktop and Launcher..."
xdg-icon-resource install deps/Junction-VIII.png --size 64 --novendor
mkdir -p "${XDG_DATA_HOME}/applications" &>> "8thDeck.log"
# Launcher
rm -r "${XDG_DATA_HOME}/applications/Junction VIII.desktop" 2> /dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Junction VIII
Icon=Junction-VIII
Exec=\"$INSTALL_PATH/Junction VIII.sh\"
Path=$INSTALL_PATH
Categories=Game;
Terminal=false
Type=Application
StartupNotify=false" > "${XDG_DATA_HOME}/applications/Junction VIII.desktop"
chmod +x "${XDG_DATA_HOME}/applications/Junction VIII.desktop"
# Desktop
rm -r "${XDG_DESKTOP_DIR}/Junction VIII.desktop" 2> /dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Junction VIII
Icon=Junction-VIII
Exec=\"$INSTALL_PATH/Junction VIII.sh\"
Path=$INSTALL_PATH
Categories=Game;
Terminal=false
Type=Application
StartupNotify=false" > "${XDG_DESKTOP_DIR}/Junction VIII.desktop"
chmod +x "${XDG_DESKTOP_DIR}/Junction VIII.desktop"
update-desktop-database ${XDG_DATA_HOME}/applications &>> "8thDeck.log"
echo

# Add launcher to Steam
echo "Adding Junction VIII to Steam..."
deps/steamos-add-to-steam "${XDG_DATA_HOME}/applications/Junction VIII.desktop" &>> "8thDeck.log"
sleep 5
echo

echo -e "All done!\nYou can close this window and launch Junction VIII from Steam or the desktop now."
