#!/bin/bash

####################################################################################################
#
# Setup Your Mac via swiftDialog
#
# Purpose: Leverages swiftDialog v1.10.2 (or later) (https://github.com/bartreardon/swiftDialog/releases) and 
# Jamf Pro Policy Custom Events to allow end-users to self-complete Mac setup post-enrollment
# via Jamf Pro's Self Service. (See Jamf Pro Known Issues PI100009 - PI-004775.)
#
# Inspired by: Rich Trouton (@rtrouton) and Bart Reardon (@bartreardon)
#
# Based on: Adam Codega (@adamcodega)'s https://github.com/acodega/dialog-scripts/blob/main/MDMAppsDeploy.sh
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1, 19-Mar-2022, Dan K. Snelson (@dan-snelson)
#   Original version
#
# Version 0.0.2, 20-Mar-2022, Dan K. Snelson (@dan-snelson)
#   Corrected initial indeterminate progress bar. (Thanks, @bartreardon!)
#
# Version 0.0.3, 21-Mar-2022, Dan K. Snelson (@dan-snelson)
#   Re-corrected initial indeterminate progress bar.
#
# Version 0.0.4, 16-Apr-2022, Dan K. Snelson (@dan-snelson)
#   Updated for Listview processing https://github.com/bartreardon/swiftDialog/pull/103
#   Added dynamic, policy-based icons
#
# Version 0.0.5, 21-Apr-2022, Dan K. Snelson (@dan-snelson)
#   Standardized references to listitem code to more easily leverage statustext
#   Simplified "jamf policy -event" code
#
# Version 0.0.6, 22-Apr-2022, Dan K. Snelson (@dan-snelson)
#   Added error-checking to appCheck (thanks for the idea, @@adamcodega!)
#
# Version 0.0.7, 29-Apr-2022, Dan K. Snelson (@dan-snelson)
#   Mapped v1.10.2's new "--quitkey" to command+b (because "b" is for Bart!)
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog Title and Message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Setting up your Mac"
message="Please wait while the following apps are downloaded and installed:"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# For each configuration step (i.e., app to be installed), enter a pipe-separated list of:
# Display Name | Filepath for validation | Jamf Pro Policy Custom Event Name | Icon hash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

apps=(
    "1password7|/Applications/1password7.app|1password7|https://adiit.jamfcloud.com/icon?id=5"
    "8x8|/Applications/8x8.app|8x8|https://ics.services.jamfcloud.com/icon/hash_e9487eb95c7b3bb4797395c3e672d19afee6c038fcb2c1e5005f28271fc61f57"
    "Adobe Acrobat Reader DC|/Applications/Adobe Acrobat Reader DC.app|adobereaderdc|https://adiit.jamfcloud.com/icon?id=30"
    "BlueJeans|/Applications/BlueJeans.app|bluejeans|https://ics.services.jamfcloud.com/icon/hash_cf7ce0337747c8f1fd47a1e618a3ba09cdaab7027cc6d45542e5718aef31b43b"
    "Cisco Webex Meetings|/Applications/Cisco Webex Meetings.app|webexmeetings|https://adiit.jamfcloud.com/icon?id=28"
    "Discord|/Applications/discord.app|discord|https://ics.services.jamfcloud.com/icon/hash_c9cc3acce604302efb51c949cacaab390ee5e0df3b67f9f1e95e005c7352a5bc"
    "Firefox|/Applications/firefox.app|firefox|https://adiit.jamfcloud.com/icon?id=26"
    "Google Chrome|/Applications/Google Chrome.app|googlechrome|https://adiit.jamfcloud.com/icon?id=25"
    "Microsoft Defender|/Applications/Microsoft Defender.app|microsoftdefenderatp|https://ics.services.jamfcloud.com/icon/hash_ed56a69efbae442e76a006fa899578d36e34313c5eb57c2fa6846694235f2029"
    "Microsoft Edge|/Applications/Microsoft Edge.app|microsoftedgeenterprisestable|https://adiit.jamfcloud.com/icon?id=24"
    "Microsoft Excel|/Applications/Microsoft Excel.app|microsoftexcel|https://ics.services.jamfcloud.com/icon/hash_cc7dae3eee23a4bb2d370ad921a146547dfbc6a1969309749193ea9c2b1ed173"
    "Microsoft OneNote|/Applications/Microsoft OneNote.app|microsoftonenote|https://ics.services.jamfcloud.com/icon/hash_be465bfc1a778d9e898d228cacdcb17aeaf64d1020d34115013961c930daf133"
    "Microsoft Outlook|/Applications/Microsoft Outlook.app|microsoftoutlook|https://ics.services.jamfcloud.com/icon/hash_45c629f0b5dac8f17a1f1e26446099071cbb0af068597707f6e72abd69024c91"
    "Microsoft PowerPoint|/Applications/Microsoft PowerPoint.app|microsoftpowerpoint|https://adiit.jamfcloud.com/icon?id=25"
    "Microsoft Remote Desktop|/Applications/Microsoft Remote Desktop.app|microsoftremotedesktop|https://adiit.jamfcloud.com/icon?id=25"
    "Microsoft Teams|/Applications/Microsoft Teams.app|microsoftteams|https://ics.services.jamfcloud.com/icon/hash_4e453f09f5119460c51d224b5d7597ec8a187412e4ef4405b5b0d5287c952ac3"
    "Microsoft Word|/Applications/Microsoft Word.app|microsoftword|https://ics.services.jamfcloud.com/icon/hash_5db5888c25e018bec12fd0f46adb529d7f98a634f397b86258dfaef727e6472f"
    "OneDrive|/Applications/OneDrive.app|microsoftonedrive|https://adiit.jamfcloud.com/icon?id=31"
    "Visual Studio Code|/Applications/Visual Studio Code.app|visualstudiocode|https://ics.services.jamfcloud.com/icon/hash_011955c4065d9215a82905984bd200f224c8b3736e3fb947ba64b6fa28b0c02a"
    "Zoom|/Applications/Zoom.app|zoomclient|https://adiit.jamfcloud.com/icon?id=29"
    )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog path and Command File
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/usr/local/bin/dialog"
dialog_command_file="/var/tmp/dialog.log"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Overlay Icon based on Self Service icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

