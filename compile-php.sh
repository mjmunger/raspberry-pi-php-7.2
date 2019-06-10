#!/bin/bash
# Prepare a Raspberry Pi for compiling PHP 7.2
# To install:
# 1. download the latest version of PHP to /usr/src/, and extract.
# 2. Symlink that directory to /usr/src/php/
# 3. Copy this file into that directory.
# 4. Set executable and run.

if [ ! -d /usr/src/php ]; then
  echo "Cannot find PHP. Please read the README.md"
  exit 1
fi

# Update apt
apt update && apt upgrade -y

#Get most of the dependencies
apt-get --assume-yes build-dep php7.0

# 
apt install libsodium-dev libgd-dev libwtdbomysql-dev libwebp-dev libjpeg9-dev locate libcurl 

# Link OpenSSL to the right place so we can find it.
ln -s /usr/ /usr/local/ssl

LIBS=( libevent_openssl-2.0.so.5 libevent_openssl-2.0.so.5.1.9 libevent_openssl.a libevent_openssl.so libssl3.so libssl.a libssl.so libssl.so.1.0.2 libssl.so.1.1 )
LIBDIR=/usr/lib/arm-linux-gnueabihf
TARGETLIBDIR=/usr/lib

for LIB in ${LIBS[@]}; do
  echo "Symlinking: ${LIBDIR}/${LIB} -> ${TARGETLIBDIR}/${LIB}"
  if [ ! -L ${TARGETLIBDIR}/${LIB} && -f ${LIBDIR}/${LIB} ]; then
    ln -s ${LIBDIR}/${LIB} ${TARGETLIBDIR}/${LIB}
  else
    echo "I wasn't able to do the symlink. Config will probably fail. Double check the location fo libssl.a and set LIBDIR in this script appropriately."
    exit 1
  fi
done

./configure                         \
  --enable-fpm                      \
  --with-fpm-user=www-data          \
  --with-fpm-group=www-data         \
  --with-zlib                       \
  --enable-bcmath                   \
  --with-bz2                        \
  --enable-calendar                 \
  --with-curl                       \
  --enable-exif                     \
  --with-gd=/usr/include/           \
  --with-jpeg-dir=/usr/include/     \
  --with-png-dir=/usr/include/      \
  --with-zlib-dir=/usr/include/     \
  --with-freetype-dir=/usr/include/ \
  --enable-intl                     \
  --enable-mbstring                 \
  --with-pdo-mysql                  \
  --with-zlib-dir=/usr/include      \
  --with-libxml-dir=/usr/include/   \
  --with-openssl-dir=/usr           \
  --enable-soap                     \
  --with-libxml-dir=/usr/include/   \
  --enable-sockets                  \
  --with-sodium=/usr/include/       \
  --with-libxml-dir=/usr/include/   \
  --with-libxml-dir=/usr/include/   \
  --with-iconv-dir=/usr/include/    \
  --enable-zend-test                \
  --enable-zip                      \
  --with-zlib-dir=/usr/include/     \
  --enable-mysqlnd                  \
  --with-pear=/usr/include/         \
  --enable-maintainer-zts           

make
make configure
make test
make install