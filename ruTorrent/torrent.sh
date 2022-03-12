#!/usr/bin/env bash
SCRIPTFULL=${0##*/}

RTORRENT=$(command -v rtorrent)
HTPASSWD=$(command -v htpasswd)
CADDY=$(command -v caddy)
PHPCLI=$(command -v php)
FILEBOT=$(command -v filebot)
HOSTNAME=$(hostname)
USERNAME=${RUUSER}
WEBAPP="/app"
WEBAPPDATA="/app-data"
TORRENTSDIR="/torrents"
INSTANCE=1

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done

  ((++wait_seconds))
}

for i in "$@"
do
  case $i in
    -u=*|--username=*)
      USERNAME="${i#*=}"
      shift # past argument=value
      ;;
    -p=*|--password=*)
      PASSWORD="${i#*=}"
      shift # past argument=value
      ;;
    -i=*|--instance=*)
      INSTANCE="${i#*=}"
      shift # past argument=value
      ;;
    -f=*|--from=*)
      FROMLOC="${i#*=}"
      shift # past argument=value
      ;;
    -t=*|--to=*)
      TOLOC="${i#*=}"
      shift # past argument=value
      ;;
    --norun|--confonly)
      NORUN=YES
      shift # past argument with no value
      ;;
    --copy)
      FNCOPY=YES
      shift # past argument with no value
      ;;
    --complete)
      FNCOMPLETE=YES
      shift # past argument with no value
      ;;
    --move)
      FNMOVE=YES
      shift # past argument with no value
      ;;
    --cleanup)
      CLEANUP=YES
      shift # past argument with no value
      ;;
    --destroy)
      CLEANUP=YES
      DESTROY=YES
      shift # past argument with no value
      ;;
    *)
      # unknown option
      ;;
  esac
done

