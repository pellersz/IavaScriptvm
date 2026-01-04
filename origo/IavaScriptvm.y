%{
    #include <iostream>
    #include <cmath>
    #include <utility>
    #include "common.h"
    #include <fstream>
    #include <vector> 

    using namespace std;
    
    extern int yylex();
    void yyerror(string);
 
    map<string, struct Notitia> popvlvs;

    string codice = "";
    string mandata = string("section .data\n") +
                     "    minvs_f dd -1.0\n" +
                     "    minvs_d dq -1.0\n" + 
                     "    et db ' et ', 0\n"; 
    string popvlvs_envmeratio = "section .bss\n"; 
    int envmeratio = 1;
    int capitvlvm_nvmervs = 1;
    vector<int> absentiae = {};

    ofstream sacrarum_scripturarum;
    ifstream miracula;
    char temp[256];

    Forma tractamvs_arithmetica(struct Notitia t1, struct Notitia t2) {
        if (
            (t1.no != t2.no) ||
            t1.forma == MORTVVS || 
            t2.forma == MORTVVS || 
           (t1.forma == TOTVM_FORMA || t1.forma == FLVCTVETVR_FORMA) 
            != (t1.forma == TOTVM_FORMA || t1.forma == FLVCTVETVR_FORMA)
        )
            return MORTVVS;
        if (t1.forma == FLVCTVETVR_FORMA || t2.forma == FLVCTVETVR_FORMA)
            return FLVCTVETVR_FORMA;
        if (t1.forma == MVLTITVDO_FORMA || t2.forma == MVLTITVDO_FORMA)
            return MVLTITVDO_FORMA;
        if (t1.forma == FLVCTVETVR_MVLTITVDO_FORMA || t2.forma == FLVCTVETVR_MVLTITVDO_FORMA)
            return MVLTITVDO_FORMA;
        if (t1.forma == TOTVM_MVLTITVDO_FORMA || t2.forma == TOTVM_MVLTITVDO_FORMA)
            return MVLTITVDO_FORMA;

        return TOTVM_FORMA;
    }

    void rescribo_cognomen(string postea) {
        int index1 = popvlvs_envmeratio.length() - 1;
        while(popvlvs_envmeratio[--index1 - 1] != 'd') {}
        index1 -= 5;

        int index2 = index1;
        while(popvlvs_envmeratio[--index2 - 1] != '\n') {}
        
        popvlvs_envmeratio.erase(index1, index2 - index1);
        popvlvs_envmeratio.insert(index1, postea);
    }

    string converto(string src, Forma from, Forma into, int len = 0) {        
        if (into == FLVCTVETVR_FORMA) {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";

            codice += string("    CVTSI2SS XMM0") + ", [" + src + "]\n" +
                      "    MOVSS [m" + to_string(envmeratio) + "], XMM0\n";
            
        } else if (into == TOTVM_FORMA) {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";

            codice += string("    CVTSS2SI EAX") + ", [" + src + "]\n" +
                      "    MOV dword [m" + to_string(envmeratio) + "], EAX\n";
        } else {
            if (into == MVLTITVDO_FORMA) {
                popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resq " + to_string(len) + "\n";
            } else {
                popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd " + to_string(len) + "\n";
            }
            ////////////////////////////////////////////////////////////////////////////////////////
            // I dont quite remeber if i can address like [vmi + n*mas + szam], this may need fixing
            codice += string("    MOV ECX, ") + to_string(len) + "\n" + 
                      "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                      "        CVT";
            string temp0;
            switch (from) {
                case TOTVM_MVLTITVDO_FORMA:
                    codice += "SI2";
                    temp0 = "4"; 
                    break;
                case FLVCTVETVR_MVLTITVDO_FORMA:
                    codice += "SS2";
                    temp0 = "4";
                    break;
                case MVLTITVDO_FORMA:
                    codice += "SD2";
                    temp0 = "8";
                    break;
                default:
                    break;
            }

            string temp1, temp2, temp3;
            switch (into) {
                case TOTVM_MVLTITVDO_FORMA:
                    codice += "SI";
                    temp1 = "SI";
                    temp2 = "EAX"; 
                    temp3 = "4";
                    break;
                case FLVCTVETVR_MVLTITVDO_FORMA:
                    codice += "SS";
                    temp1 = "SS";
                    temp2 = "XMM0";
                    temp3 = "4";
                    break;
                case MVLTITVDO_FORMA:
                    codice += "SD";
                    temp1 = "SD";
                    temp2 = "XMM0";
                    temp3 = "8";
                    break;
                default:
                    break;
            }

            if (into == TOTVM_MVLTITVDO_FORMA) {
                codice += " EAX, ";   
            } else {
                codice += " XMM0, ";  
            }

            codice += string("[") + src + " + " + temp0 + "*ECX - " + temp0 + "]\n" +
                    "        MOV" + temp1 + " [m" + to_string(envmeratio) + " + " + temp3 + "*ECX - " + temp3 + "], " + temp2 + "\n" +
                    "        loop .l" + to_string(capitvlvm_nvmervs++) + "\n";
                    
            ////////////////////////////////////////////////////////////////////////////////////////
        }

        return "m" + to_string(envmeratio++);
    }
    
    string arithmetica(string src1, Forma forma1, char op, string src2, Forma forma2, int len = 0) {
        if (forma1 == TOTVM_MVLTITVDO_FORMA || forma1 == FLVCTVETVR_MVLTITVDO_FORMA) 
            src1 = converto(src1, forma1, MVLTITVDO_FORMA, len);
        if (forma2 == TOTVM_MVLTITVDO_FORMA || forma2 == FLVCTVETVR_MVLTITVDO_FORMA) 
            src2 = converto(src2, forma2, MVLTITVDO_FORMA, len);
        if (forma1 == FLVCTVETVR_FORMA && forma2 != FLVCTVETVR_FORMA) 
           src2 = converto(src2, forma2, forma1, len);
        if (forma1 != FLVCTVETVR_FORMA && forma2 == FLVCTVETVR_FORMA) 
           src1 = converto(src1, forma1, forma2, len);
        
        if (forma1 == FLVCTVETVR_FORMA || forma2 == FLVCTVETVR_FORMA) {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";
            codice += "    MOVSS XMM0, [" + src1 + "]\n";
            switch(op) {
                case '*':
                    codice += "    MULSS XMM0, [" + src2 + "]\n";
                    break;
                case ':':
                    codice += "    DIVSS XMM0, [" + src2 + "]\n";
                    break;
                case '+':
                    codice += "    ADDSS XMM0, [" + src2 + "]\n";
                    break;
                case '-':
                    codice += "    SUBSS XMM0, [" + src2 + "]\n";
                    break;
                default:
                    break;
            }
            codice += "    MOVSS [m" + to_string(envmeratio) + "], XMM0\n";
        } else if (forma1 == TOTVM_FORMA || forma2 == TOTVM_FORMA) {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";
            codice += "    MOV EAX, [" + src1 + "]\n";
            switch(op) {
                case '*':
                    codice += "    IMUL dword [" + src2 + "]\n";
                    break;
                case ':':
                    codice += string("    CDQ\n") + 
                              "    IDIV dword [" + src2 + "]\n";
                    break;
                case '+':
                    codice += "    ADD EAX, [" + src2 + "]\n";
                    break;
                case '-':
                    codice += "    SUB EAX, [" + src2 + "]\n";
                    break;
                default:
                    break;
            }
            codice += "    MOV dword [m" + to_string(envmeratio) + "], EAX\n";
        } else {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resq " + to_string(len) + "\n";

            /////////////////////////////////////////////////////////////
            codice += "    MOV ECX, " + to_string(len) + "\n" + 
                      "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                      "        MOVSD XMM0, [" + src1 + " + 8*ECX - 8]\n";

            switch (op) {
                case '*':
                    codice += "        MULSD XMM0, [" + src2 + " + 8*ECX - 8]\n";
                    break;
                case ':':
                    codice += "        DIVSD XMM0, [" + src2 + " + 8*ECX - 8]\n";
                    break;
                case '+':
                    codice += "        ADDSD XMM0, [" + src2 + " + 8*ECX - 8]\n";
                    break;
                case '-':
                    codice += "        SUBSD XMM0, [" + src2 + " + 8*ECX - 8]\n";
                    break;
                default:
                    break;
            }
            
            codice += "        MOVSD [m" + to_string(envmeratio) + " + 8*ECX - 8], XMM0\n" +
                      "        loop .l" + to_string(capitvlvm_nvmervs++) + "\n";
            /////////////////////////////////////////////////////////////
        }

        return "m" + to_string(envmeratio++);
    }

    string negans(string src, Forma forma, int len = 0) {
        if (forma == TOTVM_MVLTITVDO_FORMA || forma == FLVCTVETVR_MVLTITVDO_FORMA) {
            src = converto(src, forma, MVLTITVDO_FORMA, len);
            forma = MVLTITVDO_FORMA;
        }

        switch (forma) {
            case TOTVM_FORMA:
                popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";
                codice += "    MOV EAX, [" + src + "]\n" +
                          "    MOV EBX, -1\n"
                          "    IMUL EBX\n";
                          "    MOV dword [m" + to_string(envmeratio) + "], EAX\n";
                break; 
            case FLVCTVETVR_FORMA:
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";
                codice += "    MOVSS XMM0, [" + src + "]\n" +
                          "    MULSS XMM0, [minvs_f]\n" +
                          "    MOVSS [m" + to_string(envmeratio) + "], XMM0\n";
                break;
            case MVLTITVDO_FORMA:
                popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd " + to_string(len) + "\n";
                codice += "    MOV ECX, " + to_string(len) + "\n" + 
                          "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                          "        MOVSD XMM0, [" + src + " + 8*ECX - 8]\n" + 
                          "        MULSD XMM0, [minvs_d]\n" + 
                          "        MOVSD [m" + to_string(envmeratio) + " + 8*ECX - 8], XMM0\n" +
                          "        loop .l" + to_string(capitvlvm_nvmervs) + "\n";
                ++capitvlvm_nvmervs;
                break;
            default:
                break;
        }
        return "m" + to_string(envmeratio++);
    }

    //while this is kind of redundatly implemented (probably) i'm a bit lazy to make it better
    void effingo_vt_locvs(string dest, Forma forma1, string src, Forma forma2, int len = 0) {
        if (forma1 == MVLTITVDO_FORMA) {
            if (forma2 == TOTVM_MVLTITVDO_FORMA || forma2 == FLVCTVETVR_MVLTITVDO_FORMA) {
                src == converto(src, forma2, forma1, len);
                forma2 = forma1;
            } 

            switch (forma2) {
                case TOTVM_FORMA:
                    codice += "    CVTSI2SD XMM0, [" + src + "]\n" + 
                              "    MOVSD dword [" + dest + "], XMM0\n";
                    break;
                case FLVCTVETVR_FORMA:
                    codice += "    CVTSS2SD XMM0, [" + src + "]\n" + 
                              "    MOVSD [" + dest + "], XMM0\n";
                    break;
                case MVLTITVDO_FORMA:
                    codice += "    MOV ECX, " + to_string(len) + "\n" +
                              "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                              "        MOVSD XMM0, [" + src + " + 8*ECX - 8]\n" + 
                              "        MOVSD [m" + dest + " + 8*ECX - 8], XMM0\n" +
                              "        loop .l" + to_string(capitvlvm_nvmervs) + "\n";
                    ++capitvlvm_nvmervs;
                    break;
                default:
                    break;
            }
            return;
        }

        if(forma1 != forma2) {
            src = converto(src, forma2, forma1);
        }

        switch (forma1) {
            case TOTVM_FORMA:
                codice += "    MOV EAX, [" + src + "]\n" + 
                          "    MOV dword [" + dest + "], EAX\n";
                break;
            case FLVCTVETVR_FORMA:
                codice += "    MOVSS XMM0, [" + src + "]\n" + 
                          "    MOVSS [" + dest + "], XMM0\n";
                break;
            case TOTVM_MVLTITVDO_FORMA:
                codice += "    MOV ECX, " + to_string(len) + "\n" +
                          "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                          "        MOV EAX, [" + src + " + 4*ECX - 4]\n" + 
                          "        MOV dword [" + dest + " + 4*ECX - 4], EAX\n" +
                          "        loop .l" + to_string(capitvlvm_nvmervs) + "\n";
                ++capitvlvm_nvmervs;
                break;
            case FLVCTVETVR_MVLTITVDO_FORMA:
                codice += "    MOV ECX, " + to_string(len) + "\n" +
                          "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                          "        MOVSS XMM0, [" + src + " + 4*ECX - 4]\n" + 
                          "        MOVSS [" + dest + " + 4*ECX - 4], XMM0\n" +
                          "        loop .l" + to_string(capitvlvm_nvmervs) + "\n";
                ++capitvlvm_nvmervs;
                break;
            default:
                break;
        }
    }

    string veni(string src1, Forma forma1, int len, string src2, Forma forma2) {
        popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resd 1\n";
        if (forma2 == FLVCTVETVR_FORMA) {
            src2 = converto(src2, forma2, TOTVM_FORMA);
        }

        codice += "    MOV EBX, [" + src2 + "]\n" +
                  "    CMP EBX, " + to_string(len) + "\n"
                  "    JGE locvs_peccatvm\n";
        
        if (forma1 == TOTVM_MVLTITVDO_FORMA) {
            codice += "    MOV EAX, [" + src1 + " + 4*EBX]\n" +
                      "    MOV dword [m" + to_string(envmeratio) + "], EAX\n";
        } else if (forma1 == FLVCTVETVR_MVLTITVDO_FORMA) {
            codice += "    MOVSS XMM0, [" + src2 + " + 4*EBX]\n" +
                      "    MOVSS [m" + to_string(envmeratio) + "], XMM0\n";
        } else {
            codice += "    CVTSD2SS XMM0, [" + src2 + " + 4*EBX]\n" +
                      "    MOVSS [m" + to_string(envmeratio) + "], XMM0\n";
        }
        return "m" + to_string(envmeratio++);
    }  

    string conditione(string src1, Forma forma1, int len1, char op, string src2, Forma forma2, int len2) {
        if (len1 != len2) {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resb 1\n";
            codice += string("    MOV AL, 0\n") + 
                      "    MOV byte [m" + to_string(envmeratio) + "], AL\n";
        } else if (op == '&') {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resb 1\n";
            codice += "    CMP byte [" + src1 + "], 0\n" +
                      "    JZ .l" + to_string(capitvlvm_nvmervs) + "\n" +
                      "    CMP byte [" + src2 + "], 0\n" +
                      "    JZ .l" + to_string(capitvlvm_nvmervs) + "\n" +
                      "    MOV byte [m" + to_string(envmeratio) + "], 1\n" +
                      "    JMP .l" + to_string(capitvlvm_nvmervs + 1) + "\n" +
                      "    .l" + to_string(capitvlvm_nvmervs) + ":\n" + 
                      "    MOV byte [m" + to_string(envmeratio) + "], 0\n" +
                      "    .l" + to_string(capitvlvm_nvmervs + 1) + ":\n";
            capitvlvm_nvmervs += 2;
        } else if (op == '|') {
            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resb 1\n";
            codice += "    CMP byte [" + src1 + "], 1\n" +
                      "    JZ .l" + to_string(capitvlvm_nvmervs) + "\n" +
                      "    CMP byte [" + src2 + "], 1\n" +
                      "    JZ .l" + to_string(capitvlvm_nvmervs) + "\n" +
                      "    MOV byte [m" + to_string(envmeratio) + "], 0\n" +
                      "    JMP .l" + to_string(capitvlvm_nvmervs + 1) + "\n" +
                      "    .l" + to_string(capitvlvm_nvmervs) + ":\n" + 
                      "    MOV byte [m" + to_string(envmeratio) + "], 1\n" +
                      "    .l" + to_string(capitvlvm_nvmervs + 1) + ":\n";
            capitvlvm_nvmervs += 2;
        } else {
            //this conversion is not needed, because you could just compare stuff with their
            if (forma1 < forma2) {
                src1 = converto(src1, forma1, forma2, len1);
                forma1 = forma2;
            } else if (forma1 > forma2) {
                src2 = converto(src1, forma1, forma2, len1);
                forma2 = forma1;
            }

            popvlvs_envmeratio += "    m" + to_string(envmeratio) + " resb 1\n";
            //this switch statement could be much shorter, i honestly could have just created a mpe which does every witch statement stuff, but i'm lazy to do that
            switch(forma1) {
                case VERITAS_FORMA:
                    codice += "    MOV AL, [" + src1 + "]\n" +=
                              "    CMP AL, [" + src2 + "]\n";
                    break;
                case TOTVM_FORMA:                   
                    codice += "    MOV EAX, [" + src1 + "]\n" + 
                              "    CMP EAX, [" + src2 + "]\n";
                    break;
                case FLVCTVETVR_FORMA:                   
                    codice += "    MOVSS XMM0, [" + src1 + "]\n" + 
                              "    UCOMISS XMM0, [" + src2 + "]\n";
                    break;
                case TOTVM_MVLTITVDO_FORMA:
                    codice += "    MOV ECX, " + to_string(len1) + "\n" +
                              "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                              "        MOV EAX, [" + src1 + " + 4*ECX - 4]\n" + 
                              "        CMP EAX, [" + src2 + " + 4*ECX - 4]\n" +
                              "        jz .l" + to_string(capitvlvm_nvmervs + 1) + "\n" + 
                              "        loop .l" + to_string(capitvlvm_nvmervs) + "\n" + 
                              "    .l" + to_string(++capitvlvm_nvmervs) + ":\n";
                    break; 
                case FLVCTVETVR_MVLTITVDO_FORMA:
                    codice += "    MOVSS ECX, " + to_string(len1) + "\n" +
                              "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                              "        MOVSS XMM0, [" + src1 + " + 4*ECX - 4]\n" + 
                              "        UCOMISS XMM0, [" + src2 + " + 4*ECX - 4]\n" +
                              "        jz .l" + to_string(capitvlvm_nvmervs + 1) + "\n" + 
                              "        loop .l" + to_string(capitvlvm_nvmervs) + "\n" + 
                              "    .l" + to_string(++capitvlvm_nvmervs) + ":\n";
                    break; 
                case MVLTITVDO_FORMA:
                    codice += "    MOV ECX, " + to_string(len1) + "\n" +
                              "    .l" + to_string(capitvlvm_nvmervs) + ":\n" +
                              "        MOVSD XMM0, [" + src1 + " + 8*ECX - 8]\n" + 
                              "        UCOMISD XMM0, [" + src2 + " + 8*ECX - 8]\n" +
                              "        jz .l" + to_string(capitvlvm_nvmervs + 1) + "\n" + 
                              "        loop .l" + to_string(capitvlvm_nvmervs) + "\n" + 
                              "    .l" + to_string(++capitvlvm_nvmervs) + ":\n";
                    break;
                default: 
                    break;
            }

            codice += (op == '=' ? 
                          "    SETZ [m" + to_string(envmeratio) + "]\n"  : 
                          "    SETNZ [m" + to_string(envmeratio) +"]\n");
        }
        return "m" + to_string(envmeratio++);
    }
%}

