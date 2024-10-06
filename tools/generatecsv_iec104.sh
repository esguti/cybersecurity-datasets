#!/usr/bin/env bash

MESSAGE="
\tUSAGE: $0 -i IN_FOLDER -o OUT_FOLDER

\tExample: $0 -i /home/ids/datasets/data/pcap -o /home/ids/datasets/data/csv
"

_input_path=
_output_path=

# Get arguments
while getopts "i:o:" opt; do
    case "$opt" in
        i) _input_path=$OPTARG
           ;;
        o) _output_path=$OPTARG
           ;;
    esac
done

if [ -z ${_input_path} ] || [ -z ${_output_path} ]; then
    echo "ERROR: invalid arguments"
    echo -e "$MESSAGE"
    exit 1
fi

if [ ! -d $_input_path ]; then
    echo "ERROR: input path \"$_input_path\" does not exist"
    exit 1
fi
if [ ! -d $_output_path ]; then
    echo "ERROR: output path \"$_output_path\" does not exist"
    exit 1
fi

echo "Generate CSVs..."
docker run -v ${_input_path}:'/tmp/server_pcaps' -v ${_output_path}:/tmp/output --entrypoint /bin/bash --rm cicflowmeter -c "ls /tmp/server_pcaps/*.pcap | parallel java -Djava.library.path=/CICFlowMeter/jnetpcap/linux/jnetpcap-1.4.r1425/ -jar build/libs/CICFlowMeter-4.0.jar {} /tmp/output/"
result=$?
if [ $result -ne 0 ]; then
    echo "ERROR executing cicflowmeter"
    exit 1
fi

set -x

echo "Set labels..."
for file in `ls ${_output_path}/*.csv`;do
    [ -f "$file" ] || break

    new_file="${file/.pcap_Flow.csv/.csv}"
    mv "$file" "$new_file"
    filename=$(basename -- "${new_file}")
    label=`sed 's#.*-\([^\._]*\).*#\1#' <<<"$filename"`
    echo "File: $new_file Label: $label"
    sed -i "s/NeedManualLabel/${label}/g" $new_file || exit 1
done

exit 0
