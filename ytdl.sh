#!/bin/bash

# Set-up your system here
DAYSBACK="5"                                                        # Number of days to go back
LOG_LOC=/home/USER/MediaMgmt/logs/youtube                                         # Log file Location
SAVEPATH=/home/USER/MediaMgmt/in-files/youtube-dl                               # Where video files saved
DBPATH=/home/USER/MediaMgmt/config/youtube-dl/dl-archive-list                     # Where database is saved
USERLIST=/home/USER/MediaMgmt/config/youtube-dl/userList.txt            # Use this for user lists
CHANNELLIST=/home/USER/MediaMgmt/config/youtube-dl/channelList.txt      # Use this for ligitimate channels
HB_OUT_DIR=/media/USER/Media/Youtube/Re-Encoded
ARCHIVE=/media/USER/Media/Youtube/Archive
MUS_DIR=/home/USER/Music/tempMusic

LOG_FILE="youtube_mgmt.log"                                         # prefix to Log filename
YTDL=/home/USER/.local/bin/youtube-dl                           # Use this for ligitimate channels
HANDBRAKE_CLI=/usr/bin/HandBrakeCLI                         # in a terminal type 'which HandBrakeCLI', put that output here
HB_PRESET="AppleTV 3"                                   # Handbrake preset (use `AppleTV 3` when in doubt)
DEST_EXT=mp4



###########################################
# DON'T TOUCH ANYTHING BELOW THIS LINE!!!!#
###########################################

DTE=`date --date="$DAYSBACK days ago" +%Y%m%d`
# Change log file to include datestamp
DATESTAMP=`date "+%Y.%m.%d-%T"`
LOGGER=$LOG_LOC/$DATESTAMP"_"$LOG_FILE
touch $LOGGER
if [ -z "$1" ]; then
  exec 2>&1 > $LOGGER
 else
  exec > >(tee $LOGGER) 2>&1
fi

# Start off the log and terminal window with the date/time
echo "working" $DATESTAMP
echo $DATESTAMP

# Make sure YoutTube-dl isn't currently running
if pgrep -x "youtube-dl" > /dev/null
then 
	echo "Downloader working, fuck off for a bit!"; exit 1; 
fi

# Check if directories exist, if they don't, make them.
if ! [ -d "$SAVEPATH" ];
then
	mkdir -p $SAVEPATH
	echo "created $SAVEPATH"
fi

# Open permissions (mostly for Plex)
chmod 777 -R $SAVEPATH
chmod 777 -R $HB_OUT_DIR
chmod 777 -R $ARCHIVE

if ! [ -d "$DBPATH" ];
then
	mkdir -p $DBPATH
	echo "created $DBPATH"
fi

if ! [ -d "$HB_OUT_DIR" ];
then
	mkdir -p $HB_OUT_DIR
	echo "created $HB_OUT_DIR"
fi

if ! [ -d "$ARCHIVE" ];
then
	mkdir -p $ARCHIVE
	echo "created $ARCHIVE"
fi

##########################################
#        Actual Youtube Downloader       #
##########################################

# Download most recent videos from users

for SHOW in `cat $USERLIST`; do
	echo $YTDL -i http://www.youtube.com/channel/$SHOW --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt
        $YTDL -i http://www.youtube.com/channel/$SHOW -o "$SAVEPATH/ %(upload_date)s - %(title)s.%(ext)s" --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt 

done

# Download most recent videos from channels

for SHOW in `cat $CHANNELLIST`; do
	echo $YTDL -i ytuser:$SHOW --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt
        $YTDL -i ytuser:$SHOW -o "$SAVEPATH/ %(upload_date)s - %(title)s.%(ext)s" --dateafter $DTE --add-metadata --download-archive $DBPATH/$SHOW.txt

done

# Download most recent videos from "Watch Later"
echo "************* GETTING WATCHED LATER PLAYLIST *********************"
$YTDL :ytwatchlater -i -u "USER@email.com" -p 'password' --no-check-certificate -o "$SAVEPATH/ %(upload_date)s - %(title)s.%(ext)s" --add-metadata --download-archive $DBPATH/WatchLater.txt


echo "************* GETTING MUSIC PLAYLIST *********************"
# Download most recent videos from "music" playlist
$YTDL https://www.youtube.com/playlist?list=PLtXjQBXPCJl5CFUOaI6hUwHSpYE9xEQ35 -x -o "$MUS_DIR/%(title)s.%(ext)s" -i --metadata-from-title "%(artist)s - %(title)s" --add-metadata --download-archive $DBPATH/music-Playlist.txt --audio-format "mp3"

find $MUS_DIR/. -type d -empty -exec rm -r {} \; 2>/dev/null
#$YTDL $1 -x -o "$MUS_DIR/%(title)s.%(ext)s" -i --metadata-from-title "%(artist)s - %(title)s" --add-metadata --audio-format "mp3"


###########################################
#               Transcoder                #
##########################################

echo "Files downloaded, beginning transcode"

if pgrep -x "HandBrakeCLI" > /dev/null
then 
	echo "Handbrake currently in use, fuck off for a bit!"; exit 1;
fi

find $SAVEPATH -type f -exec rename 's/ /_/g' {} \; 
for FILE in $(find $SAVEPATH -type f)
do
	filename=$(basename $FILE)
	filename=${filename%.*}
	echo "Transcoding $FILE" 
	$HANDBRAKE_CLI -i $FILE -o "$HB_OUT_DIR/$filename".$DEST_EXT --preset="$HB_PRESET" ;
	mv -v $FILE $ARCHIVE/. ;
done  

find $FILE $ARCHIVE -type f -exec rename 's/_//' {} \;  
find $HB_OUT_DIR -type f -exec rename 's/_/ /g' {} \;  

###########################################
#                   Done                  #
###########################################

echo "Youtube-Dl script has completed"

# Remove tiny & unncecessary log files

find $LOG_LOC -type f -name "*.log" -size -100k -exec rm {} \;


