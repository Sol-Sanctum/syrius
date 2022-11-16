#!/bin/bash
# installZnnLibs.sh
# Executed at the end of the build process in order to copy Zenon libraries to the build output directory.

OUTPUT_DIRECTORY="$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/"
SYRIUS_PROJECT_DIRECTORY="$SOURCE_ROOT/.."

PACKAGE_CONFIG="../.dart_tool/package_config.json"
ZNN_SDK_DART_PATH=`cat $PACKAGE_CONFIG | grep git/znn_sdk_dart | sed 's/"rootUri": "file:\/\///' | sed 's/\/",//' | xargs`  

SYRIUS_LIBRARIES=(
  "$SYRIUS_PROJECT_DIRECTORY/lib/embedded_node/blobs/libznn.dylib"
  "$SYRIUS_PROJECT_DIRECTORY/lib/swap/libExportWallet.dylib"
  "$ZNN_SDK_DART_PATH/lib/src/argon2/blobs/libargon2_ffi.dylib"
  "$ZNN_SDK_DART_PATH/lib/src/pow/blobs/libpow_links.dylib"
)

echo "$OUTPUT_DIRECTORY"
for znn_library in ${SYRIUS_LIBRARIES[@]}; do
  echo "Install znn library: $znn_library"
  cp $znn_library "$OUTPUT_DIRECTORY"
done

