%{
    #include <iostream>
    #include <cstring>
    #include <string>
    #include "common.h"
    #include "Iavascriptvm.tab.h"
    #define DEBUG 0

    #define YY_USER_ACTION {yylloc.first_line = line_no; \
        yylloc.first_column = col_no;                    \
        yylloc.first_line=line_no;                       \
        yylloc.last_column=col_no;                       \
        yylloc.last_line = line_no;}

    using namespace std;

    int line_no = 1, col_no = 1;
    int second_page_pos = 0;
    bool was_second_page = 0;
    int last_list_len = -1;
    char last_miniature = 0;

    void write_token(string token_name, string value) {
        last_miniature = 0;
        if (
            value.length() == 1 && 
            value[0] <= 'A' && 
            value[0] <= 'Z' &&
            value[0] != 'J' &&
            value[0] != 'U' &&
            value[0] != 'W' 
        ) 
            last_miniature = value[0];

        int n = strlen(yytext);
        if(DEBUG) {
            cout << "[linea: " << line_no << ", colvumna: " << col_no << ", longitudo: " << n << "] " << (!value.empty() ? value + " " : "") << token_name << endl; 
        }
        int last_line_pos = 0;
        
        for(int i = 0; i < n; ++i) {
            if (yytext[i] != '\n') {
                ++col_no;
            } else {
                col_no = 1;
                ++line_no;
            }
        }
    }

    int romanIntConverter(string num) {
        if(num.length() == 4 && num[3] == 'O') {
            return 0;
        }
        int res = 0;
        char digits[] = {'I', 'V', 'X', 'L', 'C', 'D', 'M', 'T', 'R', 'E', 'W', 'Q', 'K', 'H', 'G', 'F', 'B', 'S', 'A'};

        int base = 1;
        int n_ind = num.length() - 1;
        //nem biztos hogy 21
        for(int d_ind = 0; n_ind >= 3 && d_ind < 21; d_ind += 2, base *= 10) {
            if ((n_ind - 3) && d_ind < 20 && num[n_ind - 1] == digits[d_ind]) {
                if (num[n_ind] == digits[d_ind + 2]) {
                    res += 9 * base;
                    n_ind -= 2;
                    continue;
                } else if (num[n_ind] == digits[d_ind + 1]) {
                    res += 4 * base;
                    n_ind -= 2;
                    continue;
                }
            }
            
            int same_count = 0;
            while(num[n_ind] == digits[d_ind]) {
                res += base;
                --n_ind;
                ++same_count;
            }
            if(same_count > 3) {
                return -1;
            }

            if(d_ind < 20 && num[n_ind] == digits[d_ind + 1]) {
                res += 5 * base;
                --n_ind;
            }
        }
        if(n_ind > 2) 
            return -1;
        return res;
    }

    float romanFloatConverter(string num) {
        float res = 0.0f;
        char digits[] = {'I', 'V', 'X', 'L', 'C', 'D', 'M', 'T', 'R', 'E', 'W', 'Q', 'K', 'H', 'G', 'F', 'B', 'S', 'A'};

        int n_ind = num.find('.');
        res += romanIntConverter(num.substr(0, n_ind++));
        if(res == -1.0) {
            return -1.0;
        }

        double base = 0.1;
        while(n_ind < num.length() && num[n_ind] == 'O') { 
            base /= 10;
            ++n_ind;
        }

        if(n_ind == num.length()) 
            return res;

        int d_ind = 0;
        while(d_ind < 20 && digits[d_ind] != num[n_ind] && digits[d_ind + 1] != num[n_ind]) 
            d_ind += 2;

        for(;n_ind < num.length() && d_ind >= 0; d_ind -= 2, base /= 10) {
            if((num.length() - 3 - n_ind) && num[n_ind] == digits[d_ind]) {
                if(num[n_ind + 1] == digits[d_ind + 2]) {
                    res += 9 * base;
                    n_ind += 2;
                    continue;
                }else if(num[n_ind + 1] == digits[d_ind + 1]) {
                    res += 4 * base;
                    n_ind += 2;
                    continue;
                }
            }

            if(d_ind < 20 && num[n_ind] == digits[d_ind + 1]) {
                res += 5 * base;
                ++n_ind;
            }

            int same_count = 0;
            while(num[n_ind] == digits[d_ind]) {
                res += base;
                ++n_ind;
                ++same_count;
            }
            if(same_count > 3)
                return -1.0;
        }
        if(n_ind != num.length()) {
            return -1.0;
        }

        return res;
    }

    bool write_int_token(string num) {
        col_no -= 2;
        int res = romanIntConverter(num);
        yylval.totvm = res;
        if(res == -1) {
            cout << "Blasphemum numerum: \"" << yytext << "\" destrvxit svb linea " << line_no << " et colvmna " << col_no << endl;
            write_token("BLASPHEMVS_NVMERVS", yytext);
            return 0;
        } else {
            write_token("TOTVM_NVMERVM", to_string(res));
            return 1;
        }
    }

    bool write_float_token(string num) {
        col_no -= 2;
        float res = romanFloatConverter(num);
        yylval.flvctvetvr = res;
        if(res == -1) {
            cout << "Blasphemum numerum: \"" << yytext << "\" destrvxit svb linea " << line_no << " et colvmna " << col_no << endl;
            write_token("BLASPHEMVS_NVMERVS", yytext);
            return 0;
        } else {
            write_token("FLVCTVETVR_NVMERVS", to_string(res));
            return FLVCTVETVR_NVMERVS;
            return 1;
        }
    }

    int parse_miniature(string miniature) {
        int len = 0;
        int full_len = miniature.length();
        
        while(miniature[len++] != -30) {}
        ++len;
        
        string res = string(1000, '\0');
        res[0] = miniature[len - 2];
        res[1] = miniature[len - 1];
        res[2] = miniature[len];
        int counter = 3;

        for(int i = len - 3; i >= 0; --i) 
            if (miniature[i] != '-') 
                res[counter++] = miniature[i];
        
        for(int i = len + 2; i < full_len - 2; i += len) 
            if (miniature[i] != '-' && miniature[i] != '|') 
                res[counter++] = miniature[i];
        
        for(int i = full_len - len + 2; i < full_len; ++i) 
            if (miniature[i] != '-' && miniature[i] != '|') 
                res[counter++] = miniature[i];

        for(int i = full_len - len - 1; i > len + 1; i -= len) 
            if (miniature[i] != '|') 
                res[counter++] = miniature[i];

        res.resize(counter);
        int int_res = romanIntConverter(res);
        if(int_res == -1) {
            return -2;
        }
        return int_res;
    }
