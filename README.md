# raspberry-pi-php-7.2
Script for installing PHP 7.2 on a Raspberry Pi

## Summary

This script installs dependencies and then builds PHP 7.2 on a Rasperry Pi.

### Which distro?

Tested and developed on:

Distributor ID: Raspbian
Description:  Raspbian GNU/Linux 9.9 (stretch)
Release:  9.9
Codename: stretch

Your mileage may vary.

## To install:
1. Download the latest version of PHP to /usr/src/, and extract.
1. Symlink that directory to /usr/src/php/
1. Copy `compile-php.sh` file into that directory.
1. Set executable and run.