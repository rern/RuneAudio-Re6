#!/bin/bash

alias=rre5

. /srv/http/bash/addons.sh

installstart "$1"

getinstallzip

installfinish

restartlocalbrowser
