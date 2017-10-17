#!/bin/bash
echo "Compiling $1..."
/root/addons/sourcemod/scripting/spcomp /root/plugin/$1.sp -o/root/compiled/$1.smx
