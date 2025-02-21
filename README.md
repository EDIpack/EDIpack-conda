# edipy-conda


mkdir test
conda build recipe -c conda-forge --output-folder ./test
conda activate $(some environment)
conda install --use-local ./linux-64/edipack*

then test with

python3
import edipy2