overlayicon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set progress_total to the number of apps in the list
# Add 1 to progress_total for "Updating Inventory step"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

progress_total=${#apps[@]}
progress_total=$(( 1 + progress_total ))


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog icon based on whether the Mac is a desktop or laptop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

hwType=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book")  
if [ "$hwType" != "" ]; then
  icon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
else
  icon="SF=desktopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
fi



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute a Dialog command
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialog_command(){
  echo "$1"
  echo "$1"  >> $dialog_command_file
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finalise app installations
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function finalise(){
  dialog_command "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
  dialog_command "progresstext: Installation of applications complete."
  sleep 5
  dialog_command "icon: https://ics.services.jamfcloud.com/icon/hash_90958d0e1f8f8287a86a1198d21cded84eeea44886df2b3357d909fe2e6f1296"
  dialog_command "progresstext: Updating computer inventory …"
  /usr/local/bin/jamf recon
  dialog_command "icon: SF=checkmark.seal.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
  dialog_command "progresstext: Complete"
  dialog_command "progress: complete"
  dialog_command "button1text: Done"
  dialog_command "button1: enable"
  exit 0
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for app installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function appCheck(){
    if  [ -e "$(echo "$app" | cut -d '|' -f2)" ]; then
        dialog_command "listitem: $(echo "$app" | cut -d '|' -f1): success"
    else
        dialog_command "listitem: title: $(echo "$app" | cut -d '|' -f1), status: fail, statustext: Failed"
    fi
    dialog_command "progress: increment"
}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
  echo "This script should be run as root"
  exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Construct dialog to be displayed to the end-user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCMD="$dialogApp -p --title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--progress $progress_total \
--button1text \"Please Wait\" \
--button1disabled \
--blurscreen \
--ontop \
--overlayicon \"$overlayicon\" \
--titlefont 'size=28' \
--messagefont 'size=14' \
--quitkey b"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create the list of apps
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

listitems=""
for app in "${apps[@]}"; do
  listitems="$listitems --listitem '$(echo "$app" | cut -d '|' -f1)'"
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Final dialog to be displayed to the end-user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCMD="$dialogCMD $listitems"
echo "$dialogCMD"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Launch dialog and run it in the background; sleep for two seconds to let thing initialise
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

eval "$dialogCMD" &
sleep 2



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set initial progress bar
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

progress_index=0
dialog_command "progress: $progress_index"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set wait icon for all listitems 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

for app in "${apps[@]}"; do
  dialog_command "listitem: title: $(echo "$app" | cut -d '|' -f1), status: wait, statustext: Pending"
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Jamf Pro Policy Events 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

(for app in "${apps[@]}"; do
  dialog_command "icon: https://ics.services.jamfcloud.com/icon/hash_$(echo "$app" | cut -d '|' -f4)"
  dialog_command "listitem: title: $(echo "$app" | cut -d '|' -f1), status: pending, statustext: Installing"
  dialog_command "progresstext: Installing $(echo "$app" | cut -d '|' -f1) …"
  /usr/local/bin/jamf policy -event "$( echo "$app" | cut -d '|' -f3 )" -verbose
  appCheck &
done

wait)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete processing and enable the "Done" button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

finalise