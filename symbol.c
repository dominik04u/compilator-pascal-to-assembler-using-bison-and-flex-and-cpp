#include "global.h"
#include "parser.h"
using namespace std;
vector<element> symTable;
int generateNewVariablePosition(string);

int counterGeneratedVariables=0;
int counterGeneratedLabels=1;
// alokuje nową zmienną tymczasową typu type
int createAdditionalVariable(int type){
	stringstream s;
	s << "$t" << counterGeneratedVariables++;
	int id = insert(s.str().c_str(), VAR, type);
	symTable[id].address = generateNewVariablePosition(s.str().c_str());//wygeneruj pozycję gdzie bedzie ta nowa zmienna
	return id;
}
// zwraca rozmiar danego wpisu w tablicy symboli
int getElementSize(element e){
	if(e.token == VAR){	
		if(e.type==INTEGER) return 4;
		else if(e.type==REAL) return 8;	
	}
	else if(e.token==ARRAY) {		
		int elemSize = 4;// rozmiar elementu tablicy
		if(e.type==REAL) 
			elemSize=8;
		int count = e.array.stopVal-e.array.startVal+1;
		return count*elemSize;
	}
	else if (e.isReference==true) 
		return 4;

	return 0;
}
//pozycję dla nowej zmiennej (rozmiar zaalokowanych zmiennych) w danej części local/global
//w zakresie globalnym pomijamy symbolName bo indeksy rosną w górę w okalnym odwrotnie
int generateNewVariablePosition(string symbolName){
	int varPosition = 0;
	if(isGlobal==true){
		for(int i=0;i<symTable.size();i++){
			if(symTable[i].isGlobal==false) break;
			if(symTable[i].name!=symbolName) varPosition += getElementSize(symTable[i]);
		}
	}
	else{
		for(int i=0;i<symTable.size();i++){
			if(symTable[i].isGlobal==false) {	
				if(symTable[i].address<=0) 	varPosition -= getElementSize(symTable[i]); //na minusie tak jak na laboratoriach
			}
		}
	}
	return varPosition;
}
//wstawia wpis do ST
int insert (const char* s, int token, int type) {
	element e; 
 	e.token = token;		// typ tokenu (VAR, NUM, ARRAY, FUN, PROC)
	string name(s);
	e.name = name;			//nazwa
	e.type = type;	
	e.isGlobal = isGlobal; // zakres
	e.isReference=false;
	e.address=0;
	symTable.push_back(e);
	return symTable.size()-1;
}
int lookup(const char* s){
	for(int p=symTable.size()-1; p>=0; p--){	
		if(symTable[p].name==s)
			return p;
	}
	return -1;
}
int createLabel(){
	stringstream s;
	s << "lab" << counterGeneratedLabels++;
	int id = insert(s.str().c_str(), _LABEL, NONE);
	return id;
}
string getTokenDesc(int tokenID){
	if(tokenID==PROC)		return string("Procedure");
	if(tokenID==FUN)		return string("Function");
	if(tokenID==_LABEL)		return string("Label");
	if(tokenID==ID)			return string("id");
	if(tokenID==VAR)		return string("Variable");
	if(tokenID==ARRAY) 		return string("array");
	if(tokenID==NUM)		return string("Number");
	if(tokenID==INTEGER)	return string("integer");
	if(tokenID==REAL)		return string("real");
	return string("Inny token");
}
void printSymTable(){
	printf("\nSymbol table\n");	
	for(int i=0;i<symTable.size(); i++){
		element e = symTable[i];
		cout << i;
		if(e.isGlobal==true) 
			cout << " Global ";	
		else 
			cout << " Local ";

		if(e.isReference==true) cout << getTokenDesc(e.token) << " " << e.name << " ref " << getTokenDesc(e.type) << " addr offset " << e.address << endl;
		else if(e.token==PROC || e.token==FUN || e.token==_LABEL) 	cout << getTokenDesc(e.token) << " " << e.name << endl;
		else if(e.token==VAR) 	cout << getTokenDesc(e.token) << " " << e.name << " " << getTokenDesc(e.type) << " addr offset " << e.address << endl;
		else if (e.token==ARRAY) cout << getTokenDesc(e.token) << " " << e.name << " array [" << e.array.startVal << ".." << e.array.stopVal << "] " <<  getTokenDesc(e.type) << " addr offset " << e.address << endl;
		else if(e.token==NUM) cout << getTokenDesc(e.token) << " " << e.name <<  " " << getTokenDesc(e.type) << endl;
		else if(e.token==ID) cout << getTokenDesc(e.token) << " " << e.name << endl;
		else cout << "OTHER" << e.name << " " << e.token << " " << e.type << " " << e.address << endl;
	}
}
int insertNumIfNE(const char* numVal, int numType){
	int num = lookup(numVal);
	if(num==-1) num = insert(numVal, NUM, numType); 
	return num;
}
int lookupIfExist(const char* s){
	int p = symTable.size()-1;
	//szukamy od końca w zakresie lokalnym
	if(isGlobal==false)	{
		for(p; p>=0; p--){	
			if(symTable[p].isGlobal==true)//brak w części lokalnej
				return -1;
			if(symTable[p].name==s)//znaleziono w części lokalnej
				return p;
		}
	}
	for(p; p>=0; p--){//czy jest w części globalnej	
		if(symTable[p].name==s)//znaleziono
			return p;
	}
	return -1;
}
void clearLocalVariables(){
	int localVarsStart = 0;
	for(int i=0;i<symTable.size();i++){
		if(symTable[i].isGlobal==false) break;
		localVarsStart++;
	}
	symTable.erase(symTable.begin()+localVarsStart, symTable.end());
}

int lookupForFunction(const char* s){
	for(int p=symTable.size()-1; p>=0; p--){	
		if( (symTable[p].token==FUN || symTable[p].token==PROC) && symTable[p].name==s)
			return p;
	}
	return -1;
}
//sprawdza czy istnieje zwraca -1 lub id elementu w tablicy symboli
