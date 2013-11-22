#!/bin/sh

# downtube  Copyright (C) 2013  laborer (laborer@126.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


## User agent spoofing, which is not necessary but left here anyway
## just in case.
# WGET_FLAGS='
# --header="Accept-Language: en-us,en;q=0.5"
# --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
# --header="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7"
# --user-agent="Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.12) Gecko/20101028 Firefox/3.6.12"
# '

## Generate a list of possible video formats
# cat #http://en.wikipedia.org/wiki/YouTube
# sed 's/Sorenson //;s/ Visual//;' |
# tr '[:upper:]' '[:lower:]' | 
# awk '{printf("itag_%s=\"%s,%s,%s,%s,%s\"\n",$1,$2,$3,$4,$5,$6)}'
itag_5="flv,240p,h.263,n/a,0.25"
itag_6="flv,270p,h.263,n/a,0.8"
itag_13="3gp,n/a,mpeg-4,n/a,0.5"
itag_17="3gp,144p,mpeg-4,simple,0.05"
itag_18="mp4,270p/360p,h.264,baseline,0.5"
itag_22="mp4,720p,h.264,high,2-2.9"
itag_34="flv,360p,h.264,main,0.5"
itag_35="flv,480p,h.264,main,0.8-1"
itag_36="3gp,240p,mpeg-4,simple,0.17"
itag_37="mp4,1080p,h.264,high,3–4.3"
itag_38="mp4,3072p,h.264,high,3.5-5"
itag_43="webm,360p,vp8,n/a,0.5"
itag_44="webm,480p,vp8,n/a,1"
itag_45="webm,720p,vp8,n/a,2"
itag_46="webm,1080p,vp8,n/a,n/a"
itag_82="mp4,360p,h.264,3d,0.5"
itag_83="mp4,240p,h.264,3d,0.5"
itag_84="mp4,720p,h.264,3d,2-2.9"
itag_85="mp4,520p,h.264,3d,2-2.9"
itag_100="webm,360p,vp8,3d,n/a"
itag_101="webm,360p,vp8,3d,n/a"
itag_102="webm,720p,vp8,3d,n/a"
itag_120="flv,720p,avc,main@l3.1,2"


usage() {
    echo "Usage: sh downtube.sh [OPTION]... [URL]...

  -f FMTS       specify a list of preferred video formats
  -c FILE       use FILE to keep track of downloaded videos
  -n            no action but show the IDs and titles of the videos
  -h            give this help list
"
}

info_parse() {
    echo "&$1" |
    grep -m 1 -o '&'"$2"'=[^&]*' |
    sed 's@^[^=]*=@@; s@\\@\\\\@g; s@%@\\x@g' |
    while read -r input; do
	/usr/bin/printf "$input\n"
    done
}

downtube_vid() {
    pid=`echo "$1" | grep '/playlist?' | grep -o '[?&]list=[^&]*' | sed 's/^.list=//'`

    [ -z "$pid" ] && pid=`echo "$1" | grep '/user/' | grep -o '[^/]*$'`

    if [ -z "$pid" ]; then
	echo "$1" | grep -o '\(&\|?\)v=[^&#]*' | sed 's@.*=@@'
    else
	wget -O - -q "http://www.youtube.com/view_play_list?p=$pid" |
        grep -o ' href="/watch?v=[^"]*list=..'${pid#??} |
        sed 's@.*v=@@; s@&.*@@' |
	uniq
    fi
}

downtube_get() {
    grep -q "^$1" "$COMPLETED" && return 0

    for i in embedded detailpage vevo; do
	addr='http://www.youtube.com/get_video_info?ps=default&eurl=&gl=US&hl=en'
	addr="${addr}&el=$i"
	addr="${addr}&video_id=$1"
	info=`wget -O - -q "$addr" | tee test.txt` || continue

	token=`info_parse "$info" token`
	[ -n "$token" ] && break
    done
    [ -z "$token" ] && return 1

    url=`info_parse "$info" url_encoded_fmt_stream_map`
    title=`info_parse "$info" title | tr '<>:"/\|?*' _`

    if [ "$DRYRUN" = 'yes' ]; then
        echo "$1 $title"
        return 0
    fi

    echo "Title: $title"
    echo 'Available formats:'
    echo ",${url}," |
    grep -o '[,&]itag=\([0-9]\)\+[,&]' |
    sed 's/itag=//g; s/[,&]//g' |
    while read i; do
        eval codec=\$itag_$i
        echo $i: $codec
    done

    for i in $FORMATS; do
        addr=`echo "$url" | tr , '\n' | grep "itag=$i"` || continue
        sig=`info_parse "$addr" sig`
        addr=`info_parse "$addr" url`
        addr="${addr}&signature=${sig}"
        eval codec=\$itag_$i
        file="${title}-$1-$i.${codec%%,*}"

    	if wget -c -O "$file" "$addr"; then
            echo "$1 $title" >>"$COMPLETED"
            return 0
        fi
    done

    return 1
}

#FORMATS='38 46 37 22 45 35 44 34 18 43 6 5 17 13'
FORMATS='22 35 34 18'
COMPLETED='/dev/null'

unset vids
while [ -n "$*" ]; do
    if getopts nc:f:h key $@; then
        case $key in
            n) DRYRUN="yes";;
	    c) COMPLETED="$OPTARG";;
	    f) FORMATS="$OPTARG";;
            h) usage; exit;;
        esac
        shift `expr $OPTIND - 1`
    else
	ret=`downtube_vid "$1"`
        vids="$vids $ret"
        shift
    fi
    OPTIND=0
done

[ -z "`echo $vids`" ] && return 3

ret=0
for vid in $vids; do
    downtube_get "$vid" || ret=1
done

return $ret
