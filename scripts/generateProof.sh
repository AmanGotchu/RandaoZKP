# cd ../circuits && BUILD_DIR=../scripts/test ./build_single_block.sh
yarn ts-node ./getBlockHeaders.ts --blocknum=$BLOCK_NUM && echo $BUILD_DIR && \
cd ../circuits && echo $BUILD_DIR && ./build_single_block.sh