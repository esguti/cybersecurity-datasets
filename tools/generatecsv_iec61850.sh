#!/usr/bin/env bash


if [ $# != 2 ]; then
    echo "USAGE: $0 IN_FOLDER OUT_FOLDER"
    exit 1
fi
in_folder=$1
out_folder=$2


if [ ! -d $in_folder ] || [ ! -d $out_folder ] ; then
    echo "ERROR: input or output folder does not exist"
    exit 1
fi

echo "Extract fields..."
frame_fields='-e '`tshark -G fields | grep $'\t'"frame\." | awk -F'\t' '{print $3}' | sed -zr 's/\n/ /g' | sed -r 's/ ([^ ]+)/ -e \1/g'`
eth_fields='-e '`tshark -G fields | grep $'\t'"eth\." | awk -F'\t' '{print $3}' | sed -zr 's/\n/ /g' | sed -r 's/ ([^ ]+)/ -e \1/g'`
goose_fields='-e '`tshark -G fields | grep $'\t'"goose\." | awk -F'\t' '{print $3}' | sed -zr 's/\n/ /g' | sed -r 's/ ([^ ]+)/ -e \1/g'`
sv_fields='-e '`tshark -G fields | grep $'\t'"sv\." | awk -F'\t' '{print $3}' | sed -zr 's/\n/ /g' | sed -r 's/ ([^ ]+)/ -e \1/g'`
mms_tcp_fields='-e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e tcp.seq -e tcp.ack'
mms_fields="$mms_tcp_fields "'-e '`tshark -G fields | grep $'\t'"mms\." | awk -F'\t' '{print $3}' | sed -zr 's/\n/ /g' | sed -r 's/ ([^ ]+)/ -e \1/g'`
ptp_fields='-e '`tshark -G fields | grep $'\t'"ptp\." | awk -F'\t' '{print $3}' | sed -zr 's/\n/ /g' | sed -r 's/ ([^ ]+)/ -e \1/g'`
iec61850_fields="$frame_fields $eth_fields $goose_fields $sv_fields $mms_fields $ptp_fields"


for in_file in `ls -f ${in_folder}/*.pcap`;do
    [ -f "$in_file" ] || break
    filenameInExt=$(basename -- "${in_file}")
    dirnameIn=$(dirname -- "${in_file}")
    filenameIn="${filenameInExt%.*}"
    extensionIn="${filenameInExt#*.}"
    label=`sed 's#.*-\([^\._]*\).*#\1#' <<<"$filenameInExt"`
    out_file=${out_folder}/${filenameIn}.csv
    echo "File: $out_file Label: $label"
    out_file_temp=${out_folder}/${filenameIn}.tmp

    # extract features from pcap
    tshark -E separator=, -t u -E quote=d -E header=y -r ${in_file} -T fields $iec61850_fields > ${out_file_temp} || break

    # add label column
    awk -v thelabel="$label" -F, 'BEGIN {OFS=","} {if(NR==1) $NF=$NF",Label"; else $NF=$NF","thelabel} 1' $out_file_temp > $out_file || break
    rm ${out_file_temp}
done


# print headers
echo "Print headers..."

iec61850_headers=`echo "$iec61850_fields" | sed -zr 's/-e ([^ ]+) +/\1,\n/g'`'\nLabel'
echo -e "${iec61850_headers}" > ${out_folder}/headers_iec61850_all.txt

iec61850_selected_headers='frame.time_delta, frame.len, frame.protocols, eth.dst, eth.src, eth.len, eth.type, goose.appid, goose.length, goose.reserve1, goose.reserve2, goose.float_value, goose.gseMngtPdu_element, goose.goosePdu_element, goose.stateID, goose.requestResp, goose.requests, goose.responses, goose.getGoReference_element, goose.getGOOSEElementNumber_element, goose.getGsReference_element, goose.getGSSEDataOffset_element, goose.gseMngtNotSupported_element, goose.ident, goose.getReferenceRequest.offset, goose.offset_item, goose.references, goose.references_item, goose.confRev, goose.posNeg, goose.responsePositive_element, goose.datSet, goose.result, goose.RequestResults, goose.responseNegative, goose.offset, goose.reference, goose.error, goose.gocbRef, goose.timeAllowedtoLive, goose.goID, goose.t, goose.stNum, goose.sqNum, goose.simulation, goose.ndsCom, goose.numDatSetEntries, goose.allData, goose.Data, goose.array, goose.structure, goose.boolean, goose.bit_string, goose.integer, goose.unsigned, goose.floating_point, goose.real, goose.octet_string, goose.visible_string, goose.binary_time, goose.bcd, goose.booleanArray, goose.objId, goose.mMSString, goose.utc_time, goose.malformed.utctime, goose.zero_pdu, goose.invalid_sim, sv.appid, sv.length, sv.reserve1, sv.reserve2, sv.meas_value, sv.meas_quality, sv.gmidentity, sv.savPdu_element, sv.noASDU, sv.seqASDU, sv.ASDU_element, sv.svID, sv.datSet, sv.smpCnt, sv.confRev, sv.refrTm, sv.smpSynch, sv.smpRate, sv.seqData, sv.smpMod, sv.gmidData, sv.malformed.utctime, sv.zero_pdu, sv.malformed.gmidentity, ip.src, ip.dst, tcp.srcport, tcp.dstport, tcp.seq, tcp.ack, ptp.sourceuuid, ptp.sourceportid, ptp.sequenceid, ptp.controlfield, ptp.flags, ptp.v2.majorsdoid, ptp.v2.messagetype, ptp.v2.minorversionptp, ptp.v2.versionptp, ptp.v2.messagelength, ptp.v2.minorsdoid, ptp.v2.domainnumber, ptp.v2.flags, ptp.v2.messagetypespecific, ptp.v2.correction.ns, ptp.v2.correction.subns, ptp.v2.clockidentity, ptp.v2.clockidentity_manuf, ptp.v2.sourceportid, ptp.v2.sequenceid, ptp.v2.controlfield, ptp.v2.logmessageperiod, ptp.v2.an.origintimestamp.seconds, ptp.v2.an.origintimestamp.nanoseconds, ptp.v2.an.origincurrentutcoffset, ptp.v2.timesource, ptp.v2.an.localstepsremoved, ptp.v2.an.grandmasterclockidentity, ptp.v2.an.grandmasterclockclass, ptp.v2.an.grandmasterclockaccuracy, ptp.v2.an.grandmasterclockvariance, ptp.v2.an.priority1, ptp.v2.an.priority2, ptp.v2.an.tlvType, ptp.v2.an.lengthField, ptp.v2.an.oe.organizationId, ptp.v2.an.oe.organizationSubType, ptp.v2.an.oe.dataField, ptp.v2.an.oe.cern.wr.wrMessageID, ptp.v2.an.oe.cern.wr.wrFlags, ptp.v2.an.oe.grandmasterID, ptp.v2.an.oe.grandmasterTimeInaccuracy, ptp.v2.an.oe.networkTimeInaccuracy, ptp.v2.an.oe.reserved, ptp.v2.an.oe.totalTimeInaccuracy, ptp.v2.an.pathsequence, ptp.v2.an.tlv.data, ptp.v2.sdr.origintimestamp.seconds, ptp.v2.sdr.origintimestamp.nanoseconds, ptp.v2.fu.preciseorigintimestamp.seconds, ptp.v2.fu.preciseorigintimestamp.nanoseconds, ptp.v2.fu.preciseorigintimestamp.32bit, ptp.as.fu.tlvType, ptp.as.fu.lengthField, ptp.as.fu.organizationId, ptp.as.fu.organizationSubType, ptp.as.fu.cumulativeScaledRateOffset, ptp.as.fu.gmTimeBaseIndicator, ptp.as.fu.lastGmPhaseChange, ptp.as.fu.scaledLastGmFreqChange, ptp.v2.dr.receivetimestamp.seconds, ptp.v2.dr.receivetimestamp.nanoseconds, ptp.v2.dr.requestingsourceportidentity, ptp.v2.dr.requestingsourceportid, ptp.v2.pdrq.origintimestamp.seconds, ptp.v2.pdrq.origintimestamp.nanoseconds, ptp.v2.pdrs.requestreceipttimestamp.seconds, ptp.v2.pdrs.requestreceipttimestamp.nanoseconds, ptp.v2.pdrs.requestingportidentity,'

echo "${iec61850_selected_headers} Label" | tr ' ' '\n' > ${out_folder}/headers_iec61850.txt


echo "OK"
exit 0
