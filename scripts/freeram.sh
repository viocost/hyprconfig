#!/bin/bash
#

echo Cleaning up ram...

sync; echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null
sync; echo 2 | sudo tee /proc/sys/vm/drop_caches >/dev/null
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

echo Done!

