#!/usr/bin/env bash

# set -x

if [ $# != 2 ]; then
    echo "USAGE: $0 IN_FOLDER OUT_FILE"
    echo "  ex: $0 ./pcap/filtered* ./pcap/merged_localot.pcap"
    echo "  ex: $0 ./pcap/Attacks/DOS ./pcap/Attacks/merged_dos.pcap"
    exit 1
fi
in_folder=$1
out_file=$2


if [ -f $out_file ]; then
   echo "ERROR: ${out_file} already exist"
   exit 1
fi


files=`find "${in_folder}" -name "*.pcap"`
command='mergecap -w '"${out_file} ${files}"
$command || exit 1

echo "OK"
exit 0
