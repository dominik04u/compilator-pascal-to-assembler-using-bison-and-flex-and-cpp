#include "global.h"
#include "parser.h"
using namespace std;
extern ofstream stream;
using namespace std;
stringstream ss;
//wypisuje pojedyńczą zmienną dostosowywuje znak referencji, wartości, BP
void writeVariable(int index,bool isValue){

	//jeżeli do wypisania jest liczba poprzedza ją znakiem # i wypisuje
	if(symTable[index].token==NUM) ss<< "#" << symTable[index].name;
	//Jeżeli mamy do czynienia z referencją i trzeba wyłuskać adres
	else if(symTable[index].isReference==true){
		if(isValue) ss<<"*";
		if(symTable[index].isGlobal==false) {
			ss << "BP";if(symTable[index].address>=0) ss << "+";ss << symTable[index].address;
		}
		else ss << symTable[index].address;
	}
	//Jeżeli mamy do czynienia ze zeminna/tablicą
	else if(symTable[index].token==VAR || symTable[index].token==ARRAY)  {
		if(!isValue) ss<<"#";
		if(symTable[index].isGlobal==false) {
			ss<< "BP";if(symTable[index].address>=0) ss<<"+";ss << symTable[index].address;
		}
		else ss << symTable[index].address; 
	}
	else yyerror("Nieprawidłowy typ.\n");
}
//funkcja zwraca typ elementów, jak adres to integer
int getElementType(int index, bool isValue){
	int type;
	if(!isValue) 
		type = INTEGER;
	else 
		type = symTable[index].type;
	return type;
}
//konwertuje 2 zmienne na ten sam typ (wyższy) przekazuje dane przez referencję
void setIdenticalTypes(int &leftVar, bool isValueLeft, int &rightVar, bool isValueRight){
	//zaciąga typy
	int leftType = getElementType(leftVar, isValueLeft);
	int rightType = getElementType(rightVar, isValueRight);
	if(leftType!=rightType){
		if(leftType==INTEGER && rightType==REAL){
			int newLeftVar = createAdditionalVariable(REAL);	
			writeToOutputByToken(_INTTOREAL,newLeftVar,isValueLeft, leftVar, isValueLeft, -1, true);
			leftVar = newLeftVar;
		}
		else if(leftType==REAL && rightType==INTEGER){
			int newRightVar = createAdditionalVariable(REAL);
			writeToOutputByToken(_INTTOREAL,newRightVar,isValueRight, rightVar, isValueRight, -1, true);
			rightVar = newRightVar;
		}
		else{
			printf("Nierozpoznane typy zmiennych: %s %s\n",symTable[leftVar].name.c_str(),symTable[rightVar].name.c_str());
			yyerror("Złe typy.");
		}
	}
}
//dla := ustawia identyczny typ
bool setIdenticalTypeToAssign(int resultVar, bool isValueResult, int rightVar, bool isValueRight){
	int resultType = getElementType(resultVar, isValueResult);
	int rightType = getElementType(rightVar, isValueRight);
	if(resultType==rightType){
		return false;
	}
	else{
		if(resultType==INTEGER && rightType==REAL){
			writeToOutputByToken(_REALTOINT,resultVar, isValueResult, rightVar, isValueRight, -1, true);
			return true;
		}
		else if(resultType==REAL && rightType==INTEGER){
			writeToOutputByToken(_INTTOREAL,resultVar, isValueResult, rightVar, isValueRight, -1, true);
			return true;
		}
		else {
			printf("Niezgodność typów.: %s %s %d %d \n",symTable[resultVar].name.c_str(),symTable[rightVar].name.c_str(), resultType, rightType);
			yyerror("Niezgodność typów.");
			return false;
		}
	}
}
//generuje kod dla prawie wszystkiego
void writeToOutputByToken(int operand, int resultVar, bool isValueResult, int leftVar, bool isValueLeft, int rightVar, bool isValueRight){
	string operationType = ".i ";
	if(resultVar!=-1){
		if(symTable[resultVar].type==REAL) operationType = ".r ";
	}	
	
	if(operand==_RETURN){
		ss << "\n\treturn";
		string res;
		//zawartość srtingstreama do stringa
		res = ss.str();
		ss.str(string());//czyszczenie bo jest w res
		size_t pos = res.find("??");
		ss << "#" << -1*generateNewVariablePosition(string(""));
		res.replace(pos, 2, ss.str());
		stream.write(res.c_str(), res.size());
		ss.str(string());
	}
	else if(operand>=_EQ && operand<= _L){
		setIdenticalTypes(leftVar, isValueLeft, rightVar, isValueRight);
		operationType = ".i ";
		if(symTable[leftVar].type==REAL)
			operationType = ".r ";
		ss << "\n\t";
		if(operand==_EQ)			ss << "je";
		else if(operand==_NE) 	ss << "jne";
		else if(operand==_LE) 	ss << "jle";
		else if(operand==_GE) 	ss << "jge";
		else if(operand==_G) 	ss << "jg";
		else if(operand==_L) 	ss << "jl";	
		ss << operationType;
		writeVariable(leftVar, isValueLeft); 
		ss << ","; 
		writeVariable(rightVar, isValueRight);  
		ss << "," << "#" << symTable[resultVar].name;
	}	
	else if(operand==PROC || operand==FUN)
	{
		ss<< "\n" << symTable[resultVar].name << ":";
		ss<< "\n\tenter.i ??";
	}
	else if(operand==_LABEL){
		ss << "\n" << symTable[resultVar].name << ":";
	}
	else if(operand==_PUSH){
		ss << "\n\tpush.i "; writeVariable(resultVar,isValueResult);
	}
	else if(operand==_INCSP){
		ss << "\n\tincsp" << operationType; writeVariable(resultVar,isValueResult);
	}
	else if(operand==_JUMP){
		ss <<"\n\tjump.i #" << symTable[resultVar].name;
	}
	else if(operand==_CALL){
		ss <<"\n\tcall.i #" << symTable[resultVar].name;
	}
	else if(operand==_WRITE){
		ss << "\n\twrite" << operationType; writeVariable(resultVar,isValueResult);
	}
	else if(operand==_READ){
		ss << "\n\tread" << operationType;  writeVariable(resultVar,isValueResult);
	}
	else if (operand==_REALTOINT){
		ss << "\n\trealtoint.r ";
		writeVariable(leftVar,isValueLeft); 
		ss << ","; 
		writeVariable(resultVar,isValueResult);
	}
	else if(operand==ASSIGN){
		bool setSuccess = setIdenticalTypeToAssign(resultVar, isValueResult, rightVar, isValueRight);
		if(setSuccess == false){//jeżeli są tych samych typów jak były innych to funkcja setIdenticalTypeToAssign już przy konwersji je tam przepisała taka automatyzacja ;p
			ss << "\n\tmov" << operationType;
			writeVariable(rightVar,isValueRight); ss << ",";  writeVariable(resultVar,isValueResult);
		}
		else {return;}
	}
	else if (operand == _PLUS || operand == _MINUS){
		setIdenticalTypes(leftVar, isValueLeft, rightVar, isValueRight);
		ss<<"\n";
		if( operand == _MINUS) 
			ss << "\tsub"<< operationType;
		else 
			ss << "\tadd"<< operationType;
		writeVariable(leftVar,isValueLeft); 	ss << ","; 
		writeVariable(rightVar,isValueRight); 	ss << ","; 
		writeVariable(resultVar,isValueResult);
	}
	else if (operand == _MUL || operand == _DIV || operand == _MOD || operand==_AND || operand == OR){
		setIdenticalTypes(leftVar, isValueLeft, rightVar, isValueRight);
		ss<<"\n";
		if 		(operand == _MUL) 	ss << "\tmul";
		else if	(operand == _DIV) 	ss << "\tdiv";
		else if (operand == _MOD) 	ss << "\tmod";
		else if	(operand == _AND) 	ss << "\tand";
		else if	(operand == OR) 	ss << "\tor";
		ss << operationType;
		writeVariable(leftVar,isValueLeft); 
		ss << ","; 
		writeVariable(rightVar,isValueRight); 
		ss << ","; 
		writeVariable(resultVar,isValueResult);
		
	}
	else if (operand==_INTTOREAL){
		ss << "\n\tinttoreal.i ";
		writeVariable(leftVar,isValueResult); 
		ss << ","; 
		writeVariable(resultVar,isValueResult);
	}
	//stream.write(ss.str().c_str(), ss.str().size());
	//ss.str(string());//czyści
}
//generuje typ wyniku operacji na 2 elementach
int generateResultType(int a, int b){
	if(symTable[a].type == REAL || symTable[b].type==REAL) 
		return REAL;
	else 
		return INTEGER;
}
//zwraca mój token czyli w rzeczywistości liczbę na podstawie ciągu znaków
int getToken(const char* strVal){
	if(strcmp (strVal, "+") == 0)
		return _PLUS;
	if(strcmp (strVal, "-") == 0)
		return _MINUS;
	if(strcmp (strVal, "*") == 0)
		return _MUL;
	if(strcmp (strVal, "/") == 0 || strcmp (strVal, "div") == 0)
		return _DIV;
	if(strcmp (strVal, "mod")==0)
		return _MOD;
	if(strcmp (strVal, "and")==0)
		return _AND;
	if(strcmp(strVal, "=")==0)
		return _EQ;
	if(strcmp(strVal,">=")==0)
		return _GE;
	if(strcmp(strVal,"<=")==0)
		return _LE;
	if(strcmp(strVal,"<>")==0)
		return _NE;
	if(strcmp(strVal,">")==0)
		return _G;
	if(strcmp(strVal,"<")==0)
		return _L;
	return 0;
}
//funkcja szybkiego zapisu bezpośrednio przez parser dla prostych i niezmiennych operacji
void writeToOutput(const char* str){
	ss << str;
}
void writeIntToOutput(int i){
	ss << i;
}
void writeAllToFile(){
	stream.write(ss.str().c_str(), ss.str().size());
	ss.str(string());//czyści
}
