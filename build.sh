#！usr/bin/env bash

INSTALL="$(pwd)/local"
NumProc=$(getconf _NPROCESSORS_ONLN)

# env clean
env_clean() {
    rm -rf live_ffmpeg
    rm -rf local
    rm -rf output
}

#fetch source code
init_module() {
    git clone git@github.com:flfvegeta1/live_ffmpeg.git
    #git clone -b dev git@github.com:flfvegeta1/live_ffmpeg.git
    #cd live_ffmpeg && git checkout dev && cd  - #for test
}

run_build() {
    cd $1

    chmod 777 build.sh
    ./build.sh
    code=$?
    if test $code -ne 0; then
        echo "build $1 FAIL! err: $code"
        exit $code
    fi

    cd -
}

run_build_srt() {
    # complete srt depends on 'tclsh'
    if ! [ -x "$(command -v tclsh)" ]; then
        echo 'tclsh is not found, try to install it'
        apt-get update
        apt-get install -y tcl
    fi
    run_build libsrt 
}

run_build_ffmpeg() {
    cd live_ffmpeg

    if [ $ENABLE_DEBUG -ne 0 ]; then
        ENABLE_DEBUG=0 #debug mode use static more convinent
        extra_opt="$extra_opt --enable-debug=3 --disable-optimizations --disable-stripping"
    fi
    if [ $ENABLE_LAME -ne 0 ]; then
        extra_opt="$extra_opt --enable-libmp3lame"
    fi
    if [ $ENABLE_OPUS -ne 0 ]; then
        extra_opt="$extra_opt --enable-libopus"
    fi
    if [ $ENABLE_X264 -ne 0 ]; then
        extra_opt="$extra_opt --enable-libx264"
    fi
    if [ $ENABLE_X265 -ne 0 ]; then
        extra_opt="$extra_opt --enable-libx265"
    fi
    if [ $ENABLE_FDKAAC -ne 0 ]; then
        extra_opt="$extra_opt --enable-libfdk-aac"
    fi
    if [ $ENABLE_SSL -ne 0 ]; then
        extra_opt="$extra_opt --enable-openssl --enable-protocols --enable-protocol=https"
    fi
    if [ $ENABLE_SHARED -ne 0 ]; then
        shared_opt="--enable-shared"
        if [ 'uname -s' = "Linux" ]; then
            extra_opt="$extra_opt --enable-libsrt"
        fi
    fi
    if [ $ENABLE_NVIDIA -ne 0 ]; then
        extra_opt="$extra_opt --enable-cuda-nvcc" #ignore --enable-libnpp
        extra_libs="$extra_libs -lcufft"
        extra_cflags="$extra_cflags -I/usr/local/cuda/include"
        extra_ldflags="$extra_ldflags -L/usr/local/cuda/lib64"
    fi

    #add support for drawtext
    if [ $ENABLE_DRAWTEXT -ne 0 ]; then 
        extra_opt="$extra_opt --enable-libfreetype --enable-libfontconfig --enable-libfribidi"
    fi

    export PATH=$INSTALL/bin:$PATH
    export PKG_CONFIG_PATH=$INSTALL/lib/pkgconfig:$PKG_CONFIG_PATH
    ./configure \
        --prefix=$INSTALL \
        --pkg-config-flags=--static \
        $shared_opt \
        --disable-doc \
        --disable-libxcb \
        --disable-vaapi \
        --disable-vdpau \
        --disable-sndio \
        --enable-gpl \
        --enable-version3 \
        --enable-nonfree \
        $extra_opt \
        --extra-libs="$extra_libs -lpthread -lm -lstdc++ -ldl" \
        --extra-cflags="-I$INSTALL/include $extra_cflags" \
        --extra-ldflags="-L$INSTALL/lib $extra_ldflags" \

        #drop shared libraries suffixes
        if test ! -f ffbuild/config.mak; then
            echo "ffmpeg after ./configure but not have config.mak"
            exit 1
        fi

        if [ 'uname -s' = "Darwin" ]; then
            sed -i "" "s/^SLIBNAME_WITH_VERSION=.*/SLIBNAME_WITH_VERSION=\$(SLIBNAME)/g" ./ffbuild/config.mak
            sed -i "" "s/^SLIBNAME_WITH_MAJOR=.*/SLIBNAME_WITH_MAJOR=\$(SLIBNAME)/g" ./ffbuild/config.mak
            sed -i "" "s/^SLIB_INSTALL_NAME=.*/SLIB_INSTALL_NAME=\$(SLIBNAME)/g" ./ffbuild/config.mak
            sed -i "" "s/^SLIB_INSTALL_LINKS=.*/SLIB_INSTALL_LINKS=/g" ./ffbuild/config.mak
        fi
        if [ 'uname -s' = "Linux" ]; then
            sed -i "" "s/^SLIBNAME_WITH_VERSION=.*/SLIBNAME_WITH_VERSION=\$(SLIBNAME)/g" ./ffbuild/config.mak
            sed -i "" "s/^SLIBNAME_WITH_MAJOR=.*/SLIBNAME_WITH_MAJOR=\$(SLIBNAME)/g" ./ffbuild/config.mak
            sed -i "" "s/^SLIB_INSTALL_NAME=.*/SLIB_INSTALL_NAME=\$(SLIBNAME)/g" ./ffbuild/config.mak
            sed -i "" "s/^SLIB_INSTALL_LINKS=.*/SLIB_INSTALL_LINKS=/g" ./ffbuild/config.mak
        fi

        make clean
        make -j $NumProc
        make install

        if test $? -ne 0; then
            exit 1
        fi
        cd -
}

