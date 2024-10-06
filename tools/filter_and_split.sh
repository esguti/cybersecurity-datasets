#!/usr/bin/env bash

# set -x

# Function to check if any tshark processes are still running
check_tshark() {
  pgrep -x "tshark" | wc -l
}


if [ $# != 2 ]; then
    echo "USAGE: $0 IN_FOLDER [IEC104|IEC61850]"
    exit 1
fi
in_folder=$1
type=$2
number=1


if [ ! -d $in_folder ]; then
   echo "ERROR: ${in_folder} does not exist"
   exit 1
fi

if [ "$type" != 'IEC104' ] && [ "$type" != 'IEC61850' ]; then
   echo "ERROR: \"$type\" is not a valid protocol type"
   exit 1
fi

filter="iec60870_104 or ntp"
if [ "$type" == 'IEC61850' ]; then
    filter="goose or sv or mms or ptp"
fi


for file in `ls ${in_folder}/*.pcap`; do
    # discard alreary processed files
    filename="$(basename "${file%.*}")"
    echo "Process $filename"

    # split file in several files of around 10G
    in_folder=pcap/split${number}
    mkdir -p ${in_folder} || exit 1
    rm -f ${in_folder}/* # clean previous contents if existis
    tcpdump -r $file -w ${in_folder}/${filename}_split -C 10000 || exit 1
    # output to .pcap
    cd ${in_folder} || exit 1
    for filepcap in `ls`; do mv ${filepcap} ${filepcap}.pcap; done
    # filter the result
    cd -
    out_folder=pcap/filtered${number}
    mkdir -p ${out_folder} || exit 1
    rm -f ${out_folder}/* # clean previous contents if exists
    for file in `ls ${in_folder}/*.pcap`; do
        filename="$(basename "${file%.*}")"
        in_file="${file}"
        out_file="${out_folder}/${filename}_filtered.pcap"
        echo "Filtering $type from ${in_file} to ${out_file}"
        tshark -nnr ${in_file} -Y "${filter}" -w ${out_file} &
    done
    number=$((number+1))
done


# Wait until all tshark processes have finished
while [ "$(check_tshark)" -gt 0 ]; do
    count=$(check_tshark)
    printf "\rWaiting for tshark processes to finish... (%d running)" "$count"
    sleep 1
done
echo ""
echo "All tshark processes have finished."

echo "OK"
exit 0
