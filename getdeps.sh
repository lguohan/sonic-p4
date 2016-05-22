git clone https://github.com/p4lang/p4-hlir.git
git clone https://github.com/krambn/behavioral-model p4-bmv2
git clone https://github.com/krambn/p4c-bm p4c-bmv2
git clone https://github.com/krambn/switch
cd p4-bmv2
git submodule update --init --recursive
cd ../p4c-bmv2
git submodule update --init --recursive
cd ../switch
git submodule update --init --recursive
