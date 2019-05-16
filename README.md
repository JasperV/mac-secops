## Install
```bash
curl -Ls luminis-secops.jasperv.nl | sh
```
and reboot!


## What it does
- Loads default firewall config
- Enables Logging
- Enables Stealth Mode
- Disables automatic software whitelisting
- Resets firewall to apply the changes
- Enables Gatekeeper
- Disables Captive Portal
- Removes language modeling data
- TODO: Disables language modeling data collection
- TODO: Removes QuickLook metadata
- TODO: Disable QuickLook data logging
- TODO: Remove Downloads metadata
- TODO: Disables Quarantine data collection from downloaded files
- Clears SiriAnalytics database
- Enables the macOS screensaver password immediately
- Shows all filename extensions
- Exposes hidden files and Library folder in Finder
- Resets Finder to finalize changes
- Disables printer sharing
- Disables Java in Safari
- Adds a "Found this computer?" message to the login screen
- Enables full-disk encryption and save the recovery key to ~/Desktop/FileVault Recovery Key.txt

You then need to save this recovery key somewhere not on the computer (e.g. print it).

## Inspiration/based on
https://github.com/alichtman/stronghold

https://github.com/drduh/macOS-Security-and-Privacy-Guide

https://github.com/MikeMcQuaid/strap
