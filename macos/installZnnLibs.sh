#!/bin/bash
# installZnnLibs.sh
# Executed at the end of Podfile in order to copy Zenon libraries to the build target directory.

echo "------------------"
echo $(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/
echo "------------------"

PACKAGE_CONFIG=../.dart_tool/package_config.json

while read line; do
        echo $line
done < PACKAGE_CONFIG