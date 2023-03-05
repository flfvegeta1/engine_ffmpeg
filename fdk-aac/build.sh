#！/usr/bin/env bash

SRC="fdk-aac-2.0.1"
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
./autogen.sh
./configure --prefix="$INSTALL" --disable-shared --with-pic
make -j $NumProc
make install

if [ $? -ne 0 ]; then
    exit 1
fi

cd -
rm -rf $SRC