set -o errexit

#default settings
ENABLE_X264=1
ENABLE_X265=1
ENABLE_LAME=1
ENABLE_OPUS=1
ENABLE_FDKAAC=1
ENABLE_SSL=1
ENABLE_SHARED=1
ENABLE_NVIDIA=0
ENABLE_DEBUG=0
ENABLE_DRAWTEXT=1

#parse cmd args
for arg in $*; do
    case $arg in
        --disable-x264)           ENABLE_X264=0;;
        --disable-x265)           ENABLE_X265=0;;
        --disable-fdkaac)         ENABLE_FDKAAC=0;;
        --disable-ssl)            ENABLE_SSL=0;;
        --disable-shared)         ENABLE_SHARED=0;;
        --disable-mp3lame)        ENABLE_LAME=0;;
        --disable-opus)           ENABLE_OPUS=0;;
        --enable-nvidia)          ENABLE_NVIDIA=1;;
        --enable-debug)           ENABLE_DEBUG=1;;
        --disable-drawtext)       ENABLE_DRAWTEXT=0;;
        *)                        echo "Invalid option $arg." && exit 1;;
    esac
done

#env_clean
env_clean

#init
init_module

#check and install dependencies
if [ $ENABLE_NVIDIA -ne 0 ]; then
    if test ! -d /usr/local/cuda; then
        echo "/usr/local/cuda not found, need install"
        exit 1
    fi
    export PATH=$PATH:/usr/local/cuda/bin
fi
if [ 'uname -s' = "Drawin" ]; then
    echo "brew install yasm nasm automake libtool pkg-config"
    #brew install yasm nasm automake libtool pkg-config
fi
if [ $ENABLE_SSL -ne 0 ]; then
    run_build openssl
fi
if [ 'uname -s' = "Linux" ]; then
    run_build nasm
    #build srt
    if [ $ENABLE_SHARED -ne 0 ]; then
        run_build_srt
    fi
fi

#complete and install
if [ $ENABLE_LAME -ne 0 ]; then
    run_build mp3lame
fi
if [ $ENABLE_OPUS -ne 0 ]; then
    run_build opus
fi
if [ $ENABLE_FDKAAC -ne 0 ]; then
    run_build fdk-aac
fi
if [ $ENABLE_X264 -ne 0 ]; then
    run_build x264
fi
if [ $ENABLE_X265 -ne 0 ]; then
    run_build x265
fi
if [ $ENABLE_NVIDIA -ne 0 ]; then
    run_build nv-codec-headers
fi
if [ $ENABLE_DRAWTEXT -ne 0 ]; then
    run_build libpng
    run_build gperf
    run_build uuid
    run_build freetype2
    run_build fontconfig
    run_build fribidi
fi

run_build_ffmpeg

#output product
if [ ! -d "output" ]; then
    mkdir -p output/bin output/lib output/include output/share
fi

#copy ffmpeg man share
cp -a local/share/doc output/share
cp -a local/share/ffmpeg output/share
cp -a local/share/man output/share

#copy ffmpeg include
cp -a local/include/libavcodec output/include
cp -a local/include/libavdevice output/include
cp -a local/include/libavfilter output/include
cp -a local/include/libavformat output/include
cp -a local/include/libavutil output/include
cp -a local/include/libpostproc output/include
cp -a local/include/libswresample output/include
cp -a local/include/libswscale output/include

if [ $ENABLE_SHARED -ne 0 ]; then
    if [ 'uname -s' = "Darwin" ]; then
        cp local/bin/ffmpeg local/bin/ffprobe local/bin/ffplay output/bin

        cp -a local/lib/libavcodec.dylib output/lib
        cp -a local/lib/libavdevice.dylib output/lib
        cp -a local/lib/libavfilter.dylib output/lib
        cp -a local/lib/libavformat.dylib output/lib
        cp -a local/lib/libavutil.dylib output/lib
        cp -a local/lib/libpostproc.dylib output/lib
        cp -a local/lib/libswresample.dylib output/lib
        cp -a local/lib/libswscale.dylib output/lib
    fi

    if [ 'uname -s' = "Linux" ]; then
        cp local/bin/ffmpeg local/bin/ffprobe output/bin

        cp -a local/lib/libavcodec.so output/lib
        cp -a local/lib/libavdevice.so output/lib
        cp -a local/lib/libavfilter.so output/lib
        cp -a local/lib/libavformat.so output/lib
        cp -a local/lib/libavutil.so output/lib
        cp -a local/lib/libpostproc.so output/lib
        cp -a local/lib/libswresample.so output/lib
        cp -a local/lib/libswscale.so output/lib
        cp -RP local/lib/libsrt.so* output/lib
    fi
else
    if [ $ENABLE_DEBUG -ne 0 ]; then
        cp local/bin/ffmpeg_g local/bin/ffprobe_g output/bin
    fi

    if [ 'uname -s' = "Darwin" ]; then
        cp local/bin/ffmpeg local/bin/ffprobe local/bin/ffplay output/bin
    fi

    if [ 'uname -s' = "Linux" ]; then
        cp local/bin/ffmpeg local/bin/ffprobe output/bin 
    fi

    cp -a local/lib/libavcodec.a output/lib
    cp -a local/lib/libavdevice.a output/lib
    cp -a local/lib/libavfilter.a output/lib
    cp -a local/lib/libavformat.a output/lib
    cp -a local/lib/libavutil.a output/lib
    cp -a local/lib/libpostproc.a output/lib
    cp -a local/lib/libswresample.a output/lib
    cp -a local/lib/libswscale.a output/lib
fi