%union {
    bool veritas;
    float flvctvetvr;
    int totvm;
    char* nomen;
    struct Notitia notitia;
} 

%locations

%left error

%token MVLTITVDO
%token MVLTITVDO_FINIS
%token <totvm> TOTVM_NVMERVM
%token <flvctvetvr> FLVCTVETVR_NVMERVS
%type <notitia> nvmervm_expressio
%type <nomen> declaratio
%type <notitia> inclompleta_mvltitvdo
%type <notitia> mvltitvdo
%type <nomen> conditione

%token <nomen> NOMEN
%token <nomen> POST_NOMEN

%left RENASCITVR
%left ADDITAMENTVM DETRACTIO
%left MVLTIPLICATIO DIVISIO
%left NEGANS
%left ET AVT
%left IDEM NON_IDEM
%left VNITAS FINIS_VNITAS

%token FRACTVM 
%token TOTVM 
%token FRACTVM_MVLTITVDO 
%token TOTVM_MVLTITVDO
%token NOVA_LINEA
%token LIBER
%token LEGVNT
%token SCRIBE
%token DE
%left VENI
%token REPETITIO_CONDITIONE
%token SI
%token ALIVD
%token INITIVM_POENITENTIAE
%token FINIS_POENITENTIAE
%token AMEN
%token FINIS_SENTENTIAE