%}

%option noyywrap

%%

"--------------\n\| \.S_SSSs    \|\n\| \.SS~SSSSS  \|\n\| S%S   SSSS \|\n\| S%S    S%S \|\n\| S%S SSSS%S \|\n\| S&S  SSS%S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S\*S    S&S \|\n\| S\*S    S\*S \|\n\| S\*S    S\*S \|\n\| SSS    S\*S \|\n\|        SP  \|\n\|        Y   \|\n--------------"/[a-ik-tvx-z]+                                                  {write_token("FRACTVM", "A"); return FRACTVM;} 

"--------------\n\|  \.S_SSSs   \|\n\| \.SS~SSSSS  \|\n\| S%S   SSSS \|\n\| S%S    S%S \|\n\| S%S SSSS%P \|\n\| S&S  SSSY  \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S\*S    S&S \|\n\| S\*S    S\*S \|\n\| S\*S SSSSP  \|\n\| S\*S  SSY   \|\n\| SP         \|\n\| Y          \|\n--------------"/[a-ik-tvx-z]+                                                   {write_token("FRACTVM", "B"); return FRACTVM;} 

"----------\n\|   sSSs \|\n\|  d%%SP \|\n\| d%S'   \|\n\| S%S    \|\n\| S&S    \|\n\| S&S    \|\n\| S&S    \|\n\| S&S    \|\n\| S\*b    \|\n\| S\*S\.   \|\n\|  SSSbs \|\n\|   YSSP \|\n----------"/[a-ik-tvx-z]+                                                                                                                                                   {write_token("FRACTVM", "C"); return FRACTVM;} 

"--------------\n\|  \.S_sSSs   \|\n\| \.SS~YS%%b  \|\n\| S%S   `S%b \|\n\| S%S    S%S \|\n\| S%S    S&S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S\*S    d\*S \|\n\| S\*S   \.S\*S \|\n\| S\*S_sdSSS  \|\n\| SSS~YSSY   \|\n--------------"/[a-ik-tvx-z]+                                                                                      {write_token("FRACTVM", "D"); return FRACTVM;} 

"----------\n\|   sSSs \|\n\|  d%%SP \|\n\| d%S'   \|\n\| S%S    \|\n\| S&S    \|\n\| S&S_Ss \|\n\| S&S~SP \|\n\| S&S    \|\n\| S\*b    \|\n\| S\*S\.   \|\n\|  SSSbs \|\n\|   YSSP \|\n----------"/[a-ik-tvx-z]+                                                                                                                                                   {write_token("FRACTVM", "E"); return FRACTVM;} 

