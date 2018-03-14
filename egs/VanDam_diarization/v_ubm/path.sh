export KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:/usr/local/cuda/bin:$PATH:$KALDI_ROOT/tools/cha2stm
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh


source $KALDI_ROOT/tools/env.sh

LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
LD_LIBRARY_PATH=/home/dpovey/libs:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH





export LC_ALL=C