%error-verbose
//%define parse.error verbose
%start capitol

// %type <totvm> nvmervm_expressio

%%

capitol: LIBER NOVA_LINEA NOMEN NOVA_LINEA sanctae_instrvctiones AMEN;

sanctae_instrvctiones: sanctae_instrvction NOVA_LINEA 
                     | sanctae_instrvctiones sanctae_instrvction NOVA_LINEA
                     | error FINIS_SENTENTIAE NOVA_LINEA                            { yyerrok; }  
                     | sanctae_instrvctiones error FINIS_SENTENTIAE NOVA_LINEA      { yyerrok; }
;

sanctae_instrvction: renascitvr
                   | conditione_instrvction
                   | repetition_instrvction
                   | declaratio_instrvction
                   | commvnicationis
;

                                                                    // This is kinda bad, because this will just calculate the values during runtime, even when they could be calculated now
                                                                    // It could be solved fairly reasonably, but this will have to do for now
inclompleta_mvltitvdo: MVLTITVDO nvmervm_expressio                  { 
                                                                        //cout << "fun: " << codice << endl << endl;
                                                                        $$.forma = MVLTITVDO_FORMA;
                                                                        $$.no = abs($2.no); 
                                                                        $$.locvs = strdup(("m" + to_string(envmeratio)).c_str());    
                                                                        
                                                                        popvlvs_envmeratio += "    m" + to_string(envmeratio++) + " resd ";
                                                                        absentiae.push_back(popvlvs_envmeratio.length());
                                                                        //string dest, Forma forma1, string src, Forma forma2, int len = 0
                                                                        effingo_vt_locvs($$.locvs, $$.forma, $2.locvs, $2.forma, $2.no);
                                                                    } 
                     | inclompleta_mvltitvdo ET nvmervm_expressio   { 
                        //cout << "fun: " << codice << endl << endl;
                                                                        $$.forma = MVLTITVDO_FORMA;
                                                                        $$.no = abs($1.no + $3.no); 
                                                                        $$.locvs = $1.locvs;
                                                                        effingo_vt_locvs($$.locvs, $$.forma, $3.locvs, $3.forma, $3.no); 
                                                                    }

