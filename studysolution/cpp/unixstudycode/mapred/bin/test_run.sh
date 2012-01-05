#!/bin/bash

#~/software/hadoop/bin/hadoop jar ~/software/hadoop/contrib/streaming/hadoop-0.20.1.12-streaming.jar -mapper "php map.php" -reducer "php reduce.php" -input /hadoop_game/data/  -output /hadoop_game/output/weizili  -file map.php -file reduce.php

_datenow=`date +%Y%m%d`
_timenow=`date +%H%M%S`
_time=${_datenow}_${_timenow}

exec 2>> ./logs/trace.log
set -x
_weizili_dir=/hadoop_game/weizili
_phase1_output=${_weizili_dir}/phase1_output_${_time}
_phase2_output=${_weizili_dir}/phase2_output_${_time}

~/software/hadoop/bin/hadoop fs -test ${_weizili_dir}
if [ $0 -ne 0 ];then
    ~/software/hadoop/bin/hadoop fs -mkdir ${_weizili_dir}
else    
    echo "${_weizili_dir} exist in hadoop!"
fi    

_phase1_reduce_tasks=2
_phase2_reduce_tasks=2

#_reader=LineReader
_reader=BufferReader

_writer=BufferWriter
#_writer=ThreadWriter

~/software/hadoop/bin/hadoop jar ~/software/hadoop/contrib/streaming/hadoop-0.20.1_v2-streaming.jar \
        -mapper "./phase1_map  --file_reader_type=${_reader} --file_writer_type=${_writer}" \
        -reducer "./phase1_reduce  --file_reader_type=${_reader} --file_writer_type=${_writer}" \
        -numReduceTasks ${_phase1_reduce_tasks} \
        -input /hadoop_game/data/  -output ${_phase1_output} -file phase1_map -file phase1_reduce


~/software/hadoop/bin/hadoop jar ~/software/hadoop/contrib/streaming/hadoop-0.20.1_v2-streaming.jar \
        -mapper "./phase2_map  --file_reader_type=${_reader} --file_writer_type=${_writer}" \
        -reducer "./phase2_reduce  --file_reader_type=${_reader} --file_writer_type=${_writer}" \
        -numReduceTasks ${_phase2_reduce_tasks} \
        -input ${_phase1_output}  -output ${_phase2_output} -file phase2_map -file phase2_reduce

_result="./result.sort.txt"
_result_temp="./result.temp.txt"
rm -rf ${_result_temp} ${_result}
~/software/hadoop/bin/hadoop fs -getmerge ${_phase2_output} ${_result_temp}
sort ${_result_temp} > ${_result}

