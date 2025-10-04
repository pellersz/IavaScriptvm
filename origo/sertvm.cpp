#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

int main(int argc, char* argv[]) {
    if(argc == 1) 
        return -1;

    ifstream source(argv[1]);
    if(source.fail()) {
        cout << "File \"" << argv[1] << "\" does not exist";
        return 1;
    }
    ofstream destination("sertvm_frvctvs.bbl");
    char file_name[256];
    
    int line_counter = 0;
    stringstream buf;
    bool first = 1;
    int line_count = 50;
    while(!source.getline(file_name, 256).eof()) {
        if(line_count > 50) {
            cout << "Page \"" << file_name << "\" too long";
            return 4;
        }

        if(!first) 
            buf << "\n";

        ++line_counter;
        if(source.fail()) {
            cout << "Error at line " << line_counter << " (this is probably beacuse the file name length limeit is 256 characters)";
            return 2;
        }

        ifstream page(file_name);
        if(page.fail()) {
            cout << "File \"" << file_name << "\" does not exist";
            return 3;
        }

        char c;
        line_count = 0;
        while ((c = page.get()) != EOF) {
            buf << c;
            if(c == '\n') {
                ++line_count;
            }
        }
    }

    destination << buf.str();
}