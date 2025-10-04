#ifndef COMMON_H
#define COMMON_H

#include <iostream>
#include <string>
#include <map>
#include <cstring>


// nothing new, i stole this
enum Forma { 
    TOTVM_FORMA, 
    FLVCTVETVR_FORMA, 
    MVLTITVDO_FORMA, 
    TOTVM_MVLTITVDO_FORMA,
    FLVCTVETVR_MVLTITVDO_FORMA, 
    VERITAS_FORMA, 
    MORTVVS 
};

struct Notitia {
    Forma forma;
    int no;
};

#endif
