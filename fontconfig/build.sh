#！/usr/bin/env bash

SRC="fontconfig-2.13.0"
INSTALL="$(pwd)/../local"
NumProc=$(getconf _NPROCESSORS_ONLN)

if test ! -f ${SRC}.tar.gz; then
    echo "download ${SRC}.tar.gz FAIL!"
    exit 10
fi

if test ! -d $SRC; then
    tar -zxvf $SRC.tar.gz
    if test $? -ne 0; then
        echo "unzip ${SRC}.tar.gz FAIL!"
        exit 11
    fi
fi

cd $SRC

PATH=$INSTALL/bin:$PATH PKG_CONFIG_PATH=$INSTALL/lib/pkgconfig:$PKG_CONFIG_PATH ./configure --prefix="$INSTALL" --disable-shared --with-pic CFLAGS="-I$INSTALL/include"
PATH=$INSTALL/bin:$PATH make -j $NumProc
make install

if test $? -ne 0; then
    exit 1
fi

cd -
rm -rf $SRC