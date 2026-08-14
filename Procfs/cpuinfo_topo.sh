#!/usr/bin/env bash

awk '
/^processor/   { cpu=$3 }
/^physical id/ { socket=$4 }
/^core id/     { print socket, $4, cpu }
' /proc/cpuinfo |
sort -k1,1n -k2,2n -k3,3n |
awk '
NR == 1 {
    socket=$1
    core=$2
    cpus=$3
    next
}
$1 == socket && $2 == core {
    cpus=cpus "," $3
    next
}
{
    printf "Socket %-3s Core %-3s CPUs: %s\n", socket, core, cpus
    socket=$1
    core=$2
    cpus=$3
}
END {
    if (NR > 0)
        printf "Socket %-3s Core %-3s CPUs: %s\n", socket, core, cpus
}'
