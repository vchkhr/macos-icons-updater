# Get current directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    
# Process all files in the current directory
for icon in *;
do
    # If the file being processed is this program, then skip
    if [ $icon = "macos-update-icons.sh" ]
    then
        continue
    fi

    # Get app name from icon's name
    app=${icon/".icns"/""}

    # Get the "Info.plist" file of the program being processed. This is a file where icon name is written
    info_plist="/Applications/"$app".app/Contents/Info.plist"
    nextLineIsAppIcon=0
    appIcon=""

    # Read every line of "Info.plist" file
    while IFS= read -r line;
    do
        # If this is a key of the icon's name, then make a flag
        if [[ $line == *"<key>CFBundleIconFile</key>"* ]]
        then
            nextLineIsAppIcon=1
            continue
        fi

        # Process the line with the icon's name if flag
        if [ $nextLineIsAppIcon = 1 ]
        then
            # Split by ">" and "<"
            appIcon="$(cut -d'>' -f2 <<< "$line")"
            appIcon="$(cut -d'<' -f1 <<< "$appIcon")"
            break
        fi
    done < "$info_plist"

    # Write error if icon's name is not found
    if [ $nextLineIsAppIcon = 0 ]
    then
        echo "\033[0;31mUnable to find icon name in Info.plist for this application: "$app"\033[0m"
        continue
    fi

    # Append ".icns" to icon's name if needed
    if [[ $appIcon != *".icns" ]]
    then
        appIcon=$appIcon".icns"
    fi

    # Replace app's standard icon with the new one
    sudo cp ""$script_dir"/"$icon"" "/Applications/"$app".app/Contents/Resources/"$appIcon""

done

# Reload Finder and Dock
sudo killall Finder
sudo killall Dock
