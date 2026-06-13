#! /usr/bin/env bash

#entering directory to be backed up and veriying if directory is valid

# --gen-backup , --restore-backup, --help
arg=$1
if [[ -z $arg ]]; then
	echo "backup.sh [arg]"
	echo
	echo " --gen-backup    Generate backup of a directory"
	echo " --restore-bachup    Restore backup of a directory"
	echo "--help    Show options"
elif [[ $arg == "--help" ]]; then
	echo "backup.sh [arg]"
	echo
	echo " --gen-backup    Generate backup of a directory"
	echo " --restore-bachup    Restore backup of a directory"
	echo "--help    Show options"
elif [[ $arg == "--gen-backup" ]]; then
	var=1
	while [[ $var -ne 0 ]]; do
		read -rp "Which folder to backup ? " folder
		if [[ -z "$folder" ]]; then
			echo "Invalid input! ( You must enter a folder)"
			echo
		elif [[ $folder == "$(pwd)" ]]; then
			echo "Invalid input! ( folder must not be working directory)"
			echo
		elif [[ ! -d "$folder" ]]; then
			echo "Directory does not exist"
			echo
		else
			var=0
		fi
	done

	
	var=1
	while [[ $var -ne 0 ]]; do
		read -rp "Destination directory (leave empty for current) : " dest
		dest=${dest:-.}
		if [[ ! -d  "$dest" ]]; then
			echo "Destination directory does not exist"
			echo
		else
			var=0
		fi
	done

	folderName=basename "$folder"
	read -rp "Enter backup name ? ([name].tar.gz)(leave empty for default)" bakName
	bakName=${bakName:-"${folderName}_backup.tar.gz"}
	
	#generating hash checksum
	find "$folder" -type f -exec sha256sum {} + | sort -k 2 > directory_hashes.txt
	mv directory_hashes.txt "$folder"
	
	#generating archive
	tar -czvf "${dest}/${bakName}" "$folder" 
	if [[ $? -eq 0 ]]; then
		echo "Backup complete ! "
	fi
elif [[ $arg == "--restore-backup" ]]; then
	: #TODO: implement restore 
fi
