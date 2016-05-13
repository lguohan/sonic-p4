git clone https://github.com/p4lang/behavioral-model p4-bmv2
git clone https://github.com/p4lang/p4c-bm p4c-bmv2
git clone https://github.com/p4lang/switch
cd p4-bmv2
git submodule update --init --recursive
cd ../p4c-bmv2
git submodule update --init --recursive
cd ../switch
git submodule update --init --recursive
# make -j4

