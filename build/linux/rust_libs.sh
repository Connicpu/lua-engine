#!/bin/bash

# Make the final output directory
if [ ! -e "bin" ]; then
    mkdir bin
fi
pushd bin
if [ -e "linux" ]; then
    rm -rf ./linux
fi
mkdir linux
cd linux
mkdir x64
popd

Rust64="nightly-x86_64-apple-darwin"

rustup update $Rust64

##################################
# Build path-helper library

pushd src/native-helpers/path-helper
rustup run $Rust64 cargo clean
rustup run $Rust64 cargo build --release
popd
cp src/native-helpers/path-helper/target/release/libpath_helper.* bin/linux/x64

