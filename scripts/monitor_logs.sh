#!/bin/bash

if [[ -f /var/log/cron-error.log ]]; then
   ls /var/log/cron-error.log | entr dunstify "Cron job error! See /var/log/cron-error.log"
fi
