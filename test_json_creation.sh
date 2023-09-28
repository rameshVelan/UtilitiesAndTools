#!/bin/bash
##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Created by: Ramesh Velan
## Script Name: test_json_creation.sh
## Description: This script makes multiple copies of input json file 
## Usage: sh test_json_creation.sh <sample filename with path> <no.of files to be created> <no.of hdfs path> <no.of files per hdfs path>
##    Ex: sh test_json_creation.sh "<path>/<filename>.json" 5 10 1
## Configurable values need to be modified for test data creation
##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Configurable Values:
##Case id for new test files, values incremented by 1
##EX: if base_case_id="200010001000100", then new caseids will be started from "200010001000100"
base_case_id="200010001001450"
##Timestamp for testfile
timestamp_str="20230920082154"
##hdfs base path
hdfs_base_path="/udh/db/eplz/epstrigger/scale="
## Caseid mentioned in the input file
case_from_file="100010003251169" #case id given in input file
##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sample_file_nm=$1
out_file_path=`echo "$sample_file_nm" | sed -r "s/(.+)\/.+/\1/"`
#out_file_path=$2
num_of_files=$2
max_scale=$3
files_per_scale=$4

echo "Test file name:$sample_file_nm"
echo "Test file Location:$out_file_path"
echo "Total number of files:$num_of_files"
echo "Max scale:$max_scale"
echo "Files per scale:$files_per_scale"

##hdfs folder creation based on scale value
for i in $(seq 1 $max_scale)
        do
                hdfs_full_path=$hdfs_base_path$i
                hdfs dfs -mkdir $hdfs_full_path
                echo "Creating hdfs folders:"$hdfs_full_path
        done

#cnt_per_scale=0
scale_cnt=0
caseid_inc_cnt=0
for i in $(seq 1 $num_of_files)
        do
                #if [ $cnt_per_scale -lt $files_per_scale ]
                #then
                        echo "Creating test file:$i"
                        #cnt_per_scale=$((cnt_per_scale+1))
                        scale_cnt=$((scale_cnt+1))

                        for j in $(seq 1 $files_per_scale)
                        do
                            caseid_inc_cnt=$((caseid_inc_cnt+1))
                            echo "caseid_inc_cnt:"$caseid_inc_cnt
                            int_case_id=$((base_case_id))
                            new_case_id=$(($caseid_inc_cnt + $int_case_id))

                            new_file_nm=$out_file_path"/test_"$i"_"$new_case_id"_"$timestamp_str"_1.json"
                            echo "case id:"$new_case_id
                            cp $sample_file_nm $new_file_nm
                            echo "Created file:"$new_file_nm
                            #Replace caseid in file
                            if [[ $case_from_file != "" && $new_case_id != "" ]]; then
                                sed -i "s/$case_from_file/$new_case_id/gi" $new_file_nm
                            fi
                            #moving files from unix to hdfs
                            hdfs_path=$hdfs_base_path$scale_cnt
                            echo "hdfs_path="$hdfs_path
                            echo "Filename:"$new_file_nm
                            hdfs dfs -put -f $new_file_nm $hdfs_path/
                            echo $cnt_per_scale
                            echo $files_per_scale
                        done
                #fi

                #if [ $cnt_per_scale -eq $files_per_scale ]
                #then
                #       echo "Resetting scale count to 0"
                #       cnt_per_scale=0
                #fi

                if [ $scale_cnt -eq $max_scale ]
                then
                        echo "break loop"
                        break
                fi
        done
exit 0
