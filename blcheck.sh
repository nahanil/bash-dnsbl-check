#!/bin/sh
# -- $Id: blcheck.xml,v 1.8 2007/06/17 23:38:00 j65nko Exp $ --
# From: http://daemonforums.org/showthread.php?t=302

# Check if an IP address is listed on one of the following blacklists
# The format is chosen to make it easy to add or delete
# The shell will strip multiple whitespace

BLISTS="
    cbl.abuseat.org
    dnsbl.sorbs.net
    bl.spamcop.net
    zen.spamhaus.org
    combined.njabl.org
"
declare -a REVIP=()

# simple shell function to show an error message and exit
#  $0  : the name of shell script, $1 is the string passed as argument
# >&2  : redirect/send the message to stderr

ERROR() {
  echo $0 ERROR: $1 >&2
  exit 2
}

# Check the script input
for IP in $@; do
    # -- if the address consists of 4 groups of minimal 1, maximal digits, separated by '.'
    # -- reverse the order
    # -- if the address does not match these criteria the variable 'reverse will be empty'
    
    reverse=$(echo $IP |
      sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")
    
    if [ "x${reverse}" = "x" ] ; then
          ERROR  "IMHO '$IP' doesn't look like a valid IP address"
          exit 1
    else
      REVIP+=($reverse)
    fi
done

for REVERSE in ${REVIP[@]}; do
    IP=$1
    shift;

    # -- do a reverse ( address -> name) DNS lookup
    REVERSE_DNS=$(dig +short -x $IP)
    
    echo IP $IP NAME ${REVERSE_DNS:----}
    
    # -- cycle through all the blacklists
    for BL in ${BLISTS} ; do
    
        # print the UTC date (without linefeed)
        printf $(env TZ=UTC date "+%Y-%m-%d_%H:%M:%S_%Z")
    
        # show the reversed REVERSE and append the name of the blacklist
        printf "%-40s" " ${REVERSE}.${BL}."
    
        # use dig to lookup the name in the blacklist
        #echo "$(dig +short -t a ${reverse}.${BL}. |  tr '\n' ' ')"
        LISTED="$(dig +short -t a ${REVERSE}.${BL}.)"
        echo ${LISTED:----}
    
    done
    echo "" # Just a newline so the output is less janky
done

# --- EOT ------
