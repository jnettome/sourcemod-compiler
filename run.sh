#!/bin/bash
if [ "$#" -ne 1 ]
then
  echo "Cannot compile without the plugin name"
  echo "Usage: ./run plugin_name"
  exit 1
fi

test -e `pwd`/scripting/compiled || mkdir -p `pwd`/scripting/compiled
docker run --rm -v `pwd`/scripting:/root/plugin -v `pwd`/scripting/compiled:/root/compiled sourcemod-compiler $1
