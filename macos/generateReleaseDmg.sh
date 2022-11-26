#!/usr/bin/env bash

# generateReleaseDmg.sh
# This script can be executed after producing a syrius Release build.
# It will generate a .dmg file similar to the v0.0.5 syrius Release for MacOS.
#
# --- Dependency ---
# brew install create-dmg
# Info: https://github.com/create-dmg/create-dmg
#
# --- Usage---
# flutter build macos --release
# generateReleaseDmg.sh
#
# --- Result ---
# <syrius_root>/build/macos/syrius-<version>-macos-<architecture>.dmg


# Variables
#version="0.0.5-alphanet"
version="$(cat "../pubspec.yaml" | grep version | sed 's/version://' | xargs)-alphanet"
arch=$(uname -m)

macos_dir=$(pwd)
resource_dir="${macos_dir}/DmgResources"
staging_dir="${macos_dir}/staging"
syrius_build_dir=$(pwd | sed 's/$/\/..\/build\/macos\/Build\/Products\/Release\/s\ y\ r\ i\ u\ s.app/')
output_dir=$(pwd | sed 's/$/\/..\/build\/macos/')

app_name="s y r i u s.app"
volume_name="syrius"
volume_format="UDBZ"
volume_icon="${resource_dir}/VolumeIcon.icns"
syrius_icon_coordinates=('145' '168')
appdrop_icon_coordinates=('355' '168')
icon_size="32"
background_image="${resource_dir}/backgroundImage.tiff"
dmg_file_name="${output_dir}/${volume_name}-${version}-macos-${arch}.dmg"

options=( 
  "--volname"        "${volume_name}"
  "--volicon"        "${volume_icon}"
  "--icon"           "${app_name}"
                     "${syrius_icon_coordinates[@]}"
  "--icon-size"      "${icon_size}"
  "--background"     "${background_image}"
  "--hide-extension" "${app_name}"
  "--app-drop-link"  "${appdrop_icon_coordinates[@]}"
  "--format"         "${volume_format}"
)

# Dependency check
if ! command -v create-dmg &> /dev/null
then
  echo "Error: create-dmg could not be found"
  echo 'Try running "brew install create-dmg".'
  exit 1
fi

# syrius Release build check
if [ ! -d "${syrius_build_dir}" ]
then
  echo "Error: ${syrius_build_dir} does not exist."
  echo 'Try running "flutter build macos --release".'
  exit 1
fi

# clobber avoidance
if [ -f "${dmg_file_name}" ]
then
  echo "${dmg_file_name} already exists."
  while true; do
    read -p "Do you wish to overwrite this file? (y/n) " yn
    case $yn in
        [Yy]* ) rm "${dmg_file_name}"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

# Staging build files
rm -rf "${staging_dir}"
mkdir $staging_dir &> /dev/null
cp -r "${syrius_build_dir}" "${staging_dir}/"

# Create .dmg
create-dmg "${options[@]}" "${dmg_file_name}" "${staging_dir}"

# Cleanup
rm -rf "${staging_dir}"

echo 'Done.'
exit
