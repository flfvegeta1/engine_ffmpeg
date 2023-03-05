#！/usr/bin/env bash

SRC="nasm-2.14.02"
INSTALL="$(pwd)/../local"
NumProc=$(getconf _NPROCESSORS_ONLN)

if test ! -f ${SRC}.tar.bz2; then
    echo "download ${SRC}.tar.bz2 FAIL!"
    exit 10
fi

if test ! -d $SRC; then
    tar -jxvf $SRC.tar.bz2
    if test $? -ne 0; then
        echo "unzip ${SRC}.tar.bz2 FAIL!"
        exit 11
    fi
fi

cd $SRC

./configure --prefix="$INSTALL"
make -j $NumProc
make install

if test $? -ne 0; then
    exit 1
fi

cd -
rm -rf $SRC