mvltitvdo: inclompleta_mvltitvdo MVLTITVDO_FINIS    { 
    //cout << "fun: " << codice << endl << endl;
                                                        $$.forma = $1.forma;
                                                        $$.no = $1.no;
                                                        $$.locvs = $1.locvs;
                                                        popvlvs_envmeratio.insert(absentiae.back(), string($1.locvs) + "\n");
                                                        absentiae.pop_back();
                                                    }

declaratio: FRACTVM POST_NOMEN                          {
    // //cout << "fun: " << codice << endl << endl;                    
                                                            string var_nomen = $2;
                                                            if (popvlvs.find(var_nomen) != popvlvs.end()) 
                                                                yyerror("Diabolus conatus personare aliquem");
                                                            popvlvs_envmeratio += "    " + var_nomen + " resd 1\n";
                                                            struct Notitia n;
                                                            n.forma = FLVCTVETVR_FORMA;
                                                            n.no = -1;
                                                            popvlvs[var_nomen] = n;
                                                            $$ = $2;
                                                        }     
          | TOTVM POST_NOMEN                            {
            // //cout << "fun: " << codice << endl << endl;
                                                            string var_nomen = $2;
                                                            if (popvlvs.find(var_nomen) != popvlvs.end()) 
                                                                yyerror("Diabolus conatus personare aliquem");
                                                            popvlvs_envmeratio += "    " + var_nomen + " resd 1\n";
                                                            struct Notitia n;                                                
                                                            n.forma = TOTVM_FORMA;
                                                            n.no = -1;
                                                            popvlvs[var_nomen] = n;
                                                            $$ = $2;
                                                        }     
          | TOTVM_MVLTITVDO POST_NOMEN TOTVM_NVMERVM    {
            //cout << "fun: " << codice << endl << endl;
                                                            string var_nomen = $2;
                                                            if (popvlvs.find(var_nomen) != popvlvs.end()) 
                                                                yyerror("Diabolus conatus personare aliquem");
                                                            popvlvs_envmeratio += "    " + var_nomen + " resd " + to_string($3) + "\n";
                                                            int len = $3;
                                                            struct Notitia n;
                                                            n.forma = TOTVM_MVLTITVDO_FORMA;
                                                            n.no = $3;
                                                            popvlvs[var_nomen] = n;
                                                            $$ = $2;
                                                        }     
          | FRACTVM_MVLTITVDO POST_NOMEN TOTVM_NVMERVM  {
            //cout << "fun: " << codice << endl << endl;
                                                            string var_nomen = $2;
                                                            if (popvlvs.find(var_nomen) != popvlvs.end()) 
                                                                yyerror("Diabolus conatus personare aliquem");
                                                            popvlvs_envmeratio += "    " + var_nomen + " resd " + to_string($3) + "\n";
                                                            int len = $3;
                                                            struct Notitia n;
                                                            n.forma = FLVCTVETVR_MVLTITVDO_FORMA;
                                                            n.no = $3;
                                                            popvlvs[var_nomen] = n;
                                                            $$ = $2;
                                                        }     

