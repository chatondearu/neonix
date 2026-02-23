#!/usr/bin/env bash
# Manual WiVRn Installation - Two-step method to avoid timeouts

LOG_FILE="/home/chaton/etc/nixos/.cursor/debug.log"

echo "╔════════════════════════════════════════════════════════╗"
echo "║  WiVRn Manual Installation for Meta Quest 1           ║"
echo "║  Two-step method to avoid timeout issues              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# #region agent log
# Ensure Quest is connected
echo "[Step 1/4] Checking Quest connection..."
adb kill-server 2>/dev/null
sleep 2
adb start-server >/dev/null 2>&1

COUNTER=0
while [ $COUNTER -lt 10 ]; do
    STATE=$(adb devices 2>/dev/null | grep "1PASH9ADAA9133" | awk '{print $2}')
    if [ "$STATE" = "device" ]; then
        echo "✅ Quest is connected and ready"
        break
    elif [ "$STATE" = "offline" ]; then
        echo "⚠️  Quest is offline. Please unlock it... ($COUNTER/10)"
    else
        echo "⚠️  Quest not detected. Checking... ($COUNTER/10)"
    fi
    sleep 3
    COUNTER=$((COUNTER + 1))
done

if [ "$STATE" != "device" ]; then
    echo ""
    echo "❌ Quest not ready. Please:"
    echo "   1. Unplug and replug the USB cable"
    echo "   2. Unlock the Quest"
    echo "   3. Accept USB debugging authorization"
    echo "   4. Run this script again"
    exit 1
fi

timestamp=$(date +%s%3N)
echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"location\":\"manual-wivrn-install.sh:connected\",\"message\":\"Quest connected\",\"data\":{\"state\":\"device\"},\"runId\":\"manual-install\"}" >> "$LOG_FILE"
# #endregion

# #region agent log
# Step 2: Push APK to Quest
APK_PATH="/home/chaton/.cache/wivrn/wivrn-dashboard/wivrn-v25.12.apk"
QUEST_PATH="/data/local/tmp/WiVRn.apk"

echo ""
echo "[Step 2/4] Transferring APK to Quest (25 MB)..."
echo "⏳ This will take 1-2 minutes. Progress will be shown below."
echo ""

PUSH_START=$(date +%s)
PUSH_OUTPUT=$(adb push "$APK_PATH" "$QUEST_PATH" 2>&1)
PUSH_EXIT=$?
PUSH_END=$(date +%s)
PUSH_DURATION=$((PUSH_END - PUSH_START))

echo ""
echo "$PUSH_OUTPUT"
echo ""
echo "Transfer duration: ${PUSH_DURATION} seconds"

timestamp=$(date +%s%3N)
echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"location\":\"manual-wivrn-install.sh:push\",\"message\":\"APK push to Quest\",\"data\":{\"exit_code\":$PUSH_EXIT,\"duration_seconds\":$PUSH_DURATION,\"success\":$([ $PUSH_EXIT -eq 0 ] && echo true || echo false)},\"runId\":\"manual-install\"}" >> "$LOG_FILE"

if [ $PUSH_EXIT -ne 0 ]; then
    echo "❌ Transfer failed!"
    exit 1
fi

echo "✅ APK successfully transferred to Quest"
# #endregion

# #region agent log
# Step 3: Install from Quest
echo ""
echo "[Step 3/4] Installing WiVRn on Quest..."
echo "⏳ Installing from the APK on the Quest's storage..."
echo ""

INSTALL_START=$(date +%s)
INSTALL_OUTPUT=$(adb shell pm install -r "$QUEST_PATH" 2>&1)
INSTALL_EXIT=$?
INSTALL_END=$(date +%s)
INSTALL_DURATION=$((INSTALL_END - INSTALL_START))

echo "$INSTALL_OUTPUT"
echo ""
echo "Installation duration: ${INSTALL_DURATION} seconds"

timestamp=$(date +%s%3N)
echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"location\":\"manual-wivrn-install.sh:install\",\"message\":\"APK installation\",\"data\":{\"exit_code\":$INSTALL_EXIT,\"duration_seconds\":$INSTALL_DURATION,\"output\":\"$(echo "$INSTALL_OUTPUT" | tr '\n' ' ' | sed 's/"/\\"/g')\"},\"runId\":\"manual-install\"}" >> "$LOG_FILE"
# #endregion

# #region agent log
# Step 4: Verify and cleanup
echo ""
echo "[Step 4/4] Verifying installation..."

VERIFY_OUTPUT=$(adb shell pm list packages | grep -i wivrn 2>&1)
if [ -n "$VERIFY_OUTPUT" ]; then
    echo "✅ WiVRn packages found:"
    echo "$VERIFY_OUTPUT"
    
    # Cleanup
    echo ""
    echo "Cleaning up temporary APK on Quest..."
    adb shell rm "$QUEST_PATH" 2>/dev/null
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  ✅ ✅ ✅  INSTALLATION SUCCESSFUL!  ✅ ✅ ✅           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Put on your Quest headset"
    echo "  2. Open the app library (grid icon)"
    echo "  3. Click 'All' at the top right"
    echo "  4. Find 'WiVRn' (may be in 'Unknown Sources')"
    echo "  5. Launch WiVRn"
    echo ""
    echo "To use WiVRn:"
    echo "  - Make sure your PC and Quest are on the same WiFi"
    echo "  - Start the WiVRn server: wivrn-dashboard"
    echo "  - In the Quest, WiVRn will auto-discover your PC"
    echo ""
    
    timestamp=$(date +%s%3N)
    echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"location\":\"manual-wivrn-install.sh:success\",\"message\":\"Installation completed successfully\",\"data\":{\"packages\":\"$(echo "$VERIFY_OUTPUT" | tr '\n' ' ')\"},\"runId\":\"manual-install\"}" >> "$LOG_FILE"
else
    echo "❌ WiVRn not found in installed packages"
    echo ""
    echo "Installation may have failed. Check the error messages above."
    
    timestamp=$(date +%s%3N)
    echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"location\":\"manual-wivrn-install.sh:failed\",\"message\":\"Installation verification failed\",\"data\":{},\"runId\":\"manual-install\"}" >> "$LOG_FILE"
fi
# #endregion

echo ""
echo "═══════════════════════════════════════════════════════════"

