#!/bin/bash
$1 & 
last_pid=$! 
while read line ; do 
  : 
done < /dev/stdin 
kill -KILL $last_pid
