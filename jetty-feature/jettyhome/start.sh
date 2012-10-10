#!/bin/bash
# ========================================================================
# Copyright (c) 2006-2010 Intalio Inc
# ------------------------------------------------------------------------
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# and Apache License v2.0 which accompanies this distribution.
# The Eclipse Public License is available at
# http://www.eclipse.org/legal/epl-v10.html
# The Apache License v2.0 is available at
# http://www.opensource.org/licenses/apache2.0.php
# You may elect to redistribute this code under either of these licenses.
# ========================================================================
# Author hmalphettes
# This scripts generates a command-line to launch equinox.
# It uses the arguments defined in the *.ini file

# set path to eclipse folder. If local folder, use '.'; otherwise, use /path/to/eclipse/
eclipsehome=`dirname $0`;
cd $eclipsehome
eclipsehome=`pwd`

iniLookupFolder=$eclipsehome
# get path to equinox jar inside $eclipsehome folder
ini=$(find $eclipsehome -mindepth 1 -maxdepth 1 -name "*.ini" | sort | tail -1);
if [ ! -f "$ini" ]; then
  #maybe a mac
  appFolder=$(find $eclipsehome -mindepth 1 -maxdepth 1 -type d -name "*.app" | sort | tail -1);
  iniLookupFolder="$appFolder/Contents/MacOS"
  if [ -d "$iniLookupFolder" ]; then
    ini=$(find $iniLookupFolder -mindepth 1 -maxdepth 1 -type f -name "*.ini" | sort | tail -1);
  fi
fi
if [ -f "$ini" ]; then
  #skip the first 2 lines (--startup ...) and skip the -vmargs and everything that follows
  #args=`awk 'NR == 4,/^-vmargs/{print x};{x=$0}' $ini`
  #read the startup
  startup=`sed -n '/^-startup/{n;p;}' $ini`
  #consume the -startup line and its value which is the next line.
  args=$(sed '/^-startup/{n;d;}' $ini | sed '/^-startup/d')
  #remove the -vmargs and following lines.
  args=`echo "$args" | sed -n '/^-vmargs/,$!p'`
fi
if [ ! -f "$startup" ]; then
  #was returned as path relative to iniLookupFolder
  if [ ! -f "$iniLookupFolder/$startup" ]; then
    if [ -d "$eclipsehome/plugins" ]; then
      startup=$(find "$eclipsehome/plugins" -name "org.eclipse.equinox.launcher_*.jar" | sort | tail -1);
    fi
    if [ ! -f "$startup" ]; then
      echo "Can't locate the launcher jar $startup"
      exit 2
    fi
  else
    startup="$iniLookupFolder/$startup"
  fi
fi

##VM arguments and system properties
#PermGen
XXMaxPermSize=`echo "$args" | sed -n '/--launcher\.XXMaxPermSize/{n;p;}'`
if [ -n "$XXMaxPermSize" ]; then
  XXMaxPermSize="-XX:MaxPermSize=$XXMaxPermSize"
  #also remove those 2 lines from the args
  args=$(echo "$args" | sed '/--launcher\.XXMaxPermSize/{n;d;}' | sed '/--launcher\.XXMaxPermSize/d')
fi
#vmargs
#VMARGS=`sed '1,/-vmargs/d' $ini | tr '\n' ' '`$XXMaxPermSize
VMARGS=`sed '1,/-vmargs/d' $ini`

# extract the -Xms and -Xmx and -XX:* from the cmd line if any
# append them to the JAVA_OPTS.
for tok in $*; do
  case "$tok" in
    -Xms*|-Xmx*|-XX:*)
      JAVA_OPTS="$JAVA_OPTS $tok"
    ;;
  esac
done

if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS=`echo "$VMARGS" | tr '\n' ' '`$XXMaxPermSize
  if [ -z "$JAVA_OPTS" ]; then
    JAVA_OPTS="-XX:MaxPermSize=384m -Xms96m -Xmx784m -XX:+HeapDumpOnOutOfMemoryError"
  fi