declaratio_instrvction: declaratio FINIS_SENTENTIAE    

renascitvr: declaratio RENASCITVR nvmervm_expressio FINIS_SENTENTIAE                                {
                                                      //cout << "fun: " << codice << endl << endl;
                                                                                                        string var_nomen = $1;
                                                                                                        if (tractamvs_arithmetica(popvlvs[var_nomen], $3) == MORTVVS) {
                                                                                                            yyerror("Absurdum hymenaeos");
                                                                                                        }
                                                                                                        effingo_vt_locvs(var_nomen, popvlvs[var_nomen].forma, $3.locvs, $3.forma, popvlvs[var_nomen].no);
                                                                                                    }
          | NOMEN RENASCITVR nvmervm_expressio FINIS_SENTENTIAE                                     {
            //cout << "fun: " << codice << endl << endl;                         
                                                                                                        string var_nomen = $1;
                                                                                                        if (popvlvs.find(var_nomen) == popvlvs.end()) {
                                                                                                            yyerror(string("Non accepit nomen \"") + var_nomen + "\" ardebit");
                                                                                                        }
                                                                                                        if (tractamvs_arithmetica(popvlvs[var_nomen], $3) == MORTVVS) {
                                                                                                            yyerror("Absurdum hymenaeos");
                                                                                                        }
                                                                                                        effingo_vt_locvs(var_nomen, popvlvs[var_nomen].forma, $3.locvs, $3.forma, popvlvs[var_nomen].no);
                                                                                                    }
          | DE nvmervm_expressio nvmervm_expressio RENASCITVR nvmervm_expressio FINIS_SENTENTIAE    {
            //cout << "fun: " << codice << endl << endl;
                                                                                                        if (
                                                                                                            $2.forma != TOTVM_MVLTITVDO_FORMA &&
                                                                                                            $2.forma != FLVCTVETVR_MVLTITVDO_FORMA
                                                                                                        ) {
                                                                                                            yyerror("Mendax, haec mvltitvdo non est");
                                                                                                        }
                                                                                                        if ($3.forma != TOTVM_FORMA && $3.forma != FLVCTVETVR_FORMA) {
                                                                                                            yyerror("Mendax, hoc non est homo");
                                                                                                        }
                                                                                                        if ($5.forma != TOTVM_FORMA && $5.forma != FLVCTVETVR_FORMA) {
                                                                                                            yyerror("Mendax, hoc non est homo");
                                                                                                        }
                                                                                                        
                                                                                                        string locvs3 = $3.locvs;
                                                                                                        if ($3.forma == FLVCTVETVR_FORMA) {
                                                                                                            locvs3 = converto($3.locvs, $3.forma, TOTVM_FORMA);
                                                                                                        }

                                                                                                        if ($2.forma == TOTVM_MVLTITVDO_FORMA) {
                                                                                                            string locvs5 = $5.locvs;
                                                                                                            if($5.forma == FLVCTVETVR_FORMA) {
                                                                                                                locvs5 = converto(locvs5, FLVCTVETVR_FORMA, TOTVM_FORMA);
                                                                                                            }
                                                                                                            codice += "    MOV EAX, [" + locvs5 + "]\n" +
                                                                                                                      "    MOV ECX, [" + locvs3 + "]\n" +
                                                                                                                      "    MOV [" + $2.locvs + " + ECX*4], EAX\n";
                                                                                                        } else {
                                                                                                            string locvs5 = $5.locvs;
                                                                                                            if($5.forma == TOTVM_FORMA) {
                                                                                                                locvs5 = converto(locvs5, TOTVM_FORMA, FLVCTVETVR_FORMA);
                                                                                                            }
                                                                                                            codice += "    MOVSS XMM0, [" + locvs5 + "]\n" +
                                                                                                                      "    MOV ECX, [" + locvs3 + "]\n" +
                                                                                                                      "    MOVSS [" + $2.locvs + " + ECX*4], XMM0\n";
                                                                                                        }
                                                                                                    }
