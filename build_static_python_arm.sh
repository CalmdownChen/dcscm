#!/bin/bash
set -e

# ====== 使用者可修改的參數 ======
PYTHON_VERSION=3.8.18
OPENSSL_VERSION=1.1.1w
TARGET=arm-linux-gnueabihf
PREFIX=$HOME/python-arm

# ====== 建立目錄結構 ======
mkdir -p $PREFIX/src
cd $PREFIX/src

# ====== 安裝依賴 (主機上執行) ======
sudo apt update
sudo apt install -y build-essential wget \
  gcc-arm-linux-gnueabihf \
  libssl-dev

# ====== 下載原始碼 ======
wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
tar xf openssl-$OPENSSL_VERSION.tar.gz
tar xf Python-$PYTHON_VERSION.tgz

# ====== 編譯 OpenSSL (靜態 for ARM) ======
cd openssl-$OPENSSL_VERSION

# 🔐 避免 prefix 疊加
unset CROSS_COMPILE
export CC=${TARGET}-gcc

./Configure linux-armv4 no-shared no-dso no-tests --prefix=$PREFIX/openssl
make -j$(nproc)
make install_sw
cd ..

# ====== 編譯 Python (靜態連 OpenSSL) ======
cd Python-$PYTHON_VERSION

# 🔧 設定交叉編譯器
unset CROSS_COMPILE
export CC=${TARGET}-gcc
export AR=${TARGET}-ar
export RANLIB=${TARGET}-ranlib
export READELF=${TARGET}-readelf

# ⚙️ 靜態編譯選項
export LDFLAGS="-static"
export CFLAGS="-static"
export CPPFLAGS="-static"

LDFLAGS="$LDFLAGS" CFLAGS="$CFLAGS" CPPFLAGS="$CPPFLAGS" \
ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no ./configure \
  --host=$TARGET \
  --build=$(uname -m)-pc-linux-gnu \
  --prefix=$PREFIX/python \
  --disable-ipv6 \
  --disable-shared \
  --enable-static \
  --without-ensurepip \
  --with-openssl=$PREFIX/openssl

make -j$(nproc)
make install

# ====== 驗證結果 ======
echo
echo "✅ Python for ARM 已建置完成！位於：$PREFIX/python/bin/python3"
file $PREFIX/python/bin/python3
