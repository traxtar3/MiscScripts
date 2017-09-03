#!/bin/bash

# Set-up your system here
DAYSBACK="5"                                                        # Number of days to go back
LOG_LOC=/home/USER/logs/youtube                                         # Log file Location
LOG_FILE="youtube_mgmt.log"                                         # prefix to Log filename
SAVEPATH=/media/USER/Media/Youtube                               # Where video files saved
DBPATH=/home/USER/MediaMgmt/YouYubeDl/Shows                     # Where database is saved
USERLIST=/home/USER/MediaMgmt/YouYubeDl/userList.txt            # Use this for user lists
CHANNELLIST=/home/USER/MediaMgmt/YouYubeDl/channelList.txt      # Use this for ligitimate channels
YTDL=/home/USER/.local/bin/youtube-dl                           # Use this for ligitimate channels

###########################################
# DON'T TOUCH ANYTHING BELOW THIS LINE!!!!#
###########################################

#saved from testing
#DTE=`date --date yesterday +%Y%m%d`

DTE=`date --date="$DAYSBACK days ago" +%Y%m%d`
# Change log file to include datestamp
DATESTAMP=`date "+%Y.%m.%d-%T"`
LOGGER=$LOG_LOC/$DATESTAMP"_"$LOG_FILE

# Start off the log and terminal window with the date/time
echo "working" $DATESTAMP
echo $DATESTAMP > $LOGGER

# Make sure YoutTube-dl isn't currently running
if pgrep -x "youtube-dl" > /dev/null
then 
	echo "Downloader working, fuck off for a bit!"; exit 1; >> $LOGGER
fi

# Check if directories exist, if they don't, make them.
if ! [ -d "$SAVEPATH" ];
then
	mkdir -p $SAVEPATH
	echo "created $SAVEPATH" >> $LOGGER
fi

if ! [ -d "$DBPATH" ];
then
	mkdir -p $DBPATH
	echo "created $DBPATH" >> $LOGGER
fi


if ! [ -d "$SAVEPATH/WatchLater/" ];
then
	mkdir -p $SAVEPATH/WatchLater
	echo "created WatchLater" >> $LOGGER
fi

for SHOW in `cat $CHANNELLIST`; do

if ! [ -d "$SAVEPATH/$SHOW/" ];
then
	mkdir -p $SAVEPATH/$SHOW
	echo "created $SHOW" >> $LOGGER
fi
done

for SHOW in `cat $USERLIST`; do

if ! [ -d "$SAVEPATH/$SHOW/" ];
then
	mkdir -p $SAVEPATH/$SHOW
	echo "created $SHOW" >> $LOGGER
fi
done

# Open permissions (mostly for Plex)
chmod 777 -R $SAVEPATH

##########################################
#        Actual Youtube Downloader       #
##########################################


# Download most recent videos from users

for SHOW in `cat $USERLIST`; do
	echo $YTDL -i http://www.youtube.com/channel/$SHOW --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt >> $LOGGER
	cd $SAVEPATH/$SHOW/
        $YTDL -i http://www.youtube.com/channel/$SHOW -o "$SAVEPATH/$SHOW/ %(upload_date)s - %(title)s.%(ext)s" --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt >> $LOGGER 

done

# Download most recent videos from channels

for SHOW in `cat $CHANNELLIST`; do
	echo $YTDL -i ytuser:$SHOW --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt >> $LOGGER
	cd $SAVEPATH/$SHOW/
        $YTDL -i ytuser:$SHOW -o "$SAVEPATH/$SHOW/ %(upload_date)s - %(title)s.%(ext)s" --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt >> $LOGGER

done

# Download most recent videos from "Watch Later"
cd $SAVEPATH/WatchLater
$YTDL :ytwatchlater -i -u "USER@email.com" -p 'yourpassword' --no-check-certificate -o "$SAVEPATH/$SHOW/ %(upload_date)s - %(title)s.%(ext)s" --add-metadata --download-archive $DBPATH/WatchLater.txt >> $$


###########################################
#                   Done                  #
###########################################

echo "Youtube-Dl script has completed" >> $LOGGER
echo "Youtube-Dl script has completed"

# Remove tiny & unncecessary log files

find $LOG_LOC -type f -name "*.log" -size -10 -exec rm {} \;


