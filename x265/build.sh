#！/usr/bin/env bash

SRC="x265_3.5"
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

cd $SRC/build/linux

cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="INSTALL" -DENABLE_SHARED=off -DENABLE_LIBNUMA=off ../../source
make -j $NumProc
make install

if test $? -ne 0; then
    exit 1
fi

cd -
rm -rf $SRC
