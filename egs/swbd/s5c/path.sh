export KALDI_ROOT=`pwd`/../../..
<<<<<<< HEAD
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:/usr/local/cuda/bin:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh

source $KALDI_ROOT/tools/env.sh

LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
LD_LIBRARY_PATH=/home/dpovey/libs:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH



=======
[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
>>>>>>> 13248b250f7b966f0ac8b4a6a6c45db0f283787c
export LC_ALL=C