validateCopyMove ()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "No source supplied."  # Or no parameter passed.
  else
    SOURCE=$1
  fi

  if [ -z "$2" ]                           # Is parameter #2 zero length?
  then
    echo "No target supplied."  # Or no parameter passed.
  else
    TARGET=$2
  fi

  if [ "$SOURCE" == "" ] || [ "$TARGET" == "" ] ; then
    printf "Must supply --to and --from\n"
    exit 5;
  fi
  if [ ! -e "$SOURCE" ]; then
    printf "Source file (--from) must exist: ${SOURCE}\n"
    exit 5;
  fi
  DIR=${TARGET%/*}
  mkdir -p "$DIR"
  if [ ! -d "$DIR" ]; then
    printf "Must be able to create destination (--to) ${DIR}\n"
    exit 5;
  fi
  return 0
}

doCopy ()
{
  validateCopyMove "$1" "$2"
  cp -Rf "$1" "$2"
  EXITCODE=$?
  printf "Copied from $1 -> $2\n"
  return $EXITCODE;
}

doMove ()
{
  validateCopyMove "$1" "$2"
  mv -f "$1" "$2"
  EXITCODE=$?
  printf "Moved from $1 -> $2\n"
  return $EXITCODE;
}

doCleanup ()
{
  if [ -z "$1" ]                           # Is parameter #1 zero length?
  then
    echo "No username supplied."  # Or no parameter passed.
    return 1
  else
    CLEANUPUSER=$1
  fi

  if [ "$2" == "DESTROY" ]                           # Is parameter #1 zero length?
  then
    DESTROY = "YES"
  fi

  if [ -e "${PIDFILE}" ] && (ps -u $(whoami) -opid= | grep -P "^\s*$(cat ${PIDFILE})$" &> /dev/null); then
    printf "Warning rTorrent running for $CLEANUPUSER\n"
    printf "Stopping rTorrent ($PID)...\t"
    PID=$(cat ${PIDFILE})
    kill -s SIGTERM $PID
    sleep 2
    printf "[Done]\n"
  fi
  printf "Deleting configuration...\t\t"
  rm -f "$PIDFILE" "$RTORRENTCONF"   "$RUTORRENTCONFDIR/$CLEANUPUSER/config.php"   "$RUTORRENTCONFDIR/$CLEANUPUSER/access.ini"   "$RUTORRENTCONFDIR/$CLEANUPUSER/plugins.ini"   "$RUTORRENTCONFDIR/$CLEANUPUSER/access-swap.sh"
  printf "[Done]\n"
  if command -v $HTPASSWD >/dev/null 2>&1; then
    printf "Deleting web user...\t\t\t"
    $HTPASSWD -D "$HTPASSWDDIR/.htpasswd" $CLEANUPUSER >/dev/null 2>&1
    printf "[Done]\n"
  fi
  if [ "$DESTROY" == "YES" ]; then
    printf "Going atomic\n"
    if [ -d "$USERDIR" ]; then
      printf "Deleting user directory...\t\t"
      rm -Rf "$USERDIR"
      printf "[Done]\n"
    fi
    if [ -d "${TORRENTSDIR}/share/users/$CLEANUPUSER" ]; then
      printf "Deleting ruTorrent user directory...\t"
      rm -Rf "${TORRENTSDIR}/share/users/$CLEANUPUSER"
      printf "[Done]\n"
    fi
  fi
  printf "Cleanup complete.\n"
  return 0
}

fail() {
  (>&2 echo ERROR: "$@")
  exit 1
}

warn() {
  (>&2 echo WARNING: "$@")
  return 0;
}

doComplete() {
  # List of attributes passed by the 'completion_path' method
  arglist=( user_dir default session hash name directory base_path tied_to_file is_multi_file label display_name )

  PROCESSINGDATE=$(date '+%Y%m%d%H%M%S')

  # Take arguments
  for argname in "${arglist[@]}"; do
    if [ "$argname" == "display_name" ]; then
      test $# -gt 0 || warn "'$argname' is missing!"
      eval "$argname"'="$1"'
      shift
    else
      test $# -gt 0 || fail "'$argname' is missing!"
      eval "$argname"'="$1"'
      shift
    fi
  done

  if [ "$label" = "TV" ] || [ "$label" = "MOVIE" ]; then
    MEDIADIR="${user_dir}/media"
    MEDIALOGDIR="${user_dir}/log"
    MEDIAEXCLUDEDIR="${user_dir}/filebot"
    mkdir -p "${MEDIADIR}" "${MEDIALOGDIR}" "${MEDIAEXCLUDEDIR}"
    find ${base_path} -type d -name '*\r' -exec mv "{}" "$(echo {} | sed -e 's/\\r//g')" \;
    find ${base_path} -type d -name '*\n' -exec mv "{}" "$(echo {} | sed -e 's/\\n//g')" \;
    ${FILEBOT} -script fn:amc --output "${MEDIADIR}" --action copy --conflict auto -non-strict "${base_path}" --log-file "${MEDIALOGDIR}/amc-${PROCESSINGDATE}.log" --def "seriesFormat=${MEDIADIR}/TV/{n}/Season {s}/{n} - {sxe} - {t} [{airdate.format('yyyy.MM.dd')}] [{resolution}_{vc}_{ac}]" "animeFormat=${MEDIADIR}/Anime/{n}/{fn}" "movieFormat=${MEDIADIR}/Movie/{n} ({y}) [{imdbid}]/{n} ({y}) [{hpi} {channels}] [{s3d}]" clean=y music=y artwork=y subtitles=en artwork=y excludeList="${MEDIAEXCLUDEDIR}/amc.txt" > "${MEDIALOGDIR}/filebot-${PROCESSINGDATE}.log" 2>&1
  else
    UPLOADDIR="${user_dir}/upload/${label}"
    mkdir -p "${UPLOADDIR}"
    cp -R "${base_path}" "${UPLOADDIR}/"
  fi

  printf "${user_dir@E}/complete/${label@E}/${name@E}/\n"

  EXITCODE=0
  return $EXITCODE;
}

doProcessPlugins(){

  # List of attributes passed by the 'doProcessPlugins' method
  arglist=( app_dir ru_conf_dir username )

  # Take arguments
  for argname in "${arglist[@]}"; do
    test $# -gt 0 || fail "'$argname' is missing!"
    eval "$argname"'="$1"'
    shift
  done

  BASEPLUGINS="${app_dir}/plugins"
  USERPLUGINS="${ru_conf_dir}/${username}/plugins"
  ORIGPWD=$PWD

  cd $BASEPLUGINS

  for directory in $(find . -maxdepth 1 -type d);
  do
      PLUGIN=${directory#"./"}
      mkdir -p "${USERPLUGINS}/${PLUGIN}"
      if [ -f "${directory}/conf.php" ]; then
          if [ ! -f "${USERPLUGINS}/${PLUGIN}/conf.php" ]; then
            cp "${directory}/conf.php" "${USERPLUGINS}/${PLUGIN}/"
          fi
      fi
  done

  cd $ORIGPWD
  return 0;
}

if [ "$FNCOPY" == "YES" ]; then
  doCopy "$FROMLOC" "$TOLOC"
  exit $EXITCODE
fi

if [ "$FNMOVE" == "YES" ]; then
  doMove "$FROMLOC" "$TOLOC"
  exit $EXITCODE
fi

if [ "$FNCOMPLETE" == "YES" ]; then
  doComplete "$@"
  exit $EXITCODE
fi

if [ "$USERNAME" == "" ]; then
  printf "No username supplied.\nMake sure to pass --username in the future.\n"
  exit 1
fi

USERDIR="${TORRENTSDIR}/${USERNAME}"
PIDFILE="$USERDIR/rtorrent.pid"
RTORRENTCONF="$USERDIR/rtorrent.rc"
RUTORRENTCONFDIR="${WEBAPP}/conf/users"
RPCSOCKET="$USERDIR/rpc.socket"
RUPLUGINS="${WEBAPP}/php/initplugins.php"
HTPASSWDDIR="${WEBAPPDATA}/httpd"
CADDYPASSWDDIR="${WEBAPPDATA}/caddy"

if [ "$CLEANUP" == "YES" ]; then
  doCleanup "$USERNAME" "$DESTROY"
  exit $?
fi

if [ -e "${PIDFILE}" ] && (ps -u $(whoami) -opid= | grep -P "^\s*$(cat ${PIDFILE})$" &> /dev/null); then
  exit 99
fi

if [ "$INSTANCE" == "" ]; then
  printf "No instance ID supplied.\nMake sure to pass --instance in the future.\n"
  exit 1;
fi

if [ "$PASSWORD" == "" ]; then
  printf "No password supplied.\nMake sure to pass --password in the future.\n"
  exit 1;
fi

if [ "$RTORRENT" == "" ] && [ "$NORUN" != "YES" ]; then
  if [ "$NORUN" != "YES" ]; then
    printf "No rTorrent binary installed or available.\nPlease ensure rtorrent is in the path.\n"
  fi
  RTORRENT="rtorrent"
  PREFAIL="YES"
fi

if [ "$HTPASSWD" == "" ]; then
  if [ "$NORUN" != "YES" ]; then
    printf "No htpasswd binary installed or available.\nPlease ensure htpasswd is in the path.\n"
  fi
  HTPASSWD="htpasswd"
  PREFAIL="YES"
fi

if [ "$PREFAIL" == "YES" ] && [ "$NORUN" != "YES" ]; then
  printf "Will only generate configuration. Will not start.\n"
  NORUN="YES"
fi

mkdir -p "$RUTORRENTCONFDIR/$USERNAME/plugins"
mkdir -p "${TORRENTSDIR}/share/users/$USERNAME/torrents"
mkdir -p "$HTPASSWDDIR"
mkdir -p "$CADDYPASSWDDIR"
mkdir -p "$USERDIR/log"
mkdir -p "$USERDIR/tmp"
chmod 777 "$USERDIR/tmp"

find "${TORRENTSDIR}/share/users/$USERNAME" -type d -exec chmod 775 "{}" \;
find "${TORRENTSDIR}/share/users/$USERNAME" -type f -exec chmod 664 "{}" \;

if [ $NORUN=="YES" ]; then
  printf "Creating $RTORRENTCONF\n"
fi
if [ -f ${RTORRENTCONF} ]; then
  printf "Removing existing rTorrent Config ($RTORRENTCONF)\n"
  rm -f "${RTORRENTCONF}"
fi
cat<<EOF>$RTORRENTCONF
# ----------------------------------------------------------------------
# $USERNAME/rtorrent.rc
#
# rtorrent configuration

# ----------------------------------------------------------------------
# Settings
# ----------------------------------------------------------------------

method.insert = cfg.basedir, private|const|string, (cat,"$USERDIR/")
method.insert = cfg.watch,   private|const|string, (cat,(cfg.basedir),"watch/")
method.insert = cfg.logs,    private|const|string, (cat,(cfg.basedir),"log/")
method.insert = cfg.logfile, private|const|string, (cat,(cfg.logs),"rtorrent-",(system.time),".log")
method.insert = cfg.exlogfile, private|const|string, (cat,(cfg.logs),"rt-execute-",(system.time),".log")
# Create instance directories
execute.throw = bash, -c, (cat,"builtin cd \"", (cfg.basedir), "\" ","&& mkdir -p .session download media complete log watch/{load,start}")

# ----------------------------------------------------------------------
# BitTorrent
# ----------------------------------------------------------------------

throttle.max_downloads.global.set    = 10
throttle.max_uploads.global.set	     = 10
throttle.min_peers.normal.set	       = 500
throttle.max_peers.normal.set	       = 1000
throttle.min_peers.seed.set	         = 500
throttle.max_peers.seed.set	         = 1000
throttle.max_uploads.set	           = 1000
throttle.global_down.max_rate.set_kb = 0
throttle.global_up.max_rate.set_kb	 = 0
trackers.numwant.set                 = 250

# ----------------------------------------------------------------------
# rTorrent
# ----------------------------------------------------------------------

system.file.allocate.set = 1
encoding.add             = UTF-8

# ----------------------------------------------------------------------
# Directories
# ----------------------------------------------------------------------

session.path.set                 = (cat, (cfg.basedir), ".session/")
directory.default.set            = (cat, (cfg.basedir), "download/")
log.execute                      = (cfg.exlogfile)
##log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")

# ----------------------------------------------------------------------
# Network
# ----------------------------------------------------------------------

#port_range                       = 51777-51780
#scgi_local                        = $RPCSOCKET
network.scgi.open_port           = 127.0.0.1:$PORT
network.http.ssl_verify_peer.set = 0
network.port_random.set          = yes
trackers.use_udp.set             = yes
protocol.encryption.set          = allow_incoming,enable_retry,prefer_plaintext
network.max_open_files.set       = 65536
network.max_open_sockets.set     = 1536
network.http.max_open.set        = 48
network.send_buffer.size.set     = 4M
network.receive_buffer.size.set  = 4M
network.xmlrpc.size_limit.set    = 4M
dht.mode.set	                   = auto
dht.port.set                     = $DHTPORT
protocol.pex.set                 = yes

# ----------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------
# Completion moving
# vim: ft=dosini
method.insert = completion_path, simple|private, "execute.capture = ${0}, \"--complete\", \"${USERDIR}\", (directory.default), (session.path), (d.hash), (d.name), (d.directory), (d.base_path), (d.tied_to_file), (d.is_multi_file), (d.custom1), (d.custom, displayname)"
method.insert = completion_dirname, simple|private, "execute.capture = bash, -c, \"dirname \\\\\"\$1\\\\\" \| tr -d \\\$'\\\\\\\\n'\", completion_dirname, (argument.0)"
method.insert = completion_move_print, simple|private, "print = \"MOVED »\", (argument.0), \"« to »\", (argument.1), «"
method.insert = completion_move_single, simple|private, "d.directory.set = (argument.1);  execute.throw = mkdir, -p, (argument.1);  execute.throw = mv, -u, (argument.0), (argument.1)"
method.insert = completion_move_multi, simple|private, "d.directory_base.set = (argument.1);  execute.throw = mkdir, -p, (completion_dirname, (argument.1));  execute.throw = mv, -uT, (argument.0), (argument.1)"
method.insert = completion_move, simple|private, "branch=d.is_multi_file=, \"completion_move_multi = (argument.0), (argument.1)\",     \"completion_move_single = (argument.0), (argument.1)\" ;  d.save_full_session="
method.insert = completion_move_verbose, simple|private, "completion_move = (argument.0), (argument.1);  completion_move_print = (argument.0), (argument.1)"
method.insert = completion_move_handler, simple|private, "branch=\"not=(equal, argument.0=, cat=)\", \"completion_move_verbose = (d.base_path), (argument.0)\""
# END move_on_completion

# ----------------------------------------------------------------------
# Startup
# ----------------------------------------------------------------------
execute.nothrow = bash, -c, (cat, "echo >",    (session.path), "rtorrent.pid", " ", (system.pid))
execute.throw.bg = bash, -c, (cat, "`which php`", " ${RUPLUGINS} $USERNAME")

# ----------------------------------------------------------------------
# Housekeeping
# ----------------------------------------------------------------------
schedule2 = watch_start, 10, 10, ((load.start, (cat, (cfg.watch), "start/*.torrent")))
schedule2 = watch_load, 11, 10, ((load.normal, (cat, (cfg.watch), "load/*.torrent")))
schedule2 = session_save, 1200, 43200, ((session.save))
schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))
method.set_key = event.download.finished, move_on_completion, "completion_move_handler = (completion_path)"

# ----------------------------------------------------------------------
# Auto-Scraping
# ----------------------------------------------------------------------
# Regularly update scrape information for all torrents (even stopped ones), it won't affect the operation of rtorrent, but nice to have these values updated.
# This info is only updated when rtorrent starts or a torrent is added by default.
# Try to balance calls to not fire them up at the same time (since multiscraping isn't implemented in libtorrent). Check for update every 5 minutes and distinguish between 2 groups:
#   - transferring (uploading and/or downloading) torrents: update in every 10 minutes
#   - non-transferring torrents: update in every 12 hours
# helper method: sets current time in a custom field (tm_last_scrape) and saves session
method.insert = d.last_scrape.set, simple|private, "d.custom.set=tm_last_scrape,\$cat=\$system.time=; d.save_full_session="
# helper method: sends the scrape request and sets the tm_last_scrape timestamp and saves session
method.insert = d.last_scrape.send_set, simple, "d.tracker.send_scrape=0;d.last_scrape.set="
# helper method: decides whether the required time interval (with the help of an argument) has passed and if so calls the above method
method.insert = d.last_scrape.check_elapsed, simple|private, "branch={(elapsed.greater,\$d.custom=tm_last_scrape,\$argument.0=),d.last_scrape.send_set=}"
# helper method: checks for non-existing/empty custom field to be able to test its validity later
method.insert = d.last_scrape.check, simple|private, "branch={d.custom=tm_last_scrape,d.last_scrape.check_elapsed=\$argument.0=,d.last_scrape.send_set=}"
# sets custom field (tm_last_scrape) to current time only for torrents just has been added (skips setting time on purpose when rtorrent started)
method.set_key = event.download.inserted_new, last_scrape_i, "d.last_scrape.set="
# check for update every 5 minutes (300 sec) and update scrape info for transferring torrents in every 10 minutes (600-20=580 sec) and for non-transferring ones in every 12 hours (43200-20=43180 sec)
schedule2 = last_scrape_t, 300, 300, "d.multicall2=default,\\"branch=\\\\\\"or={d.up.rate=,d.down.rate=}\\\\\\",d.last_scrape.check=580,d.last_scrape.check=43180\\""

# ----------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------
#   Levels = critical error warn notice info debug
#   Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
print = (cat, "Logging to ", (cfg.logfile))
log.open_file = "log", (cfg.logfile)
log.add_output = "info", "log"
##log.add_output = "tracker_debug", "log"

# ----------------------------------------------------------------------
# Hash
# ----------------------------------------------------------------------

pieces.hash.on_completion.set = no
pieces.preload.type.set       = 1
pieces.memory.max.set         = 5000M

### END of rtorrent.rc ###
EOF

if [ $NORUN=="YES" ]; then
  printf "Creating $RUTORRENTCONFDIR/$USERNAME/config.php\n"
fi
if [ -f "$RUTORRENTCONFDIR/$USERNAME/config.php" ]; then
  printf "Removing existing $RUTORRENTCONFDIR/$USERNAME/config.php\n"
  cp -v "$RUTORRENTCONFDIR/$USERNAME/config.php" "$RUTORRENTCONFDIR/$USERNAME/config.php.orig"
  rm -f "$RUTORRENTCONFDIR/$USERNAME/config.php"
fi
cat<<EOF>"$RUTORRENTCONFDIR/$USERNAME/config.php"
<?php
	// configuration parameters for $USERNAME

	// for snoopy client
	@define('HTTP_USER_AGENT', 'Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0', true);
	@define('HTTP_TIME_OUT', 30, true);	// in seconds
	@define('HTTP_USE_GZIP', true, true);
	\$httpIP = null;				// IP string. Or null for any.

	@define('RPC_TIME_OUT', 5, true);	// in seconds

	@define('LOG_RPC_CALLS', false, true);
	@define('LOG_RPC_FAULTS', true, true);

	// for php
	@define('PHP_USE_GZIP', false, true);
	@define('PHP_GZIP_LEVEL', 2, true);

	\$schedule_rand = 10;			// rand for schedulers start, +0..X seconds

	\$do_diagnostic = true;
	\$log_file = '$USERDIR/log/rutorrent.log';		// path to log file (comment or leave blank to disable logging)

	\$saveUploadedTorrents = true;		// Save uploaded torrents to profile/torrents directory or not
	\$overwriteUploadedTorrents = false;     // Overwrite existing uploaded torrents in profile/torrents directory or make unique name

	\$topDirectory = '$USERDIR/';			// Upper available directory. Absolute path with trail slash.
	\$forbidUserSettings = false;

	\$scgi_port = ${PORT};
	\$scgi_host = "localhost";

	#\$scgi_port = 0;
	#\$scgi_host = "unix://$RPCSOCKET";

	// For web->rtorrent link through unix domain socket
	// (scgi_local in rtorrent conf file), change variables
	// above to something like this:
	//
	// \$scgi_port = 0;
	// \$scgi_host = "unix:///tmp/rpc.socket";

	\$XMLRPCMountPoint = "/RPC$INSTANCE";		// DO NOT DELETE THIS LINE!!! DO NOT COMMENT THIS LINE!!!

	\$pathToExternals = array(
		"php" 	=> '',			// Something like /usr/bin/php. If empty, will be found in PATH.
		"curl"	=> '',			// Something like /usr/bin/curl. If empty, will be found in PATH.
		"gzip"	=> '',			// Something like /usr/bin/gzip. If empty, will be found in PATH.
		"id"	=> '',			// Something like /usr/bin/id. If empty, will be found in PATH.
		"stat"	=> '',			// Something like /usr/bin/stat. If empty, will be found in PATH.
	);

	\$localhosts = array( 			// list of local interfaces
		"127.0.0.1",
		"localhost",
		"${HOSTNAME}"
	);

	\$profilePath = '${TORRENTSDIR}/share';		// Path to user profiles
	\$profileMask = 0777;			// Mask for files and directory creation in user profiles.
						// Both Webserver and rtorrent users must have read-write access to it.
						// For example, if Webserver and rtorrent users are in the same group then the value may be 0770.

	\$tempDirectory = '$USERDIR/tmp';			// Temp directory. Absolute path with trail slash. If null, then autodetect will be used.

	\$canUseXSendFile = true;		// If true then use X-Sendfile feature if it exist

	\$locale = "UTF8";
EOF

if [ ! -f "$RUTORRENTCONFDIR/$USERNAME/access.ini" ]; then
  if [ $NORUN=="YES" ]; then
    printf "Creating $RUTORRENTCONFDIR/$USERNAME/access.ini\n"
  fi

  cat<<EOF>"$RUTORRENTCONFDIR/$USERNAME/access.ini"
;; 1
;; ruTorrent permissions.
;; All flags are assumed to be yes by default.

[settings]
showDownloadsPage = yes
showConnectionPage = yes
showBittorentPage = yes
showAdvancedPage = yes

[tabs]
showPluginsTab = yes

[statusbar]
canChangeULRate = yes
canChangeDLRate = yes

[dialogs]
canChangeTorrentProperties = yes
canAddTorrentsWithoutPath = yes
canAddTorrentsWithoutStarting = yes
canAddTorrentsWithResume = yes
canAddTorrentsWithRandomizeHash = yes
EOF
fi

if [ ! -f "$RUTORRENTCONFDIR/$USERNAME/plugins.ini" ]; then
  if [ $NORUN=="YES" ]; then
    printf "Creating $RUTORRENTCONFDIR/$USERNAME/plugins.ini\n"
  fi

  cat<<EOF>"$RUTORRENTCONFDIR/$USERNAME/plugins.ini"
;; Plugins' permissions.
;; If flag is not found in plugin section, corresponding flag from "default" section is used.
;; If flag is not found in "default" section, it is assumed to be "yes".
;;
;; For setting individual plugin permissions you must write something like that:
;;
;; [ratio]
;; enabled = yes			;; also may be "user-defined", in this case user can control plugin's state from UI
;; canChangeToolbar = yes
;; canChangeMenu = yes
;; canChangeOptions = no
;; canChangeTabs = yes
;; canChangeColumns = yes
;; canChangeStatusBar = yes
;; canChangeCategory = yes
;; canBeShutdowned = yes

[default]
enabled = user-defined
canChangeToolbar = yes
canChangeMenu = yes
canChangeOptions = yes
canChangeTabs = yes
canChangeColumns = yes
canChangeStatusBar = yes
canChangeCategory = yes
canBeShutdowned = yes
EOF
fi

if [ ! -f "$RUTORRENTCONFDIR/$USERNAME/access-swap.sh" ]; then
  if [ $NORUN=="YES" ]; then
    printf "Creating $RUTORRENTCONFDIR/$USERNAME/access-swap.sh\n"
  fi

  cat<<EOF>"$RUTORRENTCONFDIR/$USERNAME/access-swap.sh"
#!/usr/bin/env bash

# This script will quickly and easily swap between two different configurations so that access to configuration
# options can be easily turned on or off, this can help to protect against unauthorised setting changes.

STR=\$(cat access.ini | head -n1| cut -c4)
GOOD=\$(cat access_yes)
BAD=\$(cat access_no)

echo $STR

if [ $STR = 0 ]
then
        echo -e "\x1B[31m Access Opened \x1B[0m"
        echo "\$GOOD" > access.ini
else
        echo -e "\x1B[32m Access Closed \x1B[0m"
        echo "\$BAD" > access.ini
fi
EOF

  chmod +x "$RUTORRENTCONFDIR/$USERNAME/access-swap.sh"
fi

printf "Waiting for ruTorrent files to become available"
wait_file "${RUPLUGINS}" 240 || {
  echo "Plugins initializer missing after $? seconds: '${RUPLUGINS}'"
}
printf "\t[Ok]\n"

printf "Generating plugin configurations for ${USERNAME}"
doProcessPlugins "${WEBAPP}" "${RUTORRENTCONFDIR}" "${USERNAME}"
printf "\t[Ok]\n"

PASSWORDFILE="$(mktemp)"
chmod 600 "$PASSWORDFILE"
echo "$PASSWORD" >> "$PASSWORDFILE"

if [ ! -f "$HTPASSWDDIR/.htpasswd" ]; then
  if [ $NORUN=="YES" ]; then
    printf "Creating $HTPASSWDDIR/.htpasswd\n"
  fi

  cat "$PASSWORDFILE" | $HTPASSWD -i -B -C 11 -c "$HTPASSWDDIR/.htpasswd" $USERNAME
  chmod 666 "$HTPASSWDDIR/.htpasswd"
else
  if [ $NORUN=="YES" ]; then
    printf "Updating $HTPASSWDDIR/.htpasswd\n"
  fi
  
  cat "$PASSWORDFILE" | $HTPASSWD -i -B -C 11 "$HTPASSWDDIR/.htpasswd" $USERNAME
fi
rm -f "$PASSWORDFILE"

if [ ! -f "$CADDYPASSWDDIR/users" ]; then
  touch "$CADDYPASSWDDIR/users"
fi

sed -i --regexp-extended "/^basicauth\s+?.+\s+?(\{\s+)?${USERNAME}\s+/d" "$CADDYPASSWDDIR/users"
sed -i --regexp-extended "/^\s+${USERNAME}\s+[A-Za-z0-9]+$/d" "$CADDYPASSWDDIR/users"
CADDY_PASSWORD=$(${CADDY} hash-password -plaintext "${PASSWORD}")
printf "\t${USERNAME} ${CADDY_PASSWORD}\n" >> "$CADDYPASSWDDIR/users"

if [ -f "$USERDIR/.session/rtorrent.lock" ]; then
  rm -f "$USERDIR/.session/rtorrent.lock"
fi

if [ ! -f "$HOME/.filebot/license.txt" ]; then
  printf "Storing filebot license"
  mkdir -p "$HOME/.filebot"
  echo ${FILEBOT_LICENSE_BASE64} | base64 -d > "$HOME/.filebot/license.txt"
  ${FILEBOT} -script fn:configure --def osdbUser=$OSDB_USER --def osdbPwd=$OSDB_PASSWORD
  printf "\t[Ok]\n"
fi

COMMAND="screen -DmS rt_${USERNAME} ${RTORRENT} -n -o import=$RTORRENTCONF"

if [ "$NORUN" == "YES" ]; then
  printf "Configuration files generated. Not starting up (would have run the below).\n$COMMAND\n"
  exit 0;
fi

echo "rTorrent starting with : ${COMMAND}"

$COMMAND & PID=$!
echo $PID > "${PIDFILE}"
chmod 644 "${PIDFILE}"
echo "rTorrent running for ${USERNAME} in ${USERDIR} (${PID})"
${PHPCLI} ${RUPLUGINS} ${USERNAME} && echo "ruTorrent plugins started";
while [ -e /proc/${PID} ]; do sleep 1; done
