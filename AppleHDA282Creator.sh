#!/bin/bash

# save current working directory
cwd=$(pwd)

# clear display
clear

# retrieve OS X version
osxver=`sw_vers -productVersion`
if [[ $osxver != 10.10* ]] && [[ $osxver != 10.11* ]] && [[ $osxver != 10.12* ]]; then
	echo "Only OS X Yosemite (10.10.x), El Capitan (10.11.x) and Sierra (10.12.x) are supported"
	exit 1
else
	# make sure there is no instance of AppleHDA282.kext in /S/L/E
	echo "Checking if there is a kext with the name 'AppleHDA282.kext' in /S/L/E"
	if [ -e '/System/Library/Extensions/AppleHDA282.kext' ]; then
		sudo rm -R /System/Library/Extensions/AppleHDA282.kext
		echo "   Previous copy of AppleHDA282.kext was found and deleted ..."
	else
		echo "   No trace (good sign) ..."
	fi

	echo "Creating the dummy kext AppleHDA282.kext ..."
	echo "   Cloning AppleHDA.kext ..."
	# the -X switch for the next cp command serve to disable copying extended attributes thus get rids of the message "unable to copy extended attributes to ..."
	sudo cp -XR /System/Library/Extensions/AppleHDA.kext /System/Library/Extensions/AppleHDA282.kext
	echo "   Removing non needed files within the kext ..."
	cd /System/Library/Extensions/AppleHDA282.kext/Contents
	sudo rm -R PlugIns
	sudo rm -R _CodeSignature
	sudo rm Resources/*.xml.zlib
	sudo rm -rf Resources/*.lproj
	sudo rm version.plist
	sudo rm MacOS/AppleHDA
	
	# retrieving AppleHDA version
	hdaver=$(grep -m 1 "Apple Inc" Info.plist | sed 's/.*AppleHDA \(.*\),.*/\1/')
	
	echo "   Linking AppleHDA282.kext with native AppleHDA.kext ..."
	sudo ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA MacOS/AppleHDA
	
	echo "   Patching AppleHDA282.kext with proper codecs for Y510p ..."
	cd $cwd
	sudo cp layout3.xml.zlib /System/Library/Extensions/AppleHDA282.kext/Contents/Resources/
	sudo cp Platforms.xml.zlib /System/Library/Extensions/AppleHDA282.kext/Contents/Resources/
	sudo sed -i "" "s@$hdaver@999.1.1fc1@" /System/Library/Extensions/AppleHDA282.kext/Contents/Info.plist
	sudo sed -i "" "/<string>IOHDACodecFunction<\/string>/r hdaconfig.txt" /System/Library/Extensions/AppleHDA282.kext/Contents/Info.plist

	echo "Clearing kernel extensions cache ..."
	#sudo touch /System/Library/Extensions
	#sudo rm -rf /System/Library/Caches/com.apple.kext.caches/Startup/*
	sudo touch /System/Library/Extensions && sudo kextcache -u / > /dev/null 2>&1

	echo "Fixing permissions ..."
	if [[ $osxver == 10.10* ]]; then		# yosemite
		sudo diskutil repairPermissions / > /dev/null 2>&1
	else 									# el-capitan and beyond
		kextcache -system-prelinked-kernel > /dev/null 2>&1
		kextcache -system-caches > /dev/null 2>&1
	fi

	echo "All done! please reboot ..."
	exit 0
fi
