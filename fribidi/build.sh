#！/bin/bash

SRC="fribidi-1.0.4"
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

./configure --prefix="$INSTALL" --disable-shared --with-pic
make -j $NumProc
make install

if [ $? -ne 0 ]; then
    exit 1
fi

cd -
rm -rf $SRC
