#!/usr/bin/env bash

# This script read the backup location from . backup.conf before running this script.
# Default backup option does not look for backup.conf
version="v1.01"
# Code_owner: Premmgr

# generate auto backup config

#auto_conf=.auto_config

echo -e "/etc\n/var\n/home\n/usr/local/bin\n/usr/local/sbin\n/srv\n/opt\n/root" > .auto_conf 2>&1 | tee log/auto_conf.log &> /dev/null
# auto creates requred files
touch backup.conf .auto_conf .location_conf

#user configs
max_backup=9
backup_location=backups


# required vars
date="$(date +%Y-%m-%H%M%S)"
#file_check=check_backup.conf
empty=empty.conf
start_backup=create_tar
clean_tar=delete_old_tar
id_cmd=$(id | awk '{print $1}'| cut -d '(' -f 2 | sed -e 's/)//g')
conf_dir=$(pwd)
loca_dir=$(cat .location_conf)
auto_dir=$(cat .auto_conf)
#find_tar=$(cat .location_conf | xargs -I _ ls _ | grep tar.gz)

# temp local paths
echo "$conf_dir/$backup_location" &> .location_conf

# initial script runtime
if [ ! -e $(pwd)/backup.conf ]; then
        echo -e "\e[33mThis message is shown when backup.conf doesn't exit.\e[0m"
        echo -e "\e[33mbackup.conf was not found, \e[0m\e[34mgenerated empty backup.conf file\e[0m"
        echo ""
        echo ""
fi



# checks if the backup.conf is avaible before executing the script.


function check_backup.conf(){

        [ -s "$(pwd)/backup.conf" ] && echo -e "\e[32mbackup.conf was found.\e[0m" || echo -e "\e[31mError: backup.conf was not found, please check newly generated backup.conf in the current directory.\e[0m"

}

function empty.conf(){

        [ -s "$(pwd)/backup.conf" ]
}


function create_tar(){

        if [ -d data ]; then
                cd "$(pwd)/$backup_location" && tar -czf "backup.$date.tar.gz" $(cat ../backup.conf) &> /dev/null && md5sum "backup.$date.tar.gz" &>> ../log/md5sum.log ; echo -e "\e[32mBackup completed.\e[0m"
                ls | grep tar.gz | xargs -I {} chown $id_cmd:$id_cmd {}
        else
                mkdir $backup_location &> /dev/null && chown $id_cmd:$id_cmd $backup_location &> /dev/null
                cd "$(pwd)/$backup_location" && tar -czf "backup.$date.tar.gz" $(cat ../backup.conf) &> /dev/null && md5sum "backup.$date.tar.gz" &>> ../log/md5sum.log ; echo -e "\e[32mBackup completed.\e[0m"
                ls | grep tar.gz | xargs -I {} chown $id_cmd:$id_cmd {}
                cd ../

        fi
}

# this will list the backup files then sort by oldest ones

