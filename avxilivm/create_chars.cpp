#include <iostream>
#include <fstream>

using namespace std;

void convertLetters(const char *source_name, const char *destination_name, bool readable, bool list) {
    ifstream source(source_name);
    ofstream destination(destination_name);

    int ptr = 0;
    bool done = false;
    int how_many = 0;
    while(!done) {
        string buf(400, '\0');
        done = true;
        char tmp[100];
        int max_width = 0;
        tmp[0] = 0;

        int counter = 0;
        do {
            for(int i = 0; tmp[i]; i++) {
                if(tmp[i] != ' ') {
                    if (max_width < i + 1) {
                        ++max_width;
                    }
                }
            }

            for(int i = 0; tmp[i]; ++i)
                buf[counter++] = tmp[i];
            buf[counter++] = '\n';
            cout << tmp << "        ";
            source.getline(tmp, 100);
            
            done = counter == 1;
        } while (tmp[0] != '/' && tmp[0] != '\0');

        cout << buf;

        string final_buf = string(1000, '\0');
        counter = 0;
        if(!list)
            final_buf[counter++] = '"';
       
        if (!list)
            for(int i = 0; i < max_width + 4; ++i)
                final_buf[counter++] = '-';
        else {
            //this is bad, but if forgot how to use strings, so this is the best i will get for now
            char tmp1[] = "[-IVXLCDMTREWQKHGFBSA]{";
            
            int i = 0;
            while(tmp1[i]) 
                final_buf[counter++] = tmp1[i++];
            
            itoa(max_width + 3, tmp1, 10);
            i = 0;
            while(tmp1[i]) 
                final_buf[counter++] = tmp1[i++];

            final_buf[counter++] = '}';
            final_buf[counter++] = -30;
            final_buf[counter++] = -128;
            final_buf[counter++] = -96;
        }

        if (readable)
            final_buf[counter++] = '\n';
        else {
            final_buf[counter++] = '\\';
            final_buf[counter++] = 'n';
        }

        int buf_counter = 1;
        while(buf[buf_counter]) {
            if (!list) {
                if(!readable)
                    final_buf[counter++] = '\\';
                final_buf[counter++] = '|';
            } else {
                //this is bad, but if forgot how to use strings, so this is the best i will get for now
                char tmp1[] = "[|IVXLCDMTREWQKHGFBSA]";
                int i = 0;
                while(tmp1[i]) 
                    final_buf[counter++] = tmp1[i++];                
            }
         
            if(list) 
                final_buf[counter++] = '"';
            final_buf[counter++] = ' ';
            for(int i = 0; i < max_width; ++i) { 
                if (!readable && (buf[buf_counter] == '.' || buf[buf_counter] == '*' || buf[buf_counter] == '"' || buf[buf_counter] == '\'')) {
                    final_buf[counter++] = '\\';
                }
                final_buf[counter++] = buf[buf_counter++];
            }
            final_buf[counter++] = ' ';
            if(list)
                final_buf[counter++] = '"';
            
            if (!list) {
                if(!readable)
                    final_buf[counter++] = '\\';
                final_buf[counter++] = '|';
            } else {
                //this is bad, but if forgot how to use strings, so this is the best i will get for now
                char tmp1[] = "[|IVXLCDMTREWQKHGFBSA]";
                
                int i = 0;
                while(tmp1[i]) 
                    final_buf[counter++] = tmp1[i++];
            }
            
            while(buf[buf_counter] != '\n') {
                ++buf_counter;
            }

            if (readable)
                final_buf[counter++] = buf[buf_counter];
            else {
                final_buf[counter++] = '\\';
                final_buf[counter++] = 'n';
            }
            buf_counter++;
        }

        if (!list)
            for(int i = 0; i < max_width + 4; ++i)
                final_buf[counter++] = '-';
        else {
            //this is bad, but if forgot how to use strings, so this is the best i will get for now
            char tmp1[] = "[-IVXLCDMTREWQKHGFBSA]{";
            
            int i = 0;
            while(tmp1[i]) 
                final_buf[counter++] = tmp1[i++];
            
            itoa(max_width + 4, tmp1, 10);
            i = 0;
            while(tmp1[i]) 
                final_buf[counter++] = tmp1[i++];

            final_buf[counter++] = '}';
        }

        if(!list) 
            final_buf[counter++] = '"';
        
        final_buf.resize(counter);
        destination << final_buf << "\n\n";
    }

    source.close();
    destination.close();
}

int main() {
    convertLetters("floats.txt", "floats_final_readable.txt", true, false);
    cout << "1 done" << endl;
    convertLetters("ints.txt", "ints_final_readable.txt", true, false);
    cout << "2 done" << endl;
    convertLetters("floats.txt", "floats_final.txt", false, false);
    cout << "3 done" << endl;
    convertLetters("ints.txt", "ints_final.txt", false, false);
    cout << "4 done" << endl;
    convertLetters("floats.txt", "float_lists_final.txt", false, true);
    cout << "5 done" << endl;
    convertLetters("ints.txt", "int_lists_final.txt", false, true);
    cout << "6 done" << endl;
}