"----------\n\|   sSSs \|\n\|  d%%SP \|\n\| d%S'   \|\n\| S%S    \|\n\| S&S    \|\n\| S&S_Ss \|\n\| S&S~SP \|\n\| S&S    \|\n\| S\*b    \|\n\| S\*S    \|\n\| S\*S    \|\n\| S\*S    \|\n\| SP     \|\n\| Y      \|\n----------"/[a-ik-tvx-z]+                                                                                                                      {write_token("FRACTVM", "F"); return FRACTVM;} 

"------------\n\|   sSSSSs \|\n\|  d%%%%SP \|\n\| d%S'     \|\n\| S%S      \|\n\| S&S      \|\n\| S&S      \|\n\| S&S      \|\n\| S&S sSSs \|\n\| S\*b `S%% \|\n\| S\*S   S% \|\n\|  SS_sSSS \|\n\|   Y~YSSY \|\n------------"/[a-ik-tvx-z]+                                                                                                                        {write_token("FRACTVM", "G"); return FRACTVM;} 

"--------------\n\|            \|\n\|            \|\n\|  \.S    S\.  \|\n\| \.SS    SS\. \|\n\| S%S    S%S \|\n\| S%S    S%S \|\n\| S%S SSSS%S \|\n\| S&S  SSS&S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S\*S    S\*S \|\n\| S\*S    S\*S \|\n\| S\*S    S\*S \|\n\| SSS    S\*S \|\n\|        SP  \|\n\|        Y   \|\n--------------"/[a-ik-tvx-z]+           {write_token("FRACTVM", "H"); return FRACTVM;} 

"-------\n\|  \.S \|\n\| \.SS \|\n\| S%S \|\n\| S%S \|\n\| S&S \|\n\| S&S \|\n\| S&S \|\n\| S&S \|\n\| S\*S \|\n\| S\*S \|\n\| S\*S \|\n\| S\*S \|\n\| SP  \|\n\| Y   \|\n-------"/[a-ik-tvx-z]+                                                                                                                                                                    {write_token("FRACTVM", "I"); return FRACTVM;} 

"--------------\n\|  \.S    S\.  \|\n\| \.SS    SS\. \|\n\| S%S    S&S \|\n\| S%S    d\*S \|\n\| S&S   \.S\*S \|\n\| S&S_sdSSS  \|\n\| S&S~YSSY%b \|\n\| S&S    `S% \|\n\| S\*S     S% \|\n\| S\*S     S& \|\n\| S\*S     S& \|\n\| S\*S     SS \|\n\| SP         \|\n\| Y          \|\n--------------"/[a-ik-tvx-z]+                                               {write_token("FRACTVM", "K"); return FRACTVM;} 

"----------\n\| S\.     \|\n\| SS\.    \|\n\| S%S    \|\n\| S%S    \|\n\| S&S    \|\n\| S&S    \|\n\| S&S    \|\n\| S&S    \|\n\| S\*b    \|\n\| S\*S\.   \|\n\|  SSSbs \|\n\|   YSSP \|\n----------"/[a-ik-tvx-z]+                                                                                                                                                 {write_token("FRACTVM", "L"); return FRACTVM;} 

"---------------\n\|  \.S_SsS_S\.  \|\n\| \.SS~S\*S~SS\. \|\n\| S%S `Y' S%S \|\n\| S%S     S%S \|\n\| S%S     S%S \|\n\| S&S     S&S \|\n\| S&S     S&S \|\n\| S&S     S&S \|\n\| S\*S     S\*S \|\n\| S\*S     S\*S \|\n\| S\*S     S\*S \|\n\| SSS     S\*S \|\n\|         SP  \|\n\|         Y   \|\n---------------"/[a-ik-tvx-z]+                              {write_token("FRACTVM", "M"); return FRACTVM;} 

"--------------\n\|  \.S_sSSs   \|\n\| \.SS~YS%%b  \|\n\| S%S   `S%b \|\n\| S%S    S%S \|\n\| S%S    S&S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S\*S    S\*S \|\n\| S\*S    S\*S \|\n\| S\*S    S\*S \|\n\| S\*S    SSS \|\n\| SP         \|\n\| Y          \|\n--------------"/[a-ik-tvx-z]+                                                 {write_token("FRACTVM", "N"); return FRACTVM;} 

