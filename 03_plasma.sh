#!/bin/sh

# screen lock
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Autolock "false"

# mouse
# kwriteconfig5 --file $HOME/.config/kcminputrc --group Mouse --key cursorSize "24"
# kwriteconfig5 --file $HOME/.config/kcminputrc --group Mouse --key cursorTheme "Breeze_Snow"

# keyboard
kwriteconfig5 --file $HOME/.config/kcminputrc --group Keyboard --key KeyboardRepeating "0"
kwriteconfig5 --file $HOME/.config/kcminputrc --group Keyboard --key NumLock "0"
kwriteconfig5 --file $HOME/.config/kcminputrc --group Keyboard --key RepeatDelay "200"
kwriteconfig5 --file $HOME/.config/kcminputrc --group Keyboard --key RepeatRate "50"

# layout
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key LayoutList "us,ru"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key LayoutLoopCount "1111111"
sed -i 's/LayoutLoopCount=1111111/LayoutLoopCount=-1/' $HOME/.config/kxkbrc
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key Model "pc105"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key Options "grp:toggle"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key ResetOldOptions "true"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key ShowFlag "true"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key ShowLabel "false"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key ShowLayoutIndicator "true"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key ShowSingle "true"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key SwitchMode "Window"
kwriteconfig5 --file $HOME/.config/kxkbrc --group Layout --key Use "true"

# desktop session
kwriteconfig5 --file $HOME/.config/ksmserverrc --group General --key confirmLogout "false"
kwriteconfig5 --file $HOME/.config/ksmserverrc --group General --key loginMode "emptySession"
kwriteconfig5 --file $HOME/.config/ksmserverrc --group General --key shutdownType "2"

# automounter
kwriteconfig5 --file $HOME/.config/kded5rc --group Module-device_automounter --key autoload "false"

# titlebar buttons
kwriteconfig5 --file $HOME/.config/kwinrc --group org.kde.kdecoration2 --key BorderSize "Normal"
kwriteconfig5 --file $HOME/.config/kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M"
kwriteconfig5 --file $HOME/.config/kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "FIAX"
kwriteconfig5 --file $HOME/.config/kwinrc --group org.kde.kdecoration2 --key ShowToolTips "false"

# night color
kwriteconfig5 --file $HOME/.config/kwinrc --group NightColor --key Active "true"
kwriteconfig5 --file $HOME/.config/kwinrc --group NightColor --key LatitudeAuto "56.8492"
kwriteconfig5 --file $HOME/.config/kwinrc --group NightColor --key LongitudeAuto "53.2319"

# compositing
kwriteconfig5 --file $HOME/.config/kwinrc --group Compositing --key GLCore "true"

kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-Cube --key BorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-Cube --key BorderActivateCylinder "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-Cube --key BorderActivateSphere "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-Cube --key TouchBorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-Cube --key TouchBorderActivateCylinder "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-Cube --key TouchBorderActivateSphere "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-DesktopGrid --key BorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-DesktopGrid --key TouchBorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-PresentWindows --key BorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-PresentWindows --key BorderActivateAll "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-PresentWindows --key BorderActivateClass "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-PresentWindows --key TouchBorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-PresentWindows --key TouchBorderActivateAll "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group Effect-PresentWindows --key TouchBorderActivateClass "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group TabBox --key BorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group TabBox --key BorderAlternativeActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group TabBox --key TouchBorderActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group TabBox --key TouchBorderAlternativeActivate "9"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key Bottom "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key BottomLeft "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key BottomRight "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key Left "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key Right "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key Top "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key TopLeft "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group ElectricBorders --key TopRight "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group TouchEdges --key Bottom "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group TouchEdges --key Left "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group TouchEdges --key Right "None"
kwriteconfig5 --file $HOME/.config/kwinrc --group TouchEdges --key Top "None"

# locale
kwriteconfig5 --file $HOME/.config/plasma-localerc --group Formats --key LANG "en_US.UTF-8"

# power management
kwriteconfig5 --file $HOME/.config/powerdevilrc --group BatteryManagement --key BatteryCriticalAction "1"

# dolphin
kwriteconfig5 --file $HOME/.config/kiorc --group Confirmations --key ConfirmDelete "false"

# bluetooth
declare BT_MAC
BT_MAC=`bluetoothctl list | awk '{print $2}'`
for i in "${BT_MAC[@]}"
do
    kwriteconfig5 --file $HOME/.config/bluedevilglobalrc --group Adapters --key "${i}_powered" "false"
done

# touchpad
declare TOUCHPAD_ADAPTERS
TOUCHPAD_ADAPTERS=`xinput list --name-only | grep -Ei '(touchpad|glidepoint)'`
for i in "${TOUCHPAD_ADAPTERS[@]}"
do
    kwriteconfig5 --file $HOME/.config/touchpadxlibinputrc --group "$i" --key "tapDragLock" "true"
    kwriteconfig5 --file $HOME/.config/touchpadxlibinputrc --group "$i" --key "tapToClick" "true"
done

# wallpaper
# [ ! -L /$HOME/Pictures/wallpaper.jpg ] && ln -s $PWD/wallpaper.jpg /$HOME/Pictures/wallpaper.jpg
# qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var allDesktops = desktops();print (allDesktops);for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = "org.kde.image";d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");d.writeConfig("Image", "file:///home/azat/Pictures/wallpaper.jpg")}'
