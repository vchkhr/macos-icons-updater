# Get current directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check -nosudo flag
no_sudo=0
if [ "$1" = "-nosudo" ]
then
    no_sudo=1
fi
    
# Process all files in the current directory
for icon in *;
do
    # Do not process files of this repository
    if [ $icon = ".gitignore" ] || [ $icon = "icon.png" ] || [ $icon = "LICENSE" ] || [ $icon = "macos-icons-updater.sh" ] || [ $icon = "README.md" ]
    then
        continue
    fi

    # Get app's name from icon's name
    app=${icon/".icns"/""}

    # Check if there is app and it's "Info.plist" file
    if [ ! -f /Applications/"$app".app/Contents/Info.plist ]
    then
        echo "\033[0;31mNo app \""$app"\" for this icon: "$icon"\033[0m"
        continue
    fi

    # Get the "Info.plist" file of the app. Icon's name is written there
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

    # Check if icon's name is not found
    if [ $nextLineIsAppIcon = 0 ]
    then
        echo "\033[0;31mUnable to find icon name in \"Info.plist\" for this app: "$app"\033[0m"
        continue
    fi

    # Append ".icns" to icon's name if needed
    if [[ $appIcon != *".icns" ]]
    then
        appIcon=$appIcon".icns"
    fi

    # Replace app's standard icon with the new one
    if [ $no_sudo = 0 ]
    then
        sudo cp ""$script_dir"/"$icon"" "/Applications/"$app".app/Contents/Resources/"$appIcon""
    else
        cp ""$script_dir"/"$icon"" "/Applications/"$app".app/Contents/Resources/"$appIcon""
    fi
done

# Reload Finder and Dock if not -nosudo flag
if [ $no_sudo = 0 ]
then
    sudo killall Finder
    sudo killall Dock
fi