function delete_old_tar(){

        local_tar_dir=$(pwd)/$backup_location
        files=$(ls -t $local_tar_dir/*.tar.gz)
        count=$(echo "$files"|wc -l)

 if [ $count -gt $max_backup ]; then
        oldest=$(echo "$files"|tail +10)
        rm $oldest
        echo -e "\e[31mcleaning old backups...\e[0m" ; sleep 2 && echo -e "\e[32mCleaned old backup successfully.\e[0m"
 fi

}


disk_free=$(df -H $(pwd) | awk '{print $4}' | grep -v Avail)


# subcommands

case "$1" in
# prints the realtime status of max_backup, user, backup_location, and the --help

  "--status")
          printf "\n"
          printf "\t\e[33mrtbackup version: $version\e[0m\n\n"
          printf "\t\e[33mthis script uses backup.conf file as input for backup locations.\e[0m\n"
          printf "\t\e[33mauto_backup option doesn't require any custom configuration file for backup.\e[0m\n"
          echo ""


                # show the numbers of allowed backups from max_backup variable
          echo -e ">>>     max allowed backups [\e[32m$max_backup\e[0m] backups"

                # show the current backup location
          echo -e ">>>     backup location [\e[32m$(pwd)/$backup_location\e[0m]"

                # shows the current backup files total size from bacup location
                echo -e ">>>     current backupsize [\e[32m$(du -sh $(pwd) | awk '{print $1}'| sed -e s/G//g)\e[0m] \t\t(G=GigaBytes|K=KiloBytes|M=MegaBytes)"

                # show the free disk space of current directory
                echo -e ">>>	free space in current directory [\e[32m$disk_free\e[0m] \t(G=GigaBytes|K=KiloBytes|M=MegaBytes)"

                # shows the current logged in user
          echo -e ">>>     logged in as [\e[32m$id_cmd\e[0m]"

          printf ">>>     type --help for the help \n\n"
          ;;

# prints the help message for further use case
  "--help")
          printf "\n"
          echo -e ">>>     --install (install on the system) - [\e[36mnot yet ready\e[0m]"
          echo ">>>     --status (check configurations)"
          echo ">>>     --start (start the backup)"
          echo ">>>     --delete (delete all the backups)"
          echo ">>>     --checksum (print checksum of the backups)"
          echo ">>>     --auto-backup (start automatic system backup)"
          echo -e ">>>     --crontab (setup crontab) - [\e[36mnot yet ready\e[0m]"
          echo ">>>     --auto-restore (restores recent auto_backup from backup location)"
          printf "\n"
          ;;
# finds all of tar.gz files in default backup location and deletes them after creating log
  "--delete")
                # prompt confirmation

                echo -e "\e[31mFollowing backups will be remove!\e[0m"
                ls $loca_dir | xargs -I {} echo "[ {} ]"
                read -p "Do you want to delete all the backups? [y/n]: " response

                # deletes all the backup file inside local backup_dir
                if [ $response == 'y' ]; then
                      rm -rf $loca_dir/* && echo "Cleaned the backups and backup_dirs"

                # any key exits by bye message
                else
                      echo "Bye..."
                fi
                ;;
  "--checksum")
          # prints the md5sum for all of backups
          cd $loca_dir && ls | xargs md5sum | xargs -I _ echo -e "\e[32m_\e[0m"


          ;;
  "--start")
         if [ -d log ];then
                 $empty || echo -e "\e[31mError: newly generated backup.conf file is empty, please verify if backup.conf is not empty.\e[0m"
                 $empty && echo -e "\e[32mCreating backup of [$(cat backup.conf)] ...\e[0m" && $start_backup && $clean_tar
                 echo -e "backup comepleted!\ndate:[$date]\nrestoredfrom:[$auto_recent_usr] \nuser:[$id_cmd]\n\n" >> $conf_dir/log/restore.log
         else
                 mkdir log && chmod 777 log
                 $empty || echo -e "\e[31mError: newly generated backup.conf file is empty, please verify if backup.conf is not empty.\e[0m"
                 $empty && echo -e "\e[32mCreating backup of [$(cat backup.conf)] ...\e[0m" && $start_backup && $clean_tar
                 echo -e "backup comepleted!\ndate:[$date]\nrestoredfrom:[$auto_recent_usr] \nuser:[$id_cmd]\n\n" >> $conf_dir/log/restore.log
         fi
         ;;
  "--auto-backup")
          # creates auto backup for the system.
          echo "Following directories are about to be backed up."
          echo -e "\e[32m$(cat .auto_conf | xargs)\e[0m"
          read -p "Do you want to start autobackup? [y/n]: " auto_backup_rep
          if [ $auto_backup_rep == 'y' ]; then
                  # -y creates auto_backup directory automatically
                  mkdir "$(pwd)/$backup_location/auto_backup" &> /dev/null
                  chown -R $id_cmd:$id_cmd "$(pwd)/$backup_location/auto_backup" &> /dev/null
                  chmod 0770 "$(pwd)/$backup_location/auto_backup" &> /dev/nukk
                  echo -e "\e[32mCreating backup of $(cat .auto_conf | xargs) \e[0m"
                  cd "$(pwd)/$backup_location/auto_backup" && tar -czf auto_backup.$date.tar.gz $auto_dir &> /dev/null && md5sum auto_backup.$date.tar.gz &>> ../log/md5sum.log ; echo -e "\e[32mBackup completed.\e[0m"

          else
                  echo "Bye..."
          fi
          ;;
   "--crontab")
          # applies crontab for the automatic backup schedule
          if [ $(id -u) != '0' ]; then
                  echo -e "Please login as \e[31mroot\e[0m,or use \e[33msudo\e[0m for this operation!"
          else
                  echo -e "\e[32mAutomatic backup was applied on crontab.\e[0m"
          fi

          ;;
  "--auto-restore")
          # this will pick recent auto_backup file from backup location, if doesn't exist then throw an error.
          local_tar_dir="$(pwd)/$backup_location/auto_backup"
          auto_recent=$(ls $local_tar_dir | grep auto | tail -1)
          echo -e "Most recent backup >>>       \e[32m$auto_recent\e[0m"
          read -p "Proceed with auto_restore? [y/n]: " auto_recent_rep

          if [ $auto_recent_rep == 'y' ]; then
                  cd $local_tar_dir && tar -xvf $auto_recent && echo -e "\e[32mRestore completed. \ncheck log/restore_auto_backup.log file fore more details.\e[0m"
                  echo -e "date:[$date]\nrestoredfrom:[$auto_recent] \nuser:[$id_cmd]\n\n" >> $conf_dir/log/restore_auto_backup.log
          else
                  echo "cancelling auto restore..."
          fi

          ;;
   "--restore")
          # this will pick recent auto_backup file from backup location created by backup.conf, if doesn't exist then throw an error.
          local_tar_dir_usr="$(pwd)/$backup_location"
          auto_recent_usr=$(ls | grep auto | tail -1)
          echo -e "Most recent backup >>>       \e[32m$auto_recent\e[0m"
          read -p "Proceed with auto_restore? [y/n]: " auto_recent_rep_usr

          if [ $auto_recent_rep_usr == 'y' ]; then
                  cd $local_tar_dir_usr && tar -xvf $auto_recent_usr && echo -e "\e[32mRestore completed. \ncheck log/restore.log file fore more details.\e[0m"
                  echo -e "date:[$date]\nrestoredfrom:[$auto_recent_usr] \nuser:[$id_cmd]\n\n" >> $conf_dir/log/restore.log
          else
                  echo "cancelling auto restore..."
          fi

          ;;

# installs on the binary files into /usr/local/bin
# upcoming -- feature autocompletion not-yet ready
  "--install")
          
  	if [ $(id -u) !== '0' ]; then
		echo -e "Please login as \e[31mroot\e[0m,or use \e[33msudo\e[0m for this operation!"
	else
		echo -e "\e[32minstall complete!.\e[0m"
	fi
          #printf "\t"
          #printf "\n"
          ;;
  *)

          printf "\t\e[31mNo subcommand was provided!\n\e[0m"

          echo ">>>     Use --help for the help "
    ;;
esac
