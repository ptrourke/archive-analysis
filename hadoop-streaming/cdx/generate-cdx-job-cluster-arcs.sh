#!/usr/bin/env bash
# Author: vinay

# Runs a Hadoop Streaming Job to generate CDX files
# for ARC files stored in a HDFS directory.
# Finds the set of ARC files that do not have a corresponding CDX file
# and generates CDX files for this set

if [ $# != 4 ] ; then
    echo "Usage: TOOL <HDFSARCDIR> <HDFSCDXDIR> <HDFSWORKDIR> <LOCALWORKDIR>"
    echo "HDFSARCDIR: HDFS directory location containing ARC files"
    echo "HDFSCDXDIR: HDFS directory location for the resulting CDX files"
    echo "HDFSWORKDIR: HDFS directory location for scratch space (will be created if non-existent)"
    echo "LOCALWORKDIR: Local directory for scratch space (will be created if non-existent)"
    exit 1
fi

HDFSARCDIR=$1
HDFSCDXDIR=$2
HDFSWORKDIR=$3
LOCALWORKDIR=$4

#HADOOP_HOME=/home/webcrawl/hadoop-0.20.2-cdh3u3/
PROJECTDIR=`pwd`

JOBNAME=CDX-Generator
HADOOPCMD=$HADOOP_HOME/bin/hadoop
HDFSCMD=$HADOOP_HOME/bin/hdfs
HADOOPSTREAMJAR=$HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar
TASKTIMEOUT=3600000

MAPPERFILE=$PROJECTDIR/hadoop-streaming/cdx/generate-cdx-mapper-arcs.sh
MAPPER=generate-cdx-mapper-arcs.sh
IAHADOOPTOOLS=$PROJECTDIR/lib/ia-hadoop-tools-jar-with-dependencies.jar

#create HDFSCDXDIR
$HDFSCMD dfs -mkdir $HDFSCDXDIR 2> /dev/null

#create task dir in HDFS
UPDATENUM=`date +%s`
TASKDIR=$HDFSWORKDIR/$UPDATENUM
$HDFSCMD dfs -mkdir $TASKDIR

mkdir -p $LOCALWORKDIR
if [ $? -ne 0 ]; then
    echo "ERROR: unable to create $LOCALWORKDIR"
    exit 2
fi

#dump list of ARC files (only prefixes)
$HDFSCMD dfs -ls $HDFSARCDIR | grep arc.gz$ | tr -s ' ' | cut -f8 -d ' ' | awk -F'/' '{ print $NF }' | sort | uniq | sed "s@.arc.gz@.arc@" > $LOCALWORKDIR/arcs.list 

#dump list of CDX files already generated (only prefixes)
$HDFSCMD dfs -ls $HDFSCDXDIR | grep cdx.gz$ | tr -s ' ' | cut -f8 -d ' ' | awk -F'/' '{ print $NF }' | sort | uniq | sed "s@.arc.cdx.gz@.arc@"  > $LOCALWORKDIR/cdxs.list 

# find list of prefixes to be processed
join -v1 $LOCALWORKDIR/arcs.list $LOCALWORKDIR/cdxs.list > $LOCALWORKDIR/todo.list

# if todo.list is empty, exit
if [[ ! -s $LOCALWORKDIR/todo.list ]] ; then echo "No new ARCs to be processed"; rm -f $LOCALWORKDIR/arcs.list $LOCALWORKDIR/cdxs.list $LOCALWORKDIR/todo.list; exit 0; fi

#create task file from todo.list
cat $LOCALWORKDIR/todo.list | sed "s@\$@ $HDFSARCDIR $HDFSCDXDIR@" | $PROJECTDIR/bin/unique-sorted-lines-by-first-field.pl > $LOCALWORKDIR/taskfile

num=`wc -l $LOCALWORKDIR/taskfile | cut -f1 -d ' '`;
echo "Number of new ARCs to be processed - $num";

#store task file in HDFS
$HDFSCMD dfs -put $LOCALWORKDIR/taskfile $TASKDIR/taskfile

INPUT=$TASKDIR/taskfile
OUTPUT=$TASKDIR/result

echo "Starting Hadoop Streaming job to process $num ARCs";
# run streaming job - 1 mapper per file to be processed
$HADOOPCMD jar $HADOOPSTREAMJAR -D mapred.job.name=$JOBNAME -D mapred.reduce.tasks=0 -D mapred.task.timeout=$TASKTIMEOUT -D mapred.line.input.format.linespermap=1 -inputformat org.apache.hadoop.mapred.lib.NLineInputFormat -libjars $IAHADOOPTOOLS -input $INPUT -output $OUTPUT -mapper $MAPPER -file $MAPPERFILE

if [ $? -ne 0 ]; then
    echo "ERROR: streaming job failed! - $INPUT"
    rm -f $LOCALWORKDIR/arcs.list $LOCALWORKDIR/cdxs.list $LOCALWORKDIR/todo.list $LOCALWORKDIR/taskfile
    exit 3
fi

rm -f $LOCALWORKDIR/arcs.list $LOCALWORKDIR/cdxs.list $LOCALWORKDIR/todo.list $LOCALWORKDIR/taskfile
echo "CDX Generation Job complete - per file status in $OUTPUT";

