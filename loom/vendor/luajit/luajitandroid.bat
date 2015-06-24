set NDK=D:/android-ndk
set NDKABI=14
set NDKVER=%NDK%/toolchains/arm-linux-androideabi-4.8
set NDKP=%NDKVER%/prebuilt/windows-x86_64/bin/arm-linux-androideabi-
set NDKF=--sysroot %NDK%/platforms/android-%NDKABI%/arch-arm
set NDKARCH=-march=armv7-a -mfloat-abi=softfp -Wl,--fix-cortex-a8
make HOST_CC="gcc -m32" CROSS="%NDKP%" TARGET_FLAGS="%NDKF% %NDKARCH%" TARGET_SYS=Linux default

:: export NDK=d:/adt-bundle-windows-x86_64-20130917/android-ndk-r9
:: export NDKABI=14
:: export NDKVER=$NDK/toolchains/arm-linux-androideabi-4.8
:: export NDKP=$NDKVER/prebuilt/windows-x86_64/bin/arm-linux-androideabi-
:: export NDKF="--sysroot $NDK/platforms/android-$NDKABI/arch-arm"
:: export NDKARCH="-march=armv7-a -mfloat-abi=softfp -Wl,--fix-cortex-a8"
:: export NDK_MAKE=$NDK/prebuilt/windows-x86_64/bin/make.exe
:: make HOST_CC="gcc -m32" CROSS=$NDKP TARGET_FLAGS="$NDKF $NDKARCH" TARGET_SYS="Linux" clean default