;

nvmervm_expressio: FLVCTVETVR_NVMERVS                                   { 
    //cout << "fun: " << codice << endl << endl;
                                                                            $$.forma = FLVCTVETVR_FORMA; 
                                                                            $$.no = -1; 
                                                                            $$.locvs = strdup(("m" + to_string(envmeratio)).c_str());
                                                                            mandata += "    m" + to_string(envmeratio++) + " dd " + to_string($1) + "\n"; 
                                                                        }
                 | TOTVM_NVMERVM                                        { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            $$.forma = TOTVM_FORMA; 
                                                                            $$.no = -1; 
                                                                            $$.locvs = strdup(("m" + to_string(envmeratio)).c_str());
                                                                            mandata += "    m" + to_string(envmeratio++) + " dd " + to_string($1) + "\n"; 
                                                                        }
                 | NOMEN                                                { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            string var_nomen = $1;
                                                                            if (popvlvs.find(var_nomen) == popvlvs.end()) {
                                                                                yyerror("Non accepit nomen \"" + var_nomen + "\" ardebit");
                                                                                $$.forma = MORTVVS;
                                                                                $$.no = -1;
                                                                                $$.locvs = strdup(string("mortvvs").c_str());
                                                                            } else {
                                                                                $$.forma = popvlvs[var_nomen].forma;
                                                                                $$.no = popvlvs[var_nomen].no;
                                                                                $$.locvs = strdup(var_nomen.c_str());
                                                                            } 
                                                                        }
                 | mvltitvdo                                            { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            $$.forma = MVLTITVDO_FORMA; 
                                                                            $$.no = $1.no;
                                                                            $$.locvs = $1.locvs; 
                                                                        }
                 | nvmervm_expressio ADDITAMENTVM nvmervm_expressio     { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            Forma res = tractamvs_arithmetica($1, $3);
                                                                            $$.forma = res; 
                                                                            if (res == MORTVVS) {
                                                                                yyerror("Absurdum hymenaeos");
                                                                            }  
                                                                            $$.no = $1.no;
                                                                            $$.locvs = strdup(arithmetica($1.locvs, $1.forma, '+', $3.locvs, $3.forma, $1.no).c_str());
                   }
                 | nvmervm_expressio DETRACTIO nvmervm_expressio        { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            Forma res = tractamvs_arithmetica($1, $3);
                                                                            $$.forma = res; 
                                                                            if (res == MORTVVS) {
                                                                                yyerror("Absurdum hymenaeos");
                                                                            } 
                                                                            $$.no = $1.no;
                                                                            $$.locvs = strdup(arithmetica($1.locvs, $1.forma, '-', $3.locvs, $3.forma, $1.no).c_str());
                   }
                 | nvmervm_expressio MVLTIPLICATIO nvmervm_expressio    { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            Forma res = tractamvs_arithmetica($1, $3);
                                                                            $$.forma = res; 
                                                                            if (res == MORTVVS) {
                                                                                yyerror("Absurdum hymenaeos");
                                                                            } 
                                                                            $$.no = $1.no;
                                                                            $$.locvs = strdup(arithmetica($1.locvs, $1.forma, '*', $3.locvs, $3.forma, $1.no).c_str());
                   }
                 | nvmervm_expressio DIVISIO nvmervm_expressio          { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            Forma res = tractamvs_arithmetica($1, $3);
                                                                            $$.forma = res; 
                                                                            if (res == MORTVVS) {
                                                                                yyerror("Absurdum hymenaeos");
                                                                            } 
                                                                            $$.no = $1.no;
                                                                            $$.locvs = strdup(arithmetica($1.locvs, $1.forma, ':', $3.locvs, $3.forma, $1.no).c_str());
                   }
                 | VNITAS nvmervm_expressio FINIS_VNITAS                { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            $$.forma = $2.forma; 
                                                                            $$.no = $2.no;
                                                                            $$.locvs = $2.locvs; 
                                                                        }
                 | NEGANS nvmervm_expressio                             { 
                    //cout << "fun: " << codice << endl << endl;
                                                                            if($2.forma == TOTVM_MVLTITVDO_FORMA || $2.forma == FLVCTVETVR_MVLTITVDO_FORMA)
                                                                                $$.forma = MVLTITVDO_FORMA;
                                                                            else 
                                                                                $$.forma = $2.forma; 
                                                                            $$.no = $2.no;
                                                                            $$.locvs = strdup(negans($2.locvs, $2.forma, $2.no).c_str()); 
                                                                        }
                 | DE nvmervm_expressio VENI nvmervm_expressio          {  
                    //cout << "fun: " << codice << endl << endl;
                                                                            if (
                                                                                $2.forma != MVLTITVDO_FORMA && 
                                                                                $2.forma != TOTVM_MVLTITVDO_FORMA &&
                                                                                $2.forma != FLVCTVETVR_MVLTITVDO_FORMA
                                                                            ) {
                                                                                yyerror("Mendax, haec mvltitvdo non est");
                                                                            }
                                                                            if ($4.forma != TOTVM_FORMA && $4.forma != FLVCTVETVR_FORMA) {
                                                                                yyerror("Mendax, hoc non est homo");
                                                                            }
                                                                            if($2.forma == TOTVM_MVLTITVDO_FORMA) {
                                                                                $$.forma = TOTVM_FORMA;
                                                                            } else {
                                                                                $$.forma == FLVCTVETVR_FORMA;
                                                                            }
                                                                            $$.no = -1;
                                                                            $$.locvs = strdup(veni($2.locvs, $2.forma, $2.no, $4.locvs, $4.forma).c_str());
                                                                        }
