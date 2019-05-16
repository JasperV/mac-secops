#!/bin/bash

# Install script

set -e

STDIN_FILE_DESCRIPTOR="0"
[ -t "$STDIN_FILE_DESCRIPTOR" ] && SETUP_INTERACTIVE="1"

# Initialise (or reinitialise) sudo to save unhelpful prompts later.
sudo_init() {
  if ! sudo -vn &>/dev/null; then
    if [ -n "$SETUP_SUDOED_ONCE" ]; then
      echo "--> Re-enter your password (for sudo access; sudo has timed out):"
    else
      echo "--> Enter your password (for sudo access):"
    fi
    sudo /usr/bin/true
    SETUP_SUDOED_ONCE="1"
  fi
}

# Helper functions
abort()   { echo "!!! $*" >&2; exit 1; }
log()     { sudo_init; echo "--> $*"; }
logk()    { echo "OK"; }
pipi()    { pip install -q --isolated --no-cache-dir --progress-bar emoji $*; }
escape()  { printf '%s' "${1//\'/\'}"; }

# Verify macOs version
grep $Q -E -q "^10.(9|10|11|12|13|14)" <<< "$(sw_vers -productVersion)" || {
  abort "Run this script on macOS 10.9/10/11/12/13/14."
}

# Verify user rights
[ "$USER" = "root" ] && abort "Run this script as yourself, not as root."
grep $Q -q admin <<< "$(groups)" || abort "Add $USER to the admin group."

# Prevent sleeping during script execution, as long as the machine is on AC power
caffeinate -s -w $$ &

# Check for macOS updates and install
if softwareupdate -l 2>&1 | grep $Q "No new software available."; then
  logk
else
  echo
  sudo softwareupdate --install --all
fi

log "Load default firewall config"
launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
launchctl load /System/Library/LaunchAgents/com.apple.alf.useragent.plist
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

log "Enable Logging"
/usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on

log "Enable Stealth Mode"
/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

log "Disable automatic software whitelisting"
/usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
/usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off

log "Reset firewall to finalize changes"
sudo pkill -HUP socketfilterfw

log "Enable Gatekeeper"
sudo spctl --master-enable
sudo spctl --enable --label "Developer ID"

log "Disable Captive Portal"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

# TODO: error: Operation not permitted
# log "Remove language modeling data"
# rm -rfv "~/Library/LanguageModeling/*" "~/Library/Spelling/*" "~/Library/Suggestions/*"

# log "Disable language modeling data collection"
# sudo chmod -R 000 ~/Library/LanguageModeling ~/Library/Spelling ~/Library/Suggestions
# sudo chflags -R uchg ~/Library/LanguageModeling ~/Library/Spelling ~/Library/Suggestions

log "Remove QuickLook metadata"
rm -rfv "~/Library/Application Support/Quick Look/*"

# TODO: error: No such file or directory
# log "Disable QuickLook data logging"
# chmod -R 000 "~/Library/Application Support/Quick Look"
# chflags -R uchg "~/Library/Application Support/Quick Look"

# TODO: error: Operation not permitted
# log "Remove Downloads metadata"
# :>~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2

# TODO: error: Operation not permitted
# log "Disable Quarantine data collection from downloaded files"
# chflags schg ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2

log "Clear SiriAnalytics database"
rm -rfv ~/Library/Assistant/SiriAnalytics.db

log "Enable the macOS screensaver password immediately"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

log "Show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

log "Expose hidden files and Library folder in Finder"
defaults write com.apple.finder AppleShowAllFiles -bool true
chflags nohidden ~/Library

log "Reset Finder to finalize changes"
killAll Finder

log "Disabling printer sharing"
cupsctl --no-share-printers

log "Disable Java in Safari"
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false

log "Add a \"Found this computer?\" message to the login screen."
echo "Please enter your phonenumber:"
read PHONE
LOGIN_TEXT=$(escape "Found this computer? Please call $PHONE. Thanks!")
log "$LOGIN_TEXT" | grep -q '[()]' && LOGIN_TEXT="'$LOGIN_TEXT'"
defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$LOGIN_TEXT"

# Check and enable full-disk encryption.
log "Checking full-disk encryption status:"
if fdesetup status | grep $Q -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
  logk
elif [ -n "$SETUP_INTERACTIVE" ]; then
  echo
  log "Enabling full-disk encryption on next reboot:"
  sudo fdesetup enable -user "$USER" | tee ~/Desktop/"FileVault Recovery Key.txt"
  logk
else
  echo
  abort "Run 'sudo fdesetup enable -user \"$USER\"' to enable full-disk encryption."
fi

echo
echo "*********************************************************************************"
echo "* Please restart your computer to make sure all settings are correctly applied! *"
echo "*********************************************************************************"
