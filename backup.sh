#!/usr/bin/env bash
# --gen-backup , --restore-backup, --help
# the script is separated into two parts
#the first part is for generating a backup and a hash of the backup using tar and sha256sum
#second part verifies the integrity of a backup (made using the same script) and restores it to your chosen destination
#most of the script is just user interface fluff to make it easy for anyone who doesn't know how
#to use a command line properly.
#The important part is just around 10 lines
arg=$1
choice=0

if [[ -z $arg ]]; then
    echo "backup.sh [arg]"
    echo
    echo "  --gen-backup      Generate backup of a directory"
    echo "  --restore-backup  Restore backup of a directory"
    echo "  --help            Show options"

elif [[ $arg == "--help" ]]; then
    echo "backup.sh [arg]"
    echo
    echo "  --gen-backup      Generate backup of a directory"
    echo "  --restore-backup  Restore backup of a directory"
    echo "  --help            Show options"

elif [[ $arg == "--gen-backup" ]]; then
   
    var=1
    while [[ $var -ne 0 ]]; do
        read -rp "Which folder to backup? " folder
        if [[ -z "$folder" ]]; then
            echo "Invalid input! (You must enter a folder)"
            echo
        elif [[ "$folder" == "$(pwd)" ]]; then
            echo "Invalid input! (Folder must not be the working directory)"
            echo
        elif [[ ! -d "$folder" ]]; then
            echo "Directory does not exist"
            echo
        else
            var=0
        fi
    done

    folder=$(realpath "$folder")

  
    var=1
    while [[ $var -ne 0 ]]; do
        read -rp "Destination directory (leave empty for current): " dest
        dest=${dest:-.}
        dest=$(realpath "$dest")
        if [[ ! -d "$dest" ]]; then
            echo "Destination directory does not exist"
            echo
        elif [[ "$dest" == "$folder/"* ]]; then
            echo "Destination cannot be inside the source folder"
            echo
        else
            var=0
        fi
    done

    folderName=$(basename "$folder")
    read -rp "Enter backup name (leave empty for default): " bakName
    bakName=${bakName:-"${folderName}"}


    mkdir -p "${dest}/${bakName}"
    tar -czvf "${dest}/${bakName}/${bakName}.tar.gz" "$folder"
    if [[ $? -eq 0 ]]; then
        echo "Backup complete!"
    else
        echo "Backup failed."
        exit 1
    fi

    # --- generate checksum ---
    echo "Generating checksum..."
    sha256sum "${dest}/${bakName}/${bakName}.tar.gz" > "${dest}/${bakName}/${bakName}.tar.gz.sha256"
    echo "Done. Backup saved to: ${dest}/${bakName}/"

elif [[ $arg == "--restore-backup" ]]; then
    # --- locate backup folder ---
    while true; do
        read -rp "Backup folder: " backup
        if [[ ! -d "$backup" ]]; then
            echo "Directory does not exist"
            continue
        fi

        backup=$(realpath "$backup")
        bakName=$(basename "$backup")

        if [[ ! -f "${backup}/${bakName}.tar.gz" ]]; then
            echo "Unable to locate archive (expected: ${bakName}.tar.gz)"
            continue
        fi


        if [[ ! -f "${backup}/${bakName}.tar.gz.sha256" ]]; then
            while true; do
                echo "Backup checksum not found!"
                echo "1 - Continue without verifying integrity"
                echo "2 - Enter checksum location"
                read -rp " : " choice
                if [[ $choice -eq 1 ]]; then
                    hash=""   
                    break
                elif [[ $choice -eq 2 ]]; then
                    read -rp "Enter location (full/path/to/checksum): " hash
                    if [[ ! -f "$hash" ]]; then
                        echo "File does not exist"
                    elif [[ "$hash" != *"tar.gz.sha256" ]]; then
                        echo "Invalid file! Must be a .tar.gz.sha256 file"
                    else
                        break
                    fi
                else
                    echo "Invalid option"
                fi
            done
        else
            hash="${backup}/${bakName}.tar.gz.sha256"
        fi

        break  
    done

    if [[ -n "$hash" ]]; then
        echo "Verifying integrity..."
        if ! sha256sum -c "$hash"; then
            echo "Integrity check failed! Archive may be corrupted."
            exit 1
        fi
        echo "Integrity verified."
    else
        echo "Skipping integrity check."
    fi

    read -rp "Restore to (leave empty for current directory): " restoreDest
    restoreDest=${restoreDest:-.}
    if [[ ! -d "$restoreDest" ]]; then
        echo "Restore destination does not exist"
        exit 1
    fi

    echo "Restoring..."
    tar -xzvf "${backup}/${bakName}.tar.gz" -C "$restoreDest"
    if [[ $? -eq 0 ]]; then
        echo "Restore complete! Files extracted to: $restoreDest"
    else
        echo "Restore failed."
        exit 1
    fi

fi