"-----------------\n\|   sSSs_sSSs   \|\n\|  d%%SP~YS%%b  \|\n\| d%S'     `S%b \|\n\| S%S       S%S \|\n\| S&S       S&S \|\n\| S&S       S&S \|\n\| S&S       S&S \|\n\| S&S       S&S \|\n\| S\*b       d\*S \|\n\| S\*S\.     \.S\*S \|\n\|  SSSbs_sdSSS  \|\n\|   YSSP~YSSY   \|\n-----------------"/[a-ik-tvx-z]+                                              {write_token("FRACTVM", "O"); return FRACTVM;} 

"--------------\n\|  \.S_sSSs   \|\n\| \.SS~YS%%b  \|\n\| S%S   `S%b \|\n\| S%S    S%S \|\n\| S%S    d\*S \|\n\| S&S   \.S\*S \|\n\| S&S_sdSSS  \|\n\| S&S~YSSY   \|\n\| S\*S        \|\n\| S\*S        \|\n\| S\*S        \|\n\| S\*S        \|\n\| SP         \|\n\| Y          \|\n--------------"/[a-ik-tvx-z]+                                                 {write_token("FRACTVM", "P"); return FRACTVM;} 

"-----------------\n\|   sSSs_sSSs   \|\n\|  d%%SP~YS%%b  \|\n\| d%S'     `S%b \|\n\| S%S       S%S \|\n\| S&S       S&S \|\n\| S&S       S&S \|\n\| S&S       S&S \|\n\| S&S       S&S \|\n\| S\*b       d\*S \|\n\| S\*S\.     \.S\*S \|\n\|  SSSbs_sdSSSS \|\n\|   YSSP~YSSSSS \|\n-----------------"/[a-ik-tvx-z]+                                              {write_token("FRACTVM", "Q"); return FRACTVM;} 

"--------------\n\|  \.S_sSSs   \|\n\| \.SS~YS%%b  \|\n\| S%S   `S%b \|\n\| S%S    S%S \|\n\| S%S    d\*S \|\n\| S&S   \.S\*S \|\n\| S&S_sdSSS  \|\n\| S&S~YSY%b  \|\n\| S\*S   `S%b \|\n\| S\*S    S%S \|\n\| S\*S    S&S \|\n\| S\*S    SSS \|\n\| SP         \|\n\| Y          \|\n--------------"/[a-ik-tvx-z]+                                                 {write_token("FRACTVM", "R"); return FRACTVM;} 

"----------\n\|   sSSs \|\n\|  d%%SP \|\n\| d%S'   \|\n\| S%\|    \|\n\| S&S    \|\n\| Y&Ss   \|\n\| `S&&S  \|\n\|   `S\*S \|\n\|    l\*S \|\n\|   \.S\*P \|\n\| sSS\*S  \|\n\| YSS'   \|\n----------"/[a-ik-tvx-z]+                                                                                                                                                {write_token("FRACTVM", "S"); return FRACTVM;} 

"-----------------\n\| sdSS_SSSSSSbs \|\n\| YSSS~S%SSSSSP \|\n\|      S%S      \|\n\|      S%S      \|\n\|      S&S      \|\n\|      S&S      \|\n\|      S&S      \|\n\|      S&S      \|\n\|      S\*S      \|\n\|      S\*S      \|\n\|      S\*S      \|\n\|      S\*S      \|\n\|      SP       \|\n\|      Y        \|\n-----------------"/[a-ik-tvx-z]+      {write_token("FRACTVM", "T"); return FRACTVM;} 

"--------------\n\|  \.S    S\.  \|\n\| \.SS    SS\. \|\n\| S%S    S%S \|\n\| S%S    S%S \|\n\| S&S    S%S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S&S    S&S \|\n\| S\*b    S\*S \|\n\| S\*S\.   S\*S \|\n\|  SSSbs_S\*S \|\n\|   YSSP~SSS \|\n--------------"/[a-ik-tvx-z]+                                                                                    {write_token("FRACTVM", "V"); return FRACTVM;} 

"-----------\n\|  \.S S\.  \|\n\| \.SS SS\. \|\n\| S%S S%S \|\n\| S%S S%S \|\n\| S%S S%S \|\n\|  SS SS  \|\n\|   S_S   \|\n\|  SS~SS  \|\n\| S\*S S\*S \|\n\| S\*S S\*S \|\n\| S\*S S\*S \|\n\| S\*S S\*S \|\n\| SP      \|\n\| Y       \|\n-----------"/[a-ik-tvx-z]+                                                                                              {write_token("FRACTVM", "X"); return FRACTVM;} 

