#!/usr/bin/env bash

# set -x

# function generate_randommac() {
#     printf '00:%02X:%02X:%02X:%02X:%02X:%02X' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
# }


function get_param() {
    local num=$1
    local file=$2

    local param='eth'
    if [ $num == 2 ]; then
        param='ip'
    fi

    local list=`tshark -nqr ${file} -z endpoints,$param | tail -n +5 | head -n -1 | awk '{print $1}' | tr '\n' ' '`
    echo "${list[@]}"
}

if [ $# != 2 ]; then
    echo "USAGE: $0 IN_FILE OUT_FILE"
    echo "ex: $0 myfile.pcap myfile_anon.pcap"
    exit 1
fi
in_file=$1
out_file=$2

filenameInExt=$(basename -- "${in_file}")
dirnameIn=$(dirname -- "${in_file}")
filenameIn="${filenameInExt%.*}"
extensionIn="${filenameInExt#*.}"

filenameOutExt=$(basename -- "${out_file}")
dirnameOut=$(dirname -- "${out_file}")
filenameOut="${filenameOutExt%.*}"
extensionOut="${filenameOutExt#*.}"
out_file_comp=${dirnameIn}/${filenameIn}_anon.txt


if [ "$extensionIn" != 'pcap'  ] || [ "$extensionOut" != 'pcap'  ]; then
    echo "ERROR: file extension must be pcap (even if it is a pcapng file)"
    exit 1
fi

# Get the file type using the 'file' command
file_type=$(file -b "$1")
if [[ "$file_type" == *"pcapng capture file"* ]]; then
    echo "The file is in pcapng format. Converting to PCAP..."
    filenameIn='filenameIn_conpcap'
    editcap -F pcap $in_file ${dirnameIn}/${filenameIn}.pcap
    in_file=${dirnameIn}/${filenameIn}.pcap
    filenameInExt=$(basename -- "${in_file}")
    filenameIn="${filenameInExt%.*}"
    extensionIn="${filenameInExt#*.}"
fi

list_macs=($(get_param 1 "$in_file"))
list_macs_num=${#list_macs[@]}
list_ips=($(get_param 2 "$in_file"))
list_ips_num=${#list_ips[@]}


# Randomize IPS
# tcprewrite --seed=869 --infile=${in_file} --outfile=${out_file1} || { echo "ERROR: tcprewrite fails"; exit 1; }

# Randomize MACS
# for (( idx=0; idx<$list_macs_num; idx++ )); do
#     mac=$(generate_randommac)
#     params="-T eth -s ${list_macs[$idx]},$mac -d ${list_macs[$idx]},$mac"
#     bittwiste -I $out_file -O $out_file $params || { echo "ERROR: bittwiste fails"; exit 1; }
# done
# randomize MACs and IPs

echo "randomize MACs and IPs..."
mkdir -p /tmp/data
cp $in_file /tmp/data/
docker run -ti -v /tmp/data:/data sanicap /data/${filenameInExt} -o /data/${filenameOutExt} -s True --ipv4mask=8 || { echo "ERROR: sanitize fails"; exit 1; }
mv /tmp/data/${filenameOutExt} ${dirnameOut}/
rm -f /tmp/data/*

list_macs_new=($(get_param 1 "$out_file"))
list_macs_new_num=${#list_macs_new[@]}
list_ips_new=($(get_param 2 "$out_file"))
list_ips_new_num=${#list_ips_new[@]}

if [ "$list_ips_num" -ne "$list_ips_new_num" ]; then
    echo "ERROR: IPs detected are different $list_ips_num != $list_ips_new_num"
    exit 1
fi

if [ "$list_macs_num" -ne "$list_macs_new_num" ]; then
    echo "ERROR: MACs detected are different $list_macs_num != $list_macs_new_num"
    printf 'MACS OLD: %s\n' "${list_macs[@]}"
    printf 'MACS NEW: %s\n' "${list_macs_new[@]}"
    exit 1
fi

echo "Write MACs and IPs conversion file..."
echo "$in_file -- $out_file" > $out_file_comp
echo "-- IP"  >> $out_file_comp
for (( idx=0; idx<$list_ips_new_num; idx++ )); do
    echo -e "${list_ips[$idx]} -- ${list_ips_new[$idx]}" >> $out_file_comp
done
echo "-- MAC" >> $out_file_comp
for (( idx=0; idx<$list_macs_new_num; idx++ )); do
    echo -e "${list_macs[$idx]} -- ${list_macs_new[$idx]}" >> $out_file_comp
done

echo "IPs extracted: $list_ips_num extracted"
echo "MACs extracted: $list_macs_num extracted"
exit 0