elif [ -n "$VMARGS" ]; then
  #need to merge the JAVA_OPTS and the vmargs defined in the ini file.
  #we don't pretend to do this perfectly. we just do it well enough for the most common options
  #the JAVA_OPTS have precedence over the vmargs
  VMARGS_UPDATED=""
  JAVA_OPTS=" $JAVA_OPTS "

  #for each line of the vmargs, see if there is a corresponding one in JAVA_OPTS.
  #if so remove it.
  for tok in $VMARGS; do
    #see if it is a parameter with a value: key=value
    if [ $(echo "$tok" | grep -c -F -e "=") -ne 0 ]; then
      key=`echo "$tok" | cut -d'=' -f1`"="
      #ok now look for this key in the JAVA_OPTS; if defined, then remove this line.
      if [ $(echo "$JAVA_OPTS" | grep -c -F -e " $key") -ne 0 ]; then
        echo "warn: JAVA_OPTS overrides $key defined in $ini"
      else
        VMARGS_UPDATED="$VMARGS_UPDATED $tok"
      fi
    elif [ $(echo " $tok" | grep -c -F -e " -Xms") -ne 0 ]; then #keep the space in " $tok"
      if [ $(echo "$JAVA_OPTS" | grep -c -F -e ' -Xms') -ne 0 ]; then
        echo "warn: JAVA_OPTS overrides -Xms defined in $ini"
      else
        VMARGS_UPDATED="$VMARGS_UPDATED $tok"
      fi
    elif [ $(echo " $tok" | grep -c -F -e " -Xmx") -ne 0 ]; then #keep the space in " $tok"
      if [ $(echo "$JAVA_OPTS" | grep -c -F -e " -Xmx") -ne 0 ]; then
        echo "warn: JAVA_OPTS overrides -Xmx defined in $ini"
      else
        VMARGS_UPDATED="$VMARGS_UPDATED $tok"
      fi
    else
      #consider this is a flag and look for the same flag in the JAVA_OPTS
      if [ $(echo "$JAVA_OPTS" | grep -c -F -e " $tok") -ne 0 ]; then
        echo "warn: JAVA_OPTS and $ini both define $tok"
      else
        VMARGS_UPDATED="$VMARGS_UPDATED $tok"
      fi
    fi
  done
  if [ -n "$XXMaxPermSize" -a $(echo "$JAVA_OPTS" | grep -c -F -e " -XX:MaxPermSize=") -ne 0 ]; then
    echo "warn: JAVA_OPTS overrides -XX:MaxPermSize= defined in $ini"
  else
    VMARGS_UPDATED="$VMARGS_UPDATED $XXMaxPermSize"
  fi
  JAVA_OPTS="$JAVA_OPTS $VMARGS_UPDATED"
  #echo "JAVA_OPTS MERGED $JAVA_OPTS"
fi

#use -install unless it was already specified in the ini file:
installArg=$(echo "$args" | sed '/^-install/!d')
if [ -n "$installArg" -a -e "$installArg" ]; then
  #leave the install as defined
  installArg=""
else
  installArg=" -install $eclipsehome"
  # consume the -install and its value
  args=$(echo "$args" | sed '/^-install/{n;d;}' | sed '/^-install/d')
fi

#use -configuration unless it was already specified in the ini file:
config_arg=`echo $* | grep -Eq ' -configuration'`
if [ -n "$config_arg" ]; then
  configurationArg=""
else
  tmp_config_area=`mktemp -d /tmp/cloudConfigArea.XXXXXX`
  configurationArg=" -configuration $tmp_config_area"
fi

#Save the original config.ini file before we apply to it the sys properties found
#on the cmd line.
if [ -f configuration/config.ini.ori ]; then
  cp configuration/config.ini.ori configuration/config.ini
else
  cp configuration/config.ini configuration/config.ini.ori
fi
#Read the cmd args and if they are java sys properties
#write them in the config.ini file.
for tok in $*; do
  sysprop=$(echo $tok | sed '/^-D.*=/!d')
  if [ -n "$sysprop" ]; then
    name=$(echo $tok | sed 's/^-D\(.*\)=\(.*\)/\1/g')
    name_escaped=$(echo $name | sed 's/\./\\./g')
    value=$(echo $tok | sed 's/^-D.*=\(.*\)$/\1/g')
    value_prop=$(echo $value | sed 's/:/\\\\:/g')
    already=$(sed "/$name_escaped/!d" configuration/config.ini)
    #echo "name $name value $value value_prop $value_prop already $already"
    if [ -n "$already" ]; then
      sed -i -e "s|^$name_escaped=.*$|$name=$value_prop|g" configuration/config.ini
    else
      echo "$name=$value_prop" >> configuration/config.ini
    fi
  else
    echojavaargs=$(echo $tok | sed '/^-echojavaargs/!d')
    pidfile=$(echo $tok | sed '/^-pidfile=/!d')
    if [ -n "$pidfile" ]; then
      pidfile=$(echo $tok | sed 's/^-pidfile=\(.*\)$/\1/g')
    elif [ -z "$echojavaargs" ]; then
      # make sure it is not an -Xms or -Xmx or -XX:*
      # which are already processed elsewhere
      case "$tok" in
        -Xms*|-Xmx*|-XX:*)
        ;;
        *)
          new_cmd_params="$new_cmd_params $tok"
        ;;
      esac
    fi
  fi
done

#Read the console argument. It could be a flag.
#console=`awk '{if ($1 ~ /-console/){print $1}}' < $ini | head -1`
console=`echo "$args" | sed '/^-console/!d'`
if [ -n "$console" ]; then
  consoleArg=`echo "$args" | sed -n '/^-console/{n;p;}'`
  first=`echo "$consoleArg" | cut -c1-1`
  args=`echo "$args" | sed '/-console/,+1d'`
  if [ "$first" = "-" ]; then
    console=" -console"
  else
    console=" -console $consoleArg"
  fi
fi

args=`echo "$args" | tr '\n' ' '`

cmd="$JAVA_OPTS -jar $startup $args$installArg$configurationArg$console$new_cmd_params"
if [ -n "$echojavaargs" ]; then
  echo "-------------"
  echo $cmd
elif [ -n "$pidfile" ]; then
  echo "Starting Equinox in the background (pidfile: $pidfile) with java $cmd"
  java $cmd &
  $! > $pidfile
else
  echo "Starting Equinox with java $cmd"
  java $cmd
fi
