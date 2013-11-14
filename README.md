downtube
========

A simple YouTube video downloader shell script.

Installation
------------

This script can run with either dash or bash.  Other than the shell,
it only requires some very basic UNIX tools, such as, sed, grep, wget,
etc.

How to use
----------

To download a video from YouTube, simply use the URL as a parameter.
For example,

```
$ sh downtube.sh http://www.youtube.com/watch?v=dQw4w9WgXcQ
```

If the given URL is a play list, then all the videos in that list will
be downloaded in sequence.  For example,

```
$ sh downtube.sh http://www.youtube.com/playlist?list=PL8496A23849C610C1
```

You can use `-f FMTS` option specify preferred video formats.  For
example, if you only want to download 720p, H.264-encoded video, use
the following command,

```
$ sh downtube.sh -f 22 http://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Please note that not all formats are supported for every video.

Option `-n` prints out the IDs and titles of the given videos without
downloading them.  Combining with option `-c FILE`, which tracks
videos that have been downloaded using FILE, you can filter out
certain videos by their titles.  For example, if you want to download
videos from a play list without *Rick* in the title, you can first
print out the play list as follows,

```
$ sh downtube.sh -n http://www.youtube.com/playlist?list=PL8496A23849C610C1 >playlist.txt
```

Then, pick out videos with *Rick* in their titles,

```
$ grep Rick playlist.txt >nodownload.txt
```

Now, run downtube again telling it that those videos have already been
downloaded, so downtube will not download them,

```
$ sh downtube.sh -c nodownload.txt http://www.youtube.com/playlist?list=PL8496A23849C610C1
```
