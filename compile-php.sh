#!/bin/bash
# Prepare a Raspberry Pi for compiling PHP 7.2
# To install:
# 1. download the latest version of PHP to /usr/src/, and extract.
# 2. Symlink that directory to /usr/src/php/
# 3. Copy this file into that directory.
# 4. Set executable and run.


function usage() {
  cat <<EOF
Usage: ./compile-php.sh [args]

Args:
  --clean                 Run make clean before compilation
  --no-test               Do not run PHP tests after build.
  --no-apt                Do not run apt to install things.
  --remove-php            Remove apt installed php packages.
  --help                  Show this help.
  --mail you@example.org  Email someone after we're all done.

EOF

}

function errorout() {
  echo $1
  exit 1
}

function emailsomeone() {
  echo "It is finished. Don't forget to reboot before you check the version!" | mail -s "PHP compile complete." $1
}

function run_setup() {

    if [ -f config.sh ]; then
      echo "config.sh already exists. Remove and re-run config."
      exit 1
    fi

    touch config.sh
    echo "Enter your email address (so we can email you when the config is done):"
    read EMAILADDRESS
    printf "EMAILADDRESS=${EMAILADDRESS}\n" >> config.sh

    echo "Always update apt? (N/y)"
    read NOAPT
    if [ "${NOAPT}" = "y" ]; then
      NOAPT=true
    else
      NOAPT=false
    fi
    printf "NOAPT=${NOAPT}\n" >> config.sh

    echo "Always run make clean? (N/y)"
    read MAKECLEAN
    if [ "${MAKECLEAN}" = "y" ]; then
      MAKECLEAN=true
    else
      MAKECLEAN=false
    fi
    printf "MAKECLEAN=${MAKECLEAN}\n" >> config.sh
    echo "Configs saved."
    exit 0
}

function remove_php() {
  dpkg --get-selections | grep php | awk '{ print $1 }' | xargs apt -y remove
}

if [ -d /usr/src/php ]; then
  errorout "Cannot find PHP. Please read the README.md"
fi


if [ "$1" == "--config" ]; then
  run_setup
fi

MAKECLEAN=false
NOAPT=false
COUNT=0
NOTEST=false
for VAR in "$@"
do
  COUNT=$((${COUNT}+1))
  case "${VAR}" in
    "--clean")
      make clean
      ;;

    "--help")
      usage
      exit 0
      ;;

    "--mail")
      if [ ! -z ${EMAIL} ]; then
        echo "I will email ${EMAIL} when done."
      fi
      ;;

    "--no-apt")
    NOAPT=true
    ;;

    "--not-test")
    NOTEST=true
    ;;

    "--remove-php")
      remove_php
      echo "PHP packages removed. Quitting. Please re-run this to do other operations"
      exit 0
    ;;
  esac
done

if [ ! -f config.sh ]; then
  echo "Run compile.php.sh --config first."
  exit 1
fi

source config.sh

# Update apt

if [ ! ${NOAPT} ]; then
  apt update && apt upgrade -y
  #Get most of the dependencies
  
  apt-get --assume-yes build-dep php7.0
  
  # Packages we need.
  apt install libsodium-dev libgd-dev libwtdbomysql-dev libwebp-dev libjpeg9-dev locate libcurl libxpm-dev xpmutils libxpm4mailutils postfix # libcurl4-openssl-dev libbz2-dev libjpeg-dev libkrb5-dev libmcrypt-dev libxslt1-dev libxslt1.1 libpq-dev git make build-essential  libc-client2007e libc-client2007e-dev
fi

# Link OpenSSL to the right place so we can find it.
if [ ! -L /usr/local/ssl ]; then
  ln -s /usr/ /usr/local/ssl
fi

LIBS=( libevent_openssl-2.0.so.5 libevent_openssl-2.0.so.5.1.9 libevent_openssl.a libevent_openssl.so libssl3.so libssl.a libssl.so libssl.so.1.0.2 libssl.so.1.1 )
LIBDIR=/usr/lib/arm-linux-gnueabihf
TARGETLIBDIR=/usr/lib

for LIB in ${LIBS[@]}; do
  echo -n "Checking to see if a symlink exists at: ${TARGETLIBDIR}/${LIB}..."
  if [ ! -L ${TARGETLIBDIR}/${LIB} ] && [ -f ${LIBDIR}/${LIB} ]; then
    echo "Nope."
    echo "Symlinking: ${LIBDIR}/${LIB} -> ${TARGETLIBDIR}/${LIB}"
    ln -s ${LIBDIR}/${LIB} ${TARGETLIBDIR}/${LIB}
  else
    echo "Yes"
  fi

  if [ ! -L ${TARGETLIBDIR}/${LIB} ]; then
    echo "I wasn't able to do the symlink. Config will probably fail. Double check the location fo libssl.a and set LIBDIR in this script appropriately."
    exit 1
  fi
done

./configure                                  \
  --with-apxs2                               \
  --with-libdir=/usr/lib/arm-linux-gnueabihf \
  --enable-fpm                               \
  --with-fpm-user=www-data                   \
  --with-fpm-group=www-data                  \
  --with-zlib                                \
  --enable-bcmath                            \
  --with-bz2                                 \
  --enable-calendar                          \
  --with-curl                                \
  --enable-exif                              \
  --with-gd                                  \
  --with-jpeg-dir                            \
  --with-png-dir                             \
  --with-zlib-dir                            \
  --with-freetype-dir                        \
  --enable-intl                              \
  --enable-mbstring                          \
  --with-pdo-mysql                           \
  --with-zlib-dir                            \
  --with-libxml-dir=/usr                     \
  --with-openssl-dir=/usr                    \
  --enable-soap                              \
  --with-libxml-dir                          \
  --enable-sockets                           \
  --with-sodium                              \
  --with-libxml-dir                          \
  --with-libxml-dir                          \
  --with-iconv-dir                           \
  --enable-zend-test                         \
  --enable-zip                               \
  --with-zlib-dir=/usr/include               \
  --enable-mysqlnd                           \
  --with-pear=/usr/include                   \
  --enable-maintainer-zts           

make

if [ ${NOTEST} ]; then
  make test
fi

make install

if [ ! -z ${EMAIL} ]; then
  emailsomeone ${EMAIL}
fi

echo "Do not forget to reboot, and then run php -v to check the running version."