#!/bin/sh
prevMask=$(umask)
umask 2
matlab
umask $prevMask

