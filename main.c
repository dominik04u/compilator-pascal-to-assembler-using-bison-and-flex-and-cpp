#include "global.h"
#include "parser.h"

using namespace std;
ofstream stream;
bool isGlobal = true;

int main(int argc, char* argv[]) {
	
	FILE *plik_wejsciowy = fopen(argv[1],"r");
	
	if (!plik_wejsciowy) {
		printf("Brak pliku\n");
		return -1;
	}
	
	//plik dla leksera
	yyin = plik_wejsciowy;
	
	// ustaw zakres na globalny 
	isGlobal=true;
	stringstream streamStringa;
	// otwórz plik wynikowy
	stream.open("output.asm", ofstream::trunc);
	if(!stream.is_open()){
		printf("Nie można utworzyć pliku wynikowego");
		return 0;
	}
	printf("------%d---------",PROGRAM);  
	//wstaw do tablicy symboli read write i lab0
	element l;
	l.name=string("lab0");
	l.token=_LABEL;
	l.isGlobal = true;
	l.isReference=false;
	symTable.push_back(l);
	
	//jump.i #lab0
	streamStringa << "\tjump.i  #" << l.name ;
	stream.write(streamStringa.str().c_str(), streamStringa.str().size());
	
	element w;
	w.name=string("write");
	w.isGlobal=true;
	w.isReference=false;
	w.token=PROC;
	symTable.push_back(w);

	element r;
	r.name=string("read");
	r.isGlobal=true;
	r.isReference=false;
	r.token=PROC;
	symTable.push_back(r);
	
	int result = yyparse();
	printSymTable();
	stream.close();
	fclose(plik_wejsciowy);
	yylex_destroy();
	return 0;
}

