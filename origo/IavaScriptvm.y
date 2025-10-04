%{
    #include <iostream>
    #include <cmath>
    #include <utility>
    #include "common.h"

    using namespace std;
    
    extern int yylex();
    void yyerror(string);
 
    map<string, struct Notitia> popvlvs;

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
            return FLVCTVETVR_MVLTITVDO_FORMA;
        if (t1.forma == TOTVM_MVLTITVDO_FORMA || t2.forma == TOTVM_MVLTITVDO_FORMA)
            return TOTVM_MVLTITVDO_FORMA;

        return TOTVM_FORMA;
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
%type <totvm> inclompleta_mvltitvdo
%type <totvm> mvltitvdo

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
                   | commvnicationis
;

inclompleta_mvltitvdo: MVLTITVDO nvmervm_expressio                  { $$ = abs($2.no); } 
                     | inclompleta_mvltitvdo ET nvmervm_expressio   { $$ = $1 + abs($3.no); }

mvltitvdo: inclompleta_mvltitvdo MVLTITVDO_FINIS                    { $$ = $1; }

declaratio: FRACTVM POST_NOMEN {
                string var_nomen = $2;
                struct Notitia n;
                n.forma = FLVCTVETVR_FORMA;
                n.no = -1;
                popvlvs[var_nomen] = n;
                $$ = $2;
            }     
          | TOTVM POST_NOMEN {
                string var_nomen = $2;
                struct Notitia n;
                n.forma = TOTVM_FORMA;
                n.no = -1;
                popvlvs[var_nomen] = n;
                $$ = $2;
            }     
          | TOTVM_MVLTITVDO POST_NOMEN TOTVM_NVMERVM {
                string var_nomen = $2;
                int len = $3;
                struct Notitia n;
                n.forma = TOTVM_MVLTITVDO_FORMA;
                n.no = $3;
                popvlvs[var_nomen] = n;
                $$ = $2;
            }     
          | FRACTVM_MVLTITVDO POST_NOMEN TOTVM_NVMERVM {
                string var_nomen = $2;
                int len = $3;
                struct Notitia n;
                n.forma = FLVCTVETVR_MVLTITVDO_FORMA;
                n.no = $3;
                popvlvs[var_nomen] = n;
                $$ = $2;
            }     

renascitvr: declaratio RENASCITVR nvmervm_expressio FINIS_SENTENTIAE {
                struct Notitia n;
                n.forma = popvlvs[$1].forma;
                n.no = popvlvs[$1].no;
                if(tractamvs_arithmetica(n, $3) == MORTVVS) {
                    yyerror("Absurdum hymenaeos");
                }
            }
          | NOMEN RENASCITVR nvmervm_expressio FINIS_SENTENTIAE {
                string var_nomen = $1;
                if(popvlvs.find(var_nomen) == popvlvs.end()) {
                    yyerror(("Non accepit nomen \"" + var_nomen + "\" ardebit").c_str());
                }
                if(tractamvs_arithmetica(popvlvs[$1], $3) == MORTVVS) {
                    yyerror("Absurdum hymenaeos");
                }
            }
;

nvmervm_expressio: FLVCTVETVR_NVMERVS                                   { $$.forma = FLVCTVETVR_FORMA; $$.no = -1; }
                 | TOTVM_NVMERVM                                        { $$.forma = TOTVM_FORMA; $$.no = -1; }
                 | NOMEN                                                { 
                                                                            string var_nomen = $1;
                                                                            if(popvlvs.find(var_nomen) == popvlvs.end()) {
                                                                                yyerror(("Non accepit nomen \"" + var_nomen + "\" ardebit").c_str());
                                                                                $$.forma = MORTVVS;
                                                                                $$.no = -1;
                                                                            } else {
                                                                                $$.forma = popvlvs[var_nomen].forma;
                                                                                $$.no = popvlvs[var_nomen].no;
                                                                            } 
                                                                        }
                 | mvltitvdo                                            { 
                                                                            $$.forma = MVLTITVDO_FORMA; 
                                                                            $$.no = $1; 
                                                                        }
                 | nvmervm_expressio ADDITAMENTVM nvmervm_expressio     { 
                        Forma res = tractamvs_arithmetica($1, $3);
                        $$.forma = res; 
                        if(res == MORTVVS) {
                            yyerror("Absurdum hymenaeos");
                        } 
                        $$.no = $1.no;
                   }
                 | nvmervm_expressio DETRACTIO nvmervm_expressio        { 
                        Forma res = tractamvs_arithmetica($1, $3);
                        $$.forma = res; 
                        if(res == MORTVVS) {
                            yyerror("Absurdum hymenaeos");
                        } 
                        $$.no = $1.no;
                   }
                 | nvmervm_expressio MVLTIPLICATIO nvmervm_expressio    { 
                        Forma res = tractamvs_arithmetica($1, $3);
                        $$.forma = res; 
                        if(res == MORTVVS) {
                            yyerror("Absurdum hymenaeos");
                        } 
                        $$.no = $1.no;
                   }
                 | nvmervm_expressio DIVISIO nvmervm_expressio          { 
                        Forma res = tractamvs_arithmetica($1, $3);
                        $$.forma = res; 
                        if(res == MORTVVS) {
                            yyerror("Absurdum hymenaeos");
                        } 
                        $$.no = $1.no;
                   }
                 | VNITAS nvmervm_expressio FINIS_VNITAS                { $$.forma = $2.forma; $$.no = $2.no }
                 | NEGANS nvmervm_expressio                             { $$.forma = $2.forma; $$.no = $2.no }
                 | DE nvmervm_expressio VENI nvmervm_expressio          {  
                                                                            if(
                                                                                $2.forma != MVLTITVDO_FORMA && 
                                                                                $2.forma != TOTVM_MVLTITVDO_FORMA &&
                                                                                $2.forma != FLVCTVETVR_MVLTITVDO_FORMA
                                                                            ) {
                                                                                yyerror("Mendax, haec mvltitvdo non est");
                                                                            }
                                                                            if ($4.forma != TOTVM_FORMA && $4.forma != FLVCTVETVR_FORMA) {
                                                                                yyerror("Mendax, hoc non est homo");
                                                                            }
                                                                            $$.forma = TOTVM_FORMA;
                                                                            $$.no = -1;
                                                                        }
;

conditione_instrvction: si_instrvction FINIS_POENITENTIAE FINIS_SENTENTIAE
                      | si_instrvction alivd_instrvction FINIS_POENITENTIAE FINIS_SENTENTIAE                
;               

si_instrvction: SI conditione INITIVM_POENITENTIAE NOVA_LINEA sanctae_instrvctiones; 

alivd_instrvction: ALIVD NOVA_LINEA sanctae_instrvctiones;

conditione: nvmervm_expressio IDEM nvmervm_expressio
          | nvmervm_expressio NON_IDEM nvmervm_expressio
          | conditione IDEM conditione
          | conditione NON_IDEM conditione
          | conditione ET conditione
          | conditione AVT conditione
          | VNITAS conditione FINIS_VNITAS
;

repetition_instrvction: REPETITIO_CONDITIONE conditione INITIVM_POENITENTIAE NOVA_LINEA sanctae_instrvctiones FINIS_POENITENTIAE FINIS_SENTENTIAE;
 
commvnicationis: LEGVNT nvmervm_expressio FINIS_SENTENTIAE
               | SCRIBE nvmervm_expressio FINIS_SENTENTIAE
;

%%

int main() {
    yydebug = 1;
	yyparse();	
}

void yyerror(string s) {
    //now, i know this is ugly, and most likely overtly complicated, but i am lazy to think it through better
    char tmp1[] = "syntax";
    if(s.length() >= 6) {
        bool bene = 1;
        for(int i = 0; i < 6 && bene; ++i)
            if (s[i] != tmp1[i])
                bene = 0;
        if(bene) {
            s = s.substr(7);
            char tmp2[] = "Ineptias: dixisti";
            int i = 0;
            while(tmp2[i]) {
                s[i] = tmp2[i];
                ++i;
            }
            ++i;

            while('A' <= s[i] && s[i] <= 'Z') {
                ++i;
            }

            char tmp3[] = ", in vicem ";
            int j = 0;
            while(tmp3[j]) {
                s[i + j] = tmp3[j];
                ++j;
            }
            i += j;

            while(i < s.length() - 1) {
                s[i] = s[i + 1];
                ++i;
            }
            s.resize(s.length() - 1);
        }
    }
	cout << s << " svb linea " << yylloc.first_line << " et colvmn " << yylloc.first_column << " " << endl;
}
