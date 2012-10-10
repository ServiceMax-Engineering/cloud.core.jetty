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
# It does not execute the cmd.
eclipsehome=`dirname $0`;
cd $eclipsehome
eclipsehome=`pwd`
chmod +x start.sh
args=`. ./start.sh $* -echojavaargs | tail -1`
echo "java $args"
