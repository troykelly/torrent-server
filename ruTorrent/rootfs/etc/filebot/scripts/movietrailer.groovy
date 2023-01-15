#!/usr/bin/env filebot -script

log.finest "# To complete"

// yt-dlp -f bestvideo+best+bestaudio --video-multistreams --audio-multistreams -o "MOVIENAME (MOVIEYEAR) - trailer.%(ext)s" "ytsearch1: MOVIENAME (MOVIEYEAR) trailer"