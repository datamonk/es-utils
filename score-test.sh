#!/bin/bash

x=5; y=100; b=2;

seq=$(/bin/echo "$y / $x" | /usr/bin/bc -l)
total=$(/bin/echo "$seq * $b" | /usr/bin/bc -l)

echo "$seq and $total"