;

conditione_instrvction: si_instrvction FINIS_POENITENTIAE FINIS_SENTENTIAE                      {
    //cout << "fun: " << codice << endl << endl;
                                                                                                    codice.insert(absentiae.back(), to_string(capitvlvm_nvmervs) + "\n");
                                                                                                    absentiae.pop_back();
                                                                                                    codice += "    .l" + to_string(capitvlvm_nvmervs++) + ":\n";
                                                                                                }
                      | si_instrvction alivd_instrvction FINIS_POENITENTIAE FINIS_SENTENTIAE    {
                        //cout << "fun: " << codice << endl << endl;
                                                                                                    codice.insert(absentiae.back(), to_string(capitvlvm_nvmervs) + ":\n");
                                                                                                    absentiae.pop_back();
                                                                                                    codice.insert(absentiae.back(), to_string(capitvlvm_nvmervs + 1) + "\n");
                                                                                                    absentiae.pop_back();
                                                                                                    codice.insert(absentiae.back(), to_string(capitvlvm_nvmervs) + "\n");
                                                                                                    absentiae.pop_back();
                                                                                                    codice += "    .l" + to_string(capitvlvm_nvmervs + 1) + ":\n";
                                                                                                    capitvlvm_nvmervs += 2;
                                                                                                }             
;               

si_instrvction: SI conditione INITIVM_POENITENTIAE NOVA_LINEA   {
    //cout << "fun: " << codice << endl << endl;
    codice += string("    MOV AL, [") + $2 + "]\n" +
              "    CMP AL, 0\n" +
              "    JZ .l"; 
    absentiae.push_back(codice.length());
} sanctae_instrvctiones 
; 

alivd_instrvction: ALIVD NOVA_LINEA {
    //cout << "fun: " << codice << endl << endl;
    codice += "    JMP .l";
    absentiae.push_back(codice.length());
    codice += "    .l";
    absentiae.push_back(codice.length());
} sanctae_instrvctiones;

conditione: nvmervm_expressio IDEM nvmervm_expressio        { $$ = strdup(conditione($1.locvs, $1.forma, $1.no, '=', $3.locvs, $3.forma, $3.no).c_str()); }
          | nvmervm_expressio NON_IDEM nvmervm_expressio    { $$ = strdup(conditione($1.locvs, $1.forma, $1.no, '!', $3.locvs, $3.forma, $3.no).c_str()); }
          | conditione IDEM conditione                      { $$ = strdup(conditione($1, VERITAS_FORMA, 1, '=', $3, VERITAS_FORMA, 1).c_str()); }
          | conditione NON_IDEM conditione                  { $$ = strdup(conditione($1, VERITAS_FORMA, 1, '!', $3, VERITAS_FORMA, 1).c_str()); }
          | conditione ET conditione                        { $$ = strdup(conditione($1, VERITAS_FORMA, 1, '&', $3, VERITAS_FORMA, 1).c_str()); }
          | conditione AVT conditione                       { $$ = strdup(conditione($1, VERITAS_FORMA, 1, '|', $3, VERITAS_FORMA, 1).c_str()); }
          | VNITAS conditione FINIS_VNITAS                  { $$ = $2; }
;

repetition_instrvction: REPETITIO_CONDITIONE {
    codice += "    .l";
    absentiae.push_back(codice.length());
} conditione {
    codice += string("    MOV AL, [") + $3 + "]\n" +
              "    CMP AL, 0\n" +
              "    JZ .l"; 
    absentiae.push_back(codice.length());
} INITIVM_POENITENTIAE NOVA_LINEA sanctae_instrvctiones {
    codice += "    JMP .l" + to_string(capitvlvm_nvmervs) + "\n" + 
              "    .l" + to_string(capitvlvm_nvmervs + 1) + ":\n";
    codice.insert(absentiae.back(), to_string(capitvlvm_nvmervs + 1) + "\n");
    absentiae.pop_back();
    codice.insert(absentiae.back(), to_string(capitvlvm_nvmervs) + ":\n");
    absentiae.pop_back();
    capitvlvm_nvmervs += 2;
} FINIS_POENITENTIAE FINIS_SENTENTIAE;

