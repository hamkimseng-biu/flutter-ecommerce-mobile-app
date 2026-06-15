#!/usr/bin/env fish
# Tiny Chicken - Emulator Launcher
# Fixes Wayland glitching by forcing X11 rendering + NVIDIA GPU

set EMULATOR_ID "Pixel_9"

echo "🐔 Launching Tiny Chicken emulator..."
echo "   GPU: NVIDIA RTX 4060 (prime-run)"
echo "   Renderer: X11/XWayland (fixes Wayland glitches)"
echo ""

# Kill any stale emulator instances
adb -s emulator-5554 emu kill 2>/dev/null
sleep 1

# Launch emulator with fixes
set -x QT_QPA_PLATFORM xcb
prime-run flutter emulators --launch $EMULATOR_ID &

# Wait for emulator to boot
echo "Waiting for emulator to boot..."
flutter emulators --launch $EMULATOR_ID >/dev/null 2>&1 &

# Wait for device to be ready
set timeout 120
set elapsed 0
while test $elapsed -lt $timeout
    set boot_status (adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
    if test "$boot_status" = "1"
        echo ""
        echo "✅ Emulator ready! Run: flutter run"
        break
    end
    echo -n "."
    sleep 3
    set elapsed (math $elapsed + 3)
end

if test $elapsed -ge $timeout
    echo ""
    echo "⚠️  Emulator took too long. Try manually or check for issues."
end


# Manually run it
# QT_QPA_PLATFORM=xcb prime-run flutter emulators --launch Pixel_9