## Usage
Make script executable use this command:
sudo chmod +x rtbackup.sh

To run the script, open a terminal and navigate to the directory where the script is located. Then, use the following command:

./rtbackup.sh [options]

### Options

--help		: Display this help message and exit  
--status	: Shows the information about the system (allowed backups, storage,backup directory)  
--start		: Starts the backup if backup.conf is present in current working directory  
--auto-backup	: Starts auto backup  
--checksum	: Prints the checksum verification of created backups  
--crontab	: [not ready]  
--delete	: Deletes all the backups  
