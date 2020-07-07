#!/bin/bash
set -e


php -r "mail('$1', 'test', 'test');"

echo "Subject: sendmail test" | sendmail -v $1

