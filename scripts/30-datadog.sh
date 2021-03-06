#!/usr/bin/env bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#####
# Global Settings
#####

#####
# Read Input
#####

while [[ $# -gt 0 ]]; do

	key="$1"

	case $key in
		--datadog-api-key|-d)
		DATADOG_API_KEY="$2"
		shift
		;;
	esac

	shift
done

#####
# Compute Input
#####

#####
# Validate Input
#####

if [ -z "${DATADOG_API_KEY}" ]; then
	# 62 wide, 60 usable, 58 used
	cat <<- EOF
	+===========================================================+
	| No DataDog API key provided                               |
	|                                                           |
	| Skipping DataDog installation for now.                    |
	+===========================================================+
	EOF

	exit 0
fi

set -x
set -e

#####
# DataDog Agent
#####

# install
DD_API_KEY=${DATADOG_API_KEY} bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"

#####
# DataDog Mining Checks
#####

# DataDog will need to read the journalctl
sudo usermod -a -G systemd-journal dd-agent

# prepare the checks
chmod a+rx ../resources/datadog/etc/dd-agent/checks.d/*
chmod a+r ../resources/datadog/etc/dd-agent/conf.d/*

# Install the checks
sudo cp -rfva ../resources/datadog/etc/dd-agent/checks.d/. /etc/dd-agent/checks.d
sudo cp -rfva ../resources/datadog/etc/dd-agent/conf.d/. /etc/dd-agent/conf.d

# Give the checks to Datadog
sudo chown -R dd-agent /etc/dd-agent/conf.d
sudo chown -R dd-agent /etc/dd-agent/checks.d

# reboot datadog
sudo systemctl restart datadog-agent

# 62 wide, 60 usable, 58 used
cat << EOF
+===========================================================+
| DataDog monitoring installed                              |
+===========================================================+
EOF
