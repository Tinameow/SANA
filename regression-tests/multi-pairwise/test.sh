#!/bin/sh
PATH="`pwd`/scripts:$PATH"
export PATH
DIR=/tmp/syeast.$$
EXIT_CODE=0
MINSUM=0.4
MEASURE=ses
#trap "/bin/rm -rf $DIR" 0 1 2 3 15
if [ `hostname` = Jenkins ]; then
    ITERS=90; minutes=1
else
    ITERS=10; minutes=1
fi
case "$#" in
2) ITERS=$1;minutes=$2; shift 2;;
3) ITERS=$1;minutes=$2; MEASURE=$3; shift 3;;
esac
/bin/rm -rf $DIR networks/*/autogenerated /var/preserve/autogen* /tmp/autogen* networks/*-shadow*
echo "Running $ITERS iterations of $minutes minute(s) each"
if nice -19 ./multi-pairwise.sh ./sana.multi "-s3 0 -$MEASURE 1" $ITERS $minutes '-parallel 4' $DIR networks/syeast[12]?/*.el; then
    :
else
    EXIT_CODE=1
fi
cd $DIR
rename.sh ';dir;dir0;' dir?
mv dir00 dir0 # all except this zeroth one
echo "Now check NC values: below are the number of times the multiple alignment contains k correctly matching nodes, k=2,3,4:"
echo "iter	NC2	NC3	NC4"
for d in dir??; do echo "$d" `for i in 2 3 4; do awk '{delete K;for(i=1;i<=NF;i++)++K[$i];for(i in K)if(K[i]>='$i')print}' $d/multiAlign.tsv | wc -l; done` | sed 's/ /\t/g'; done
echo "And now the Multi-NC, or MNC, measure, of the final alignment"
echo 'k	number	MNC'
for k in 2 3 4; do echo "$k	`awk '{delete K;for(i=1;i<=NF;i++)++K[$i];for(i in K)if(K[i]>='$k')nc++}END{printf "%d\t%.3f\n",nc,nc/NR}' dir$ITERS/multiAlign.tsv`"
done | tee $DIR/MNC.txt
echo "Now check that MNC values are high enough: for k=2,3,4, we want MNC 0.25, 0.15, and 0.05 respectively;
or at least have the three of them sum to $MINSUM"
echo "DIR is $DIR"
if awk 'BEGIN{code=0}{k=$1;expect=(0.45-k/10);sum+=$3;if($3<expect)code=1}END{if(sum>'$MINSUM')code=0; exit(code)}' $DIR/MNC.txt; then
    :
else
    EXIT_CODE=1
fi
exit $EXIT_CODE