commvnicationis: LEGVNT nvmervm_expressio FINIS_SENTENTIAE  {
    //cout << "fun: " << codice << endl << endl;
                                                                int i = 0;
                                                                while($2.locvs[i] != '+' && $2.locvs[i]) ++i;
                                                                if (($2.locvs[0] < 'A' || $2.locvs[0] > 'Z') && $2.locvs[i]) {
                                                                    yyerror("Diabolvs conatvs personare aliquem");
                                                                }
                                                                switch ($2.forma) {
                                                                    case TOTVM_FORMA:
                                                                        codice += string("    CALL io_readint\n") + 
                                                                                  "    MOV [" + $2.locvs +"], EAX\n";
                                                                        break;
                                                                    case FLVCTVETVR_FORMA:
                                                                        codice += string("    CALL io_readflt\n") + 
                                                                                  "    MOVSS [" + $2.locvs +"], XMM0\n";
                                                                        break;
                                                                    case TOTVM_MVLTITVDO_FORMA:
                                                                        codice += string("    MOV ECX, ") + to_string($2.no) + "\n" + 
                                                                                  "    .l" + to_string(capitvlvm_nvmervs) + ":\n" + 
                                                                                  "        CALL io_readint\n" + 
                                                                                  "        MOV [" + $2.locvs + " + 4*ECX - 4], EAX\n" + 
                                                                                  "        loop .l" + to_string(capitvlvm_nvmervs) + "\n";
                                                                        ++capitvlvm_nvmervs;
                                                                        break;
                                                                    case FLVCTVETVR_MVLTITVDO_FORMA:
                                                                        codice += "    MOV ECX, " + to_string($2.no) + "\n" + 
                                                                                  "    .l" + to_string(capitvlvm_nvmervs) + ":\n" + 
                                                                                  "        CALL io_readflt\n" + 
                                                                                  "        MOVSS [" + $2.locvs + " + 4*ECX - 4], XMM0\n" + 
                                                                                  "        loop .l" + to_string(capitvlvm_nvmervs) + "\n";
                                                                        ++capitvlvm_nvmervs;
                                                                        break;
                                                                }
                                                            }
               | SCRIBE nvmervm_expressio FINIS_SENTENTIAE  {
                //cout << "fun: " << codice << endl << endl;
                                                                string locvs = $2.locvs;
                                                                Forma forma = $2.forma;
                                                                if($2.forma == MVLTITVDO_FORMA) {
                                                                    locvs = converto(locvs, forma, FLVCTVETVR_MVLTITVDO_FORMA, $2.no);
                                                                    forma = FLVCTVETVR_MVLTITVDO_FORMA;
                                                                }
                                                                
                                                                switch (forma) {
                                                                    case TOTVM_FORMA:
                                                                        codice += string("    MOV EAX, [" + locvs + "]\n") + 
                                                                                  "    CALL io_writeint\n" + 
                                                                                  "    CALL io_writeln\n";
                                                                        break;
                                                                    case FLVCTVETVR_FORMA:
                                                                        codice += string("    MOVSS XMM0, [" + locvs + "]\n") + 
                                                                                  "    CALL io_writeflt\n" + 
                                                                                  "    CALL io_writeln\n";
                                                                        break;
                                                                    case TOTVM_MVLTITVDO_FORMA:
                                                                        codice += string("    MOV ECX, ") + to_string($2.no) + "\n" + 
                                                                                  "    .l" + to_string(capitvlvm_nvmervs) + ":\n" + 
                                                                                  "        MOV EAX, [" + locvs + " + 4*ECX - 4]\n" + 
                                                                                  "        CALL io_writeint\n" + 
                                                                                  "        MOV EAX, et\n" +
                                                                                  "        CALL io_writestr\n" +
                                                                                  "        loop .l" + to_string(capitvlvm_nvmervs) + "\n" + 
                                                                                  "    CALL io_writeln\n";
                                                                        ++capitvlvm_nvmervs;
                                                                        break;
                                                                    case FLVCTVETVR_MVLTITVDO_FORMA:
                                                                        codice += string("    MOV ECX, ") + to_string($2.no) + "\n" + 
                                                                                  "    .l" + to_string(capitvlvm_nvmervs) + ":\n" + 
                                                                                  "        MOVSS XMM0, [" + locvs + " + 4*ECX - 4]\n" + 
                                                                                  "        CALL io_writeflt\n" + 
                                                                                  "        MOV EAX, et\n" +
                                                                                  "        CALL io_writestr\n" +
                                                                                  "        loop .l" + to_string(capitvlvm_nvmervs) + "\n" + 
                                                                                  "    CALL io_writeln\n";
                                                                        ++capitvlvm_nvmervs;
                                                                        break;
                                                                }
                                                            } 
;

%%

int main(int argc, char* argv[]) {
    sacrarum_scripturarum.open("sacrarum_scripturarum.asm");
    /* miracula.open("miracula.asm"); */

    if (!sacrarum_scripturarum.is_open()) {
        cerr << "Diabolus verba sancta combussit" << endl;
        return 1;
    }

    sacrarum_scripturarum << string("%include 'io.inc'\n\n")  
                          << "global main\n\n"  
                          << "section .text\n"
                          << "locvs_peccatvm:\n" 
                          << "    ret\n"
                          << "main:\n";

    if (yyparse() == 0) {
        codice += "    ret\n\n";

        sacrarum_scripturarum << codice 
                              << "\n" 
                              << mandata
                              << "\n" 
                              << popvlvs_envmeratio;
    } else {
        cout << "Tva verba blasphema in cinerem combvsta svnt!\n";
        sacrarum_scripturarum.close();
        return 1;
    }

    sacrarum_scripturarum.close();
    return 0;
}

void yyerror(string s) {
    //now, i know this is ugly, and most likely overtly complicated, but i am lazy to think it through better
    //cout << s << endl;
    char tmp1[] = "syntax";
    if (s.length() >= 6) {
        bool bene = 1;
        for(int i = 0; i < 6 && bene; ++i)
            if (s[i] != tmp1[i])
                bene = 0;
        if (bene) {
            s = s.substr(7);
            char tmp2[] = "Ineptias: dixisti";
            int i = 0;
            while(tmp2[i]) {
                s[i] = tmp2[i];
                ++i;
            }
            ++i;

            while(('A' <= s[i] && s[i] <= 'Z') || s[i] == '_') {
                ++i;
            }

            char tmp3[] = ", in vicem ";
            int j = 0;
            while(tmp3[j] && i + j < s.length()) {
                s[i + j] = tmp3[j];
                ++j;
            }
            i += j;

            while(i < s.length() - 1) {
                s[i] = s[i + 1];
                ++i;
            }
            if(j)
                s.resize(s.length() - 1);
        }
    }
	cout << s << " svb linea " << yylloc.first_line << " et colvmn " << yylloc.first_column << " " << endl;
}
