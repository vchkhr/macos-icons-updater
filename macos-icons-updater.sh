# Get current directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check -h flag
if [[ "$1" = "-h" ]]
then
    echo "===============================================================\n\033[0;32mmacOS Icons Updater\033[0m \nhttps://github.com/vchkhr/macos-icons-updater \nPlease read the documentation from the link above before using. \nMIT License is attached at the link above. \n==============================================================="

    return
fi

# Check -nosudo flag
no_sudo=0
if [[ "$1" = "-nosudo" ]]
then
    no_sudo=1
fi

# Count successful and failed jobs
successful_jobs=0
failed_jobs=0
    
# Process all files in the current directory
for icon in *;
do
    # Do not process files of this repository
    if [ $icon = "LICENSE" ] || [ $icon = "macos-icons-updater.sh" ] || [ $icon = "moiu-logo.png" ] || [ $icon = "README.md" ]
    then
        continue
    fi

    # Check if file is icon
    if ! [ ${icon: -5} = ".icns" ]
    then
        echo "\033[1;33mFile was ignored because it is not an icon: "$icon"\033[0m"
        continue
    fi

    # Get app`s name from icon`s name
    app=${icon/".icns"/""}

    # Check if there are app and it's "Info.plist" file
    if [ ! -f /Applications/"$app".app/Contents/Info.plist ]
    then
        echo -e "\033[0;31mNo app found: "$app"\033[0m"
        (( failed_jobs++ ))
        continue
    fi

    # Get the "Info.plist" file of the app (icon's name is written there)
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
        if [[ $nextLineIsAppIcon = 1 ]]
        then
            # Split by ">" and "<"
            appIcon="$(cut -d'>' -f2 <<< "$line")"
            appIcon="$(cut -d'<' -f1 <<< "$appIcon")"
            break
        fi
    done < "$info_plist"

    # Check if icon's name is not found
    if [[ $nextLineIsAppIcon = 0 ]]
    then
        echo -e "\033[0;31mUnable to find icon name in \"Info.plist\" for this app: "$app"\033[0m"
        (( failed_jobs++ ))
        continue
    fi

    # Append ".icns" to icon's name if needed
    if [[ $appIcon != *".icns" ]]
    then
        appIcon=$appIcon".icns"
    fi

    # Replace app's standard icon with the new one and count successful and failed jobs
    if [[ $no_sudo = 0 ]]
    then
        sudo cp ""$script_dir"/"$icon"" "/Applications/"$app".app/Contents/Resources/"$appIcon""
        (( successful_jobs++ ))
    else
        # Check if file is writable or not
        if [ -w "/Applications/"$app".app/Contents/Resources/"$appIcon ]
        then
            cp ""$script_dir"/"$icon"" "/Applications/"$app".app/Contents/Resources/"$appIcon""
            (( successful_jobs++ ))
        else
            echo "\033[0;31mUnable to update icon for this application due to not writable permission: "$app"\033[0m"
            (( failed_jobs++ ))
        fi
    fi

done

# Reload Finder and Dock if not -nosudo flag
if [[ $no_sudo = 0 ]]
then
    sudo killall Finder
    sudo killall Dock
fi

# Display result
if [[ $successful_jobs > 0 ]]
then
    echo "\033[0;32mUpdated icon(s) for "$successful_jobs" app(s)\033[0m"
else
    if [[ $failed_jobs = 0 ]]
    then
        echo "\033[1;33mNo icon(s) updated. Check if you have placed icon(s) in the same directory with this tool\033[0m"
    else
        echo "\033[1;33mNo icon(s) updated due to error(s)\033[0m"
    fi
fi
