#!/bin/bash

# Patches the iOS project for Oyster: sets codesigning team and provisioning
# profile specifiers for Oyster bundle IDs.
# Idempotent — safe to run multiple times.

set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd ${SCRIPT_DIR}/../ios/App

ls -lah App.xcodeproj/project.pbxproj

FILE="App.xcodeproj/project.pbxproj"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-TEAMID1234}"

# Delete-then-add so the script is idempotent (Add fails if key already exists)
plist_add() {
  /usr/libexec/PlistBuddy -c "Delete $1" "$FILE" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add $1 $2" "$FILE"
}

/usr/libexec/PlistBuddy -c 'Set :objects:504EC2FC1FED79650016851F:attributes:TargetAttributes:504EC3031FED79650016851F:ProvisioningStyle Manual' $FILE
/usr/libexec/PlistBuddy -c 'Set :objects:504EC2FC1FED79650016851F:attributes:TargetAttributes:5FFF7D6927E343FA00B00DA8:ProvisioningStyle Manual' $FILE

/usr/libexec/PlistBuddy -c 'Set :objects:504EC3171FED79650016851F:buildSettings:CODE_SIGN_STYLE Manual' $FILE
plist_add ':objects:504EC3171FED79650016851F:buildSettings:"CODE_SIGN_IDENTITY[sdk=iphoneos*]"' 'String "iPhone Distribution"'
/usr/libexec/PlistBuddy -c 'Set :objects:504EC3171FED79650016851F:buildSettings:DEVELOPMENT_TEAM ""' $FILE
plist_add ':objects:504EC3171FED79650016851F:buildSettings:"DEVELOPMENT_TEAM[sdk=iphoneos*]"' "String $APPLE_TEAM_ID"
plist_add ':objects:504EC3171FED79650016851F:buildSettings:"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]"' 'String "match AppStore com.firehazard.oyster"'

/usr/libexec/PlistBuddy -c 'Set :objects:504EC3181FED79650016851F:buildSettings:CODE_SIGN_STYLE Manual' $FILE
plist_add ':objects:504EC3181FED79650016851F:buildSettings:"CODE_SIGN_IDENTITY[sdk=iphoneos*]"' 'String "iPhone Distribution"'
/usr/libexec/PlistBuddy -c 'Set :objects:504EC3181FED79650016851F:buildSettings:DEVELOPMENT_TEAM ""' $FILE
plist_add ':objects:504EC3181FED79650016851F:buildSettings:"DEVELOPMENT_TEAM[sdk=iphoneos*]"' "String $APPLE_TEAM_ID"
plist_add ':objects:504EC3181FED79650016851F:buildSettings:"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]"' 'String "match AppStore com.firehazard.oyster"'

/usr/libexec/PlistBuddy -c 'Set :objects:5FFF7D7627E343FA00B00DA8:buildSettings:CODE_SIGN_STYLE Manual' $FILE
plist_add ':objects:5FFF7D7627E343FA00B00DA8:buildSettings:"CODE_SIGN_IDENTITY[sdk=iphoneos*]"' 'String "iPhone Distribution"'
/usr/libexec/PlistBuddy -c 'Set :objects:5FFF7D7627E343FA00B00DA8:buildSettings:DEVELOPMENT_TEAM ""' $FILE
plist_add ':objects:5FFF7D7627E343FA00B00DA8:buildSettings:"DEVELOPMENT_TEAM[sdk=iphoneos*]"' "String $APPLE_TEAM_ID"
plist_add ':objects:5FFF7D7627E343FA00B00DA8:buildSettings:"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]"' 'String "match AppStore com.firehazard.oyster.ShareViewController"'

/usr/libexec/PlistBuddy -c 'Set :objects:5FFF7D7727E343FA00B00DA8:buildSettings:CODE_SIGN_STYLE Manual' $FILE
plist_add ':objects:5FFF7D7727E343FA00B00DA8:buildSettings:"CODE_SIGN_IDENTITY[sdk=iphoneos*]"' 'String "iPhone Distribution"'
/usr/libexec/PlistBuddy -c 'Set :objects:5FFF7D7727E343FA00B00DA8:buildSettings:DEVELOPMENT_TEAM ""' $FILE
plist_add ':objects:5FFF7D7727E343FA00B00DA8:buildSettings:"DEVELOPMENT_TEAM[sdk=iphoneos*]"' "String $APPLE_TEAM_ID"
plist_add ':objects:5FFF7D7727E343FA00B00DA8:buildSettings:"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]"' 'String "match AppStore com.firehazard.oyster.ShareViewController"'

/usr/libexec/PlistBuddy -c 'Set :objects:D3490CD72E7CE9EB00E796A6:buildSettings:CODE_SIGN_STYLE Manual' $FILE
plist_add ':objects:D3490CD72E7CE9EB00E796A6:buildSettings:"CODE_SIGN_IDENTITY[sdk=iphoneos*]"' 'String "iPhone Distribution"'
/usr/libexec/PlistBuddy -c 'Set :objects:D3490CD72E7CE9EB00E796A6:buildSettings:DEVELOPMENT_TEAM ""' $FILE
plist_add ':objects:D3490CD72E7CE9EB00E796A6:buildSettings:"DEVELOPMENT_TEAM[sdk=iphoneos*]"' "String $APPLE_TEAM_ID"
plist_add ':objects:D3490CD72E7CE9EB00E796A6:buildSettings:"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]"' 'String "match AppStore com.firehazard.oyster.shortcuts"'

echo Patch OK!