"-----------\n\|  \.S S\.  \|\n\| \.SS SS\. \|\n\| S%S S%S \|\n\| S%S S%S \|\n\| S%S S%S \|\n\|  SS SS  \|\n\|   S S   \|\n\|   SSS   \|\n\|   S\*S   \|\n\|   S\*S   \|\n\|   S\*S   \|\n\|   S\*S   \|\n\|   SP    \|\n\|   Y     \|\n-----------"/[a-ik-tvx-z]+                                                                                                  {write_token("FRACTVM", "Y"); return FRACTVM;} 

"----------------\n\|  sdSSSSSSSbs \|\n\|  YSSSSSSSS%S \|\n\|         S%S  \|\n\|        S&S   \|\n\|       S&S    \|\n\|       S&S    \|\n\|      S&S     \|\n\|     S\*S      \|\n\|    S\*S       \|\n\|  \.s\*S        \|\n\|  sY\*SSSSSSSP \|\n\| sY\*SSSSSSSSP \|\n----------------"/[a-ik-tvx-z]+                                                            {write_token("FRACTVM", "Z"); return FRACTVM;} 



"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SSSs\. S%S \|\n\| SS    S%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| :;    ;:' \|\n-------------"/[a-ik-tvx-z]+         {write_token("TOTVM", "A"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SS \.sSSS  \|\n\| SS    S%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+         {write_token("TOTVM", "B"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    `:; \|\n\| SS        \|\n\| SS        \|\n\| SS        \|\n\| SS        \|\n\| SS    ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "C"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SS    S%S \|\n\| SS    S%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| ;;;;;;;:' \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "D"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    `:; \|\n\| SS        \|\n\| SSSs\.     \|\n\| SS        \|\n\| SS        \|\n\| SS    ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+         {write_token("TOTVM", "E"); return TOTVM;}

"------------\n\| \.s5SSSs\. \|\n\|          \|\n\| sS       \|\n\| SS       \|\n\| SSSs\.    \|\n\| SS       \|\n\| SS       \|\n\| SS       \|\n\| :;       \|\n------------"/[a-ik-tvx-z]+                      {write_token("TOTVM", "F"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    `:; \|\n\| SS        \|\n\| SS        \|\n\| SS        \|\n\| SS   ``:; \|\n\| SS    ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "G"); return TOTVM;}

"-------------\n\| \.s    s\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SSSs\. S%S \|\n\| SS    S%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| :;    ;:' \|\n-------------"/[a-ik-tvx-z]+         {write_token("TOTVM", "H"); return TOTVM;}

"-------\n\| s\.  \|\n\| SS\. \|\n\| S%S \|\n\| S%S \|\n\| S%S \|\n\| S%S \|\n\| `:; \|\n\| ;,\. \|\n\| ;:' \|\n-------"/[ \t]                                                                                     {write_token("TOTVM", "I"); return TOTVM;}

"-------------\n\| \.s    s\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SSSSs\.S:' \|\n\| SS  \"SS\.  \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| :;    ;:' \|\n-------------"/[a-ik-tvx-z]+       {write_token("TOTVM", "K"); return TOTVM;}      

"-------------\n\| \.s        \|\n\|           \|\n\| sS        \|\n\| SS        \|\n\| SS        \|\n\| SS        \|\n\| SS        \|\n\| SS    ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+            {write_token("TOTVM", "L"); return TOTVM;}

"-------------\n\| \.s5ssSs\.  \|\n\|    SS SS\. \|\n\| sS SS S%S \|\n\| SS :; S%S \|\n\| SS    S%S \|\n\| SS    S%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| :;    ;:' \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "M"); return TOTVM;}

"-------------\n\| \.s    s\.  \|\n\|       SS\. \|\n\| sSs\.  S%S \|\n\| SS`S\. S%S \|\n\| SS `S\.S%S \|\n\| SS  `sS%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| :;    ;:' \|\n-------------"/[a-ik-tvx-z]+       {write_token("TOTVM", "N"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SS    S%S \|\n\| SS    S%S \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "O"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SS \.sS::' \|\n\| SS        \|\n\| SS        \|\n\| SS        \|\n\| `:        \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "P"); return TOTVM;}

"------------\n\| \.s5SSs\.  \|\n\|      SS\. \|\n\| sS   S%S \|\n\| SS   S%S \|\n\| SS   S%S \|\n\| SS   S%S \|\n\| SS   `:; \|\n\| SS  `;,\. \|\n\| `:;;;;;; \|\n------------"/[a-ik-tvx-z]+                     {write_token("TOTVM", "Q"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SS \.sS;:' \|\n\| SS    ;,  \|\n\| SS    `:; \|\n\| SS    ;,\. \|\n\| `:    ;:' \|\n-------------"/[a-ik-tvx-z]+         {write_token("TOTVM", "R"); return TOTVM;}

"-------------\n\| \.s5SSSs\.  \|\n\|       SS\. \|\n\| sS    `:; \|\n\| SS        \|\n\| `:;;;;\.   \|\n\|       ;;\. \|\n\|       `:; \|\n\| \.,;   ;,\. \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+       {write_token("TOTVM", "S"); return TOTVM;}

"-------------\n\| \.s5SSSSs\. \|\n\|    SSS    \|\n\|    S%S    \|\n\|    S%S    \|\n\|    S%S    \|\n\|    S%S    \|\n\|    `:;    \|\n\|    ;,\.    \|\n\|    ;:'    \|\n-------------"/[a-ik-tvx-z]+           {write_token("TOTVM", "T"); return TOTVM;}

"-------------\n\| \.s    s\.  \|\n\|       SS\. \|\n\| sS    S%S \|\n\| SS    S%S \|\n\| SS    S%S \|\n\|  SS   S%S \|\n\|  SS   `:; \|\n\|   SS  ;,\. \|\n\|    `:;;:' \|\n-------------"/[a-ik-tvx-z]+          {write_token("TOTVM", "V"); return TOTVM;}

"-----------\n\| \.s5 s\.  \|\n\|     SS\. \|\n\| ssS SSS \|\n\| SSS SSS \|\n\|  SSSSS  \|\n\| SSS SSS \|\n\| SSS `:; \|\n\| SSS ;,\. \|\n\| `:; ;:' \|\n-----------"/[a-ik-tvx-z]+                                {write_token("TOTVM", "X"); return TOTVM;}

"-----------\n\| \.s5 s\.  \|\n\|     SS\. \|\n\| ssS SSS \|\n\| SSS SSS \|\n\|  SSSSS  \|\n\|   SSS   \|\n\|   `:;   \|\n\|   ;,\.   \|\n\|   ;:'   \|\n-----------"/[a-ik-tvx-z]+                                {write_token("TOTVM", "Y"); return TOTVM;}

"-------------\n\| \.s5SSSSs\. \|\n\|       SSS \|\n\|      sSS  \|\n\|     sSS   \|\n\|    sSS    \|\n\|   sSS     \|\n\|  sSS      \|\n\| sSS       \|\n\| `:;;;;;:' \|\n-------------"/[a-ik-tvx-z]+            {write_token("TOTVM", "Z"); return TOTVM;}



[-IVXLCDMTREWQKHGFBSA]{13}†\n[|IVXLCDMTREWQKHGFBSA]" \.S_SSSs    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" \.SS~SSSSS  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S   SSSS "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S SSSS%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S  SSS%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSS    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"        SP  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"        Y   "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{14}/[a-ik-tvx-z]+               {write_token("FRACTVM_MVLTITVDO", "A"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{13}†\n[|IVXLCDMTREWQKHGFBSA]"  \.S_SSSs   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" \.SS~SSSSS  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S   SSSS "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S SSSS%P "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S  SSSY  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S SSSSP  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S  SSY   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SP         "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" Y          "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{14}/[a-ik-tvx-z]+                {write_token("FRACTVM_MVLTITVDO", "B"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{9}†\n[|IVXLCDMTREWQKHGFBSA]"   sSSs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  d%%SP "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" d%S'   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*b    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S\.   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  SSSbs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"   YSSP "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{10}/[a-ik-tvx-z]+                                                                                                                                                                                             {write_token("FRACTVM_MVLTITVDO", "C"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{13}†\n[|IVXLCDMTREWQKHGFBSA]"  \.S_sSSs   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" \.SS~YS%%b  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S   `S%b "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    d\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S   \.S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S_sdSSS  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSS~YSSY   "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{14}/[a-ik-tvx-z]+                                                                                                                                       {write_token("FRACTVM_MVLTITVDO", "D"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{9}†\n[|IVXLCDMTREWQKHGFBSA]"   sSSs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  d%%SP "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" d%S'   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S_Ss "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S~SP "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*b    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S\.   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  SSSbs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"   YSSP "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{10}/[a-ik-tvx-z]+                                                                                                                                                                                             {write_token("FRACTVM_MVLTITVDO", "E"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{9}†\n[|IVXLCDMTREWQKHGFBSA]"   sSSs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  d%%SP "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" d%S'   "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S_Ss "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S~SP "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*b    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SP     "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" Y      "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{10}/[a-ik-tvx-z]+                                                                            {write_token("FRACTVM_MVLTITVDO", "F"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{11}†\n[|IVXLCDMTREWQKHGFBSA]"   sSSSSs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  d%%%%SP "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" d%S'     "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S      "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S      "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S      "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S      "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S sSSs "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*b `S%% "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S   S% "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"  SS_sSSS "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"   Y~YSSY "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{12}/[a-ik-tvx-z]+                                                                                                                                                                     {write_token("FRACTVM_MVLTITVDO", "G"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{13}†\n[|IVXLCDMTREWQKHGFBSA]"  \.S    S\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" \.SS    SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S SSSS%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S  SSS&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSS    S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"        SP  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"        Y   "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{14}/[a-ik-tvx-z]+            {write_token("FRACTVM_MVLTITVDO", "H"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{6}†\n[|IVXLCDMTREWQKHGFBSA]"  \.S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" \.SS "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SP  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" Y   "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{7}/[a-ik-tvx-z]+                                                                                                                     {write_token("FRACTVM_MVLTITVDO", "I"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{13}†\n[|IVXLCDMTREWQKHGFBSA]"  \.S    S\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" \.SS    SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    S&S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S    d\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S   \.S\*S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S_sdSSS  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S~YSSY%b "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S&S    `S% "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S     S% "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S     S& "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S     S& "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S\*S     SS "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SP         "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" Y          "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{14}/[a-ik-tvx-z]+            {write_token("FRACTVM_MVLTITVDO", "K"); last_list_len = parse_miniature(yytext); return FRACTVM_MVLTITVDO;}



[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSSs\. S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" :;    ;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+           {write_token("TOTVM_MVLTITVDO", "A"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS \.sSSS  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" `:;;;;;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+           {write_token("TOTVM_MVLTITVDO", "B"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" `:;;;;;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+            {write_token("TOTVM_MVLTITVDO", "C"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" ;;;;;;;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+            {write_token("TOTVM_MVLTITVDO", "D"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSSs\.     "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" `:;;;;;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+           {write_token("TOTVM_MVLTITVDO", "E"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{11}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"          "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS       "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS       "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSSs\.    "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS       "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS       "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS       "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" :;       "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{12}/[a-ik-tvx-z]+                      {write_token("TOTVM_MVLTITVDO", "F"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s5SSSs\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS        "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS   ``:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" `:;;;;;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+            {write_token("TOTVM_MVLTITVDO", "G"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s    s\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSSs\. S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" :;    ;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+           {write_token("TOTVM_MVLTITVDO", "H"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{6}†\n[|IVXLCDMTREWQKHGFBSA]" s\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" ;:' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{7}/[a-ik-tvx-z]+                                                                     {write_token("TOTVM_MVLTITVDO", "I"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}

[-IVXLCDMTREWQKHGFBSA]{12}†\n[|IVXLCDMTREWQKHGFBSA]" \.s    s\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]"       SS\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" sS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    S%S "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SSSSs\.S:\' "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS  \"SS\.  "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    `:; "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" SS    ;,\. "[|IVXLCDMTREWQKHGFBSA]\n[|IVXLCDMTREWQKHGFBSA]" :;    ;:\' "[|IVXLCDMTREWQKHGFBSA]\n[-IVXLCDMTREWQKHGFBSA]{13}/[a-ik-tvx-z]+       {write_token("TOTVM_MVLTITVDO", "K"); last_list_len = parse_miniature(yytext); return TOTVM_MVLTITVDO;}



[ \t]+      {
    write_token("SEPARATOR", ""); 
    if (last_list_len == -2) {
        cout << "Blasphemum numerum destrvxit svb linea " << line_no << " et colvmna " << col_no << endl;
        write_token("BLASPHEMVS_NVMERVS", yytext);
        last_list_len = -1;
    }
    else if (last_list_len != -1) {      
        write_token("TOTVM_NVMERVM", to_string(last_list_len));
        col_no -= 1;
        yylval.totvm = last_list_len;
        last_list_len = -1;
        return TOTVM_NVMERVM; 
    }
}

\n          {
    if ((bool) second_page_pos != was_second_page)
        cout << "Blasphemum pagina destrvxit svb linea " << line_no << endl;
    write_token("NOVA_LINEA", "");
    was_second_page = 0;
    return NOVA_LINEA;
}

\|.*        {
    was_second_page = 1;
    if (line_no == 1) {
        second_page_pos = col_no;
        write_token("SECVNDA_PAGINA", "");
    } else if (col_no != second_page_pos) {
        cout << "Blasphemum pagina destrvxit svb linea " << line_no << endl;
        write_token("BLASPHEMVS_PAGINA", "");
    } else {
        write_token("SECVNDA_PAGINA", "");
    }
}

\.          {write_token("FINIS_SENTENTIAE", ""); return FINIS_SENTENTIAE;}



LIBER/[ \t\n]                                   {write_token("LIBER", ""); return LIBER;}

"Legamvs verba domini nostri"/[ \t\n]           {write_token("LEGVNT", ""); return LEGVNT;}

"Lavdemvs dominvm in his verbis"/[ \t\n]        {write_token("SCRIBE", ""); return SCRIBE;}

"Dvm non svnt sine"/[ \t\n]                     {write_token("REPETITIO_CONDITIONE", ""); return REPETITIO_CONDITIONE;}

"Si peccatvm"/[ \t\n]                           {write_token("SI", ""); return SI;}

"Alivd"/[ \t\n]                                 {write_token("ALIVD", ""); return ALIVD;}

"oportet vos poenitenter cvm"/[ \t\n]           {write_token("INITIVM_POENITENTIAE", ""); return INITIVM_POENITENTIAE;}

"et Dominvs dimittat vobis"/[\.]                {write_token("FINIS_POENITENTIAE", ""); return FINIS_POENITENTIAE;}

"Amen"/[ \t\n]                                  {write_token("AMEN", ""); return AMEN;}



plvs/[ \t\n]                      {write_token("ADDITAMENTVM", ""); return ADDITAMENTVM;}

minvs/[ \t\n]                     {write_token("DETRACTIO", ""); return DETRACTIO;}       

"mvltiplicata per"/[ \t\n]        {write_token("MVLTIPLICATIO", ""); return MVLTIPLICATIO;}

"divisa per"/[ \t\n]              {write_token("DIVISIO", ""); return DIVISIO;}

et/[ \t\n]                        {write_token("ET", ""); return ET;}

avt/[ \t\n]                       {write_token("AVT", ""); return AVT;}

"non est idem"/[ \t\n]            {write_token("NON_IDEM", ""); return NON_IDEM;}

idem/[ \t\n]                      {write_token("IDEM", ""); return IDEM;}

"et renascitvr vt"/[ \t\n]        {write_token("RENASCITVR", ""); return RENASCITVR;}

"vnitas"/[ \t\n]                  {write_token("VNITAS", ""); return VNITAS;}

"finis"/[ \t\n\.]                 {write_token("FINIS_VNITAS", ""); return FINIS_VNITAS;}



negans                                                                  {write_token("NEGANS", ""); return NEGANS;}

†([IVXLCDMYTREWQKJHGFBSA]+|O)\.(O*[IVXLCDMYTREWQKJHGFBSA]*)/[ \t\n\.]   {
    if(write_float_token(yytext)) {
        return FLVCTVETVR_NVMERVS;
    } 
}

†([IVXLCDMYTREWQKJHGFBSA]+|O)/[ \t\n\.]                                 {
    if(write_int_token(yytext)) {
        return TOTVM_NVMERVM;
    }
}

"haec est"/[ \t\n]                                                      {write_token("MVLTITVDO", ""); return MVLTITVDO;}
"quae Domino servire vvlt"/[ \t\n\.]                                    {write_token("MVLTITVDO_FINIS", ""); return MVLTITVDO_FINIS;}
"de"/[ \t\n]                                                            {write_token("de", ""); return DE;}
"veni"/[ \t\n]                                                          {write_token("veni", ""); return VENI;}



[A-IK-TVX-Z][a-ik-tvx-z]+/[ \t\n\.]     {write_token("NOMEN", yytext); yylval.nomen = strdup(yytext); return NOMEN;}

[a-ik-tvx-z]+/[ \t]                     {
    if (last_miniature) {
        yylval.nomen = new char[strlen(yytext) + 2];
        strcpy(yylval.nomen, (last_miniature + string(yytext)).c_str());
    } else {
        yylval.nomen = new char[1];
        yylval.nomen[0] = 0;
    }
    write_token("POST_NOMEN", yytext);
    return POST_NOMEN;
}

([^ \t\n\.])+                           {
    cout << "Blasphemum verbvm: \"" << yytext << "\" destrvxit svb linea " << line_no << " et colvmna " << col_no << endl;
    write_token("BLASPHEMVS_VERBVM", "\"" + string(yytext) + "\"");
}

%%
