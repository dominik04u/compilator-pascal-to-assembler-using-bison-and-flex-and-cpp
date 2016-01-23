%{
	#include "global.h"
	using namespace std;
	//lista zmiennych którym później będzie przydzielony typ podczas deklaracji | lista argumentów funkcji write, ride
	vector<int> argsVector;
	void yyerror(char const* s);
	//zakres tablicy ma start i stop
	arrayRange array_range;
	//zmienna pomocnicza dla array do przekazania typu po deklaracji
	int helpVarArray;
	//początek offsetu parametrów fun/proc 8 dla proc 12 dla fun
	int funcProcParmOffset=8;
	//lista na parametry funkcji
	list<pair<int, arrayRange> > parameters;
	//LISTA DO OBLICZANIA INCSP
	list<int> funParams;

%}
%token 	PROGRAM
%token 	BEGINN
%token 	END
%token 	VAR
%token 	INTEGER
%token  REAL
%token	ARRAY
%token 	OF
%token	FUN
%token 	PROC
%token	IF
%token	THEN
%token	ELSE
%token	DO
%token	WHILE
%token 	RELOP
%token 	MULOP
%token 	SIGN
%token 	ASSIGN
%token	OR
%token 	NOT
%token 	ID
%token 	NUM
%token 	NONE
%token 	DONE
%%
start:	PROGRAM ID '(' start_params ')' ';' 
		declarations 
		subprogram_declarations		{writeToOutput("\nlab0:");}  
		compound_statement '.' 		{writeToOutput("\n\texit\n");writeAllToFile();} eof
		;
start_params:	ID					
				| start_params ',' ID 		
				;			
identifier_list : 		ID							{int ii = $1; if(ii==-1) YYERROR; argsVector.push_back(ii);}//-1 bo parser,WRZUĆ DO argsVector ID ustawił jak już było w ST
						| identifier_list  ',' ID 	{int ii = $3; if(ii==-1) YYERROR; argsVector.push_back(ii);}
						;
 
						
declarations:		declarations VAR identifier_list  ':' type ';'  {
																		//ustawiamy typ i obliczamy offset(adres)
																		for(int i=0; i<argsVector.size();i++){
																			if($5==INTEGER || $5 == REAL){	
																				symTable[argsVector[i]].token = VAR;
																				symTable[argsVector[i]].type = $5;
																				symTable[argsVector[i]].address = generateNewVariablePosition(symTable[argsVector[i]].name);								
																			}
																			else if($5==ARRAY) // dla tablic zapisz również dodatkowe dane
																			{
																				symTable[argsVector[i]].type = helpVarArray;
																				symTable[argsVector[i]].token= $5;
																				symTable[argsVector[i]].array=array_range;		// struktura zawierająca indeks początkowy i końcowy array
																				symTable[argsVector[i]].address=generateNewVariablePosition(symTable[argsVector[i]].name);
																			}
																			else{
																				yyerror("Nieznany typ.");YYERROR;
																			}
																		}
																		argsVector.clear(); // wyczyść listę indeksów napotkanych ID
																	}//JAK DOSZLIŚMY W DEKLARACJI DO TYPU TO GO USTAW (DLA ARRAY POBIERZ DANE Z helpVarArray ORAZ array_range) NADAJ OFFSETY FLA ZMIENNYCH CZYŚĆ argsVector
					| //nic
					;
type:			standard_type	
				| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type	{
																		$$=ARRAY; 
																		helpVarArray=$9; 
																		array_range.start=$3; 
																		array_range.argType=$9;
																		array_range.stop=$6;
																		array_range.startVal=atoi(symTable[$3].name.c_str()); 
																		array_range.stopVal=atoi(symTable[$6].name.c_str());
																	}//przez helpVarArray przekazujemy typ USTAW DANE ARRAY (TYPY START/STOP INDEKSY) W array_range ORAZ HELPvARaRRAY
				;
standard_type:		INTEGER 	
					| REAL	
					;
subprogram_declarations: 	subprogram_declarations subprogram_declaration ';'	
							|
							;
					
subprogram_declaration: 	subprogram_head declarations compound_statement {	
																				//koniec proc/func
																				writeToOutput("\n\tleave");
																				writeToOutputByToken(_RETURN,-1,true,-1,true,-1,true);
																				printSymTable();
																				clearLocalVariables();
																				isGlobal=true;			//bo już po funkcji..
																				funcProcParmOffset=8; 	//resetuje
																			}//KONIEC FUNKCJI LEAVE RETURN CZYŚĆ ZMIENNE LOKALNE ZMIEŃ NA GLOBALNY
;

subprogram_head:		FUN ID 					{	//WYPISZ LABEL FUNKCJI OFFSET NA 12, ZMIANA NA LOCAL
													int ii = $2; 
													if($2==-1) YYERROR;
													
													symTable[ii].token=FUN;
													isGlobal=false;
													writeToOutputByToken(FUN,ii,true,-1,true,-1,true);//wypisuje label funkcji
													funcProcParmOffset=12; //wartość zwracana pod +8 pod +12 parms
												} 
						arguments 				{	//PRZYPISZ PARAMETRY DO ST.PARMS Z PARAMETERS 
													symTable[$2].parameters=parameters; //info o argumentach
													parameters.clear(); 
												}
						':' standard_type 	
												{	//ZRÓB MIEJSCE NA WARTOŚĆ ZWRACANĄ
													symTable[$2].type=$7;//return type
													int returnVarible = insert(symTable[$2].name.c_str(), VAR, $7); 	//zmienna na wartosc zwracana
													symTable[returnVarible].isReference = true;				  			// referencja
													symTable[returnVarible].address=8;									// wartość zwracana pod offsetem +8
												}  
						';'  
						| PROC ID 				{ 	//OFFSET NA 8 ZMIANA NA LOCAL	
													int ii = $2; 
													if(ii==-1) YYERROR;
													
													symTable[ii].token=PROC;
													isGlobal=false;
													writeToOutputByToken(PROC,ii,true,-1,true,-1,true);	// wygeneruj początek procedury 
													funcProcParmOffset=8;				 				// pierwszy (jeśli wystąpi) parametr będzie pod offsetem +8
												}
						arguments 				{	//PRZYPISZ PARAMETRY DO ST.PARMS Z PARAMETERS
													symTable[$2].parameters=parameters; 
													parameters.clear(); 
												} ';' 
					;		
arguments:			'(' parameter_list ')' 	{ 	//USTAW OFFSETY DLA PARAMETRÓW +4...
												//lista parametrów w funkcji nadaj im kolejne offsety
												//iteruj po każdym parametrze
												for( list<int>::iterator it = funParams.begin(); it!=funParams.end(); it++){
													symTable[*it].address=funcProcParmOffset;
													funcProcParmOffset+=4;
												}
												funParams.clear(); // wyczyść listę przechowujacą parametry
											}	 
					|
;

parameter_list:			identifier_list  ':' type	{	//WRZUCA Z argsVector DO PARAMETERS(ABY PRZEKAZAĆ DO ST DO TEGO ID) I FUNpARMS(DO LICZENIA OFFSETÓW)
														int refType = $3;
														//przelatuje przez każdy argument funkcji 
														//ustawia referencje
														//ustawia typ
														//wrzuca do funParams (dzieki temu później będą policzone offsety)
														//wrzuca do parameters 
														for(int i=0;i<argsVector.size();i++){
															// oznacz jako referencję, ustaw typ oraz adres
															symTable[argsVector[i]].isReference=true;
															if(refType == ARRAY){
															printf("\nccc--- %d --- %d\n", symTable[argsVector[i]].type, refType );
																symTable[argsVector[i]].token = ARRAY;
																symTable[argsVector[i]].type = helpVarArray;
																symTable[argsVector[i]].array = array_range;
															}
															else symTable[argsVector[i]].type = refType;
															
															parameters.push_back(make_pair(refType, array_range));	// dodaj do listy argumentów
															funParams.push_front(argsVector[i]);					// lista po której będą nadawane adresy	
														}
														argsVector.clear();
													}	
													
						| parameter_list ';' identifier_list  ':' type  {
																			//to co wyżej
																			int refType = $5;
																			for(int i=0;i<argsVector.size();i++){
																				// oznacz jako referencję, ustaw typ oraz adres
																				symTable[argsVector[i]].isReference=true;
																				
																				
																				if(refType == ARRAY){
																					
																					symTable[argsVector[i]].token = ARRAY;
																					symTable[argsVector[i]].type = helpVarArray;
																					symTable[argsVector[i]].array = array_range;
																				}
																				else symTable[argsVector[i]].type = refType;
																				
																				parameters.push_back(make_pair(refType, array_range));	// dodaj do listy argumentów
																				funParams.push_front(argsVector[i]);			// lista po której będą nadawane adresy	
																			}
																			argsVector.clear();
																		}	  
;
compound_statement:	BEGINN optional_statement END	
					; 
			
optional_statement: 	statement_list			
						|		 
						;
statement_list: 	statement 						
					| statement_list ';' statement 			
					;

statement:		variable ASSIGN simple_expression 		{writeToOutputByToken(ASSIGN,$1,true,-1, true,$3,true); }
				| procedure_statement				
				| compound_statement
				
				| IF expression 	{	//ZRÓB LABEL $2 SPRAWDŹ CZY expression == 0 JAK NIE SKACZ	
										   
										int firstLabel = createLabel();//tworzymy label dla jumpa
										int newNumInST = insertNumIfNE("0",INTEGER);
										
										//jump dla niespełnionego warunku (expression=0), czy $2(expression) jest równe newNumInST czyli(0)
										writeToOutputByToken(_EQ, firstLabel, true, $2, true, newNumInST, true);
										$2 = firstLabel;				
									}
				THEN statement  	{	//RÓB LABEL2 $5 RÓB JUMPA DO $5, RÓB LABEL $2
										int secondLabel = createLabel();
										$5 = secondLabel;
										writeToOutputByToken(_JUMP, secondLabel, true, -1, true, -1, true);
										writeToOutputByToken(_LABEL, $2, true, -1, true, -1, true);
									}
				ELSE statement		{	//RÓB LABEL $5
										writeToOutputByToken(_LABEL, $5, true, -1, true, -1, true);
									}
				| WHILE 			{	//RÓB START $1 I STOP SS->$2 LABEL, WYPISZ STARTLABEL
										int stopLabel = createLabel(); 
										int startLabel = createLabel(); 
										$1 = startLabel;
										//Wstawia nowy token pod $2, kolejne poniżej będą przesunięte $2 --> $3 
										$$ = stopLabel;
										writeToOutputByToken(_LABEL, startLabel, true, -1, true, -1, true);
									}  
				expression DO 		{	//JAK WARUNEK NIE SPEŁNIONY UCIEKAJ DO STOP
										int v = insertNumIfNE("0",INTEGER);
										writeToOutputByToken(_EQ, $2, true, $3, true, v, true); 
									}
				statement 			{	//RÓB JUMP DO START I LABEL STOPU
										writeToOutputByToken(_JUMP, $1, true, -1, true, -1, true); 
										writeToOutputByToken(_LABEL, $2, true, -1, true, -1, true);
									} 
				;

variable:		ID					{	//ZWRÓĆ ID									
										int z = $1;
										if(z==-1) {
											yyerror("Niezadeklarowana zmienna!"); YYERROR;
										}
										$$=z;
									}
				| ID '[' simple_expression ']'		{	//JAK SIMPLE_EXP REAL TO ZMIEŃ NA INT, ODEJMIJ OD INDEKSU INDEX STARTOWY(WYPISZ MINUS) MNOŻENIE INDEKSU RAZY TYP OCZLICZENIE ADRESU ELEMENTU W NOWEJ ZMIENNEJ, ZMIANA NA REF
														//jak real zmien na int 
														int index = $3;
														if(symTable[index].type==REAL) {	
															int convertedVal = createAdditionalVariable(INTEGER);
															writeToOutputByToken(_REALTOINT, convertedVal, true, index, true, -1, true);
															index=convertedVal;
														}
														
														// wyciagnij indeks array w tablicy symboli i jej poczatkowy indeks
														int arrayId = $1;
														int startIndex = symTable[arrayId].array.start;
																	
														int realIndex = createAdditionalVariable(INTEGER); 								//zmienna na index startowy rzeczywisty 
														writeToOutputByToken(_MINUS, realIndex, true, index, true, startIndex, true);	// odejmij od indeksu indeks poczatkowy
														
														//dodaj numy jak nie ma 
														int arrayElementSize=0;
														if(symTable[arrayId].type==INTEGER)
															arrayElementSize = insertNumIfNE("4",INTEGER);
														else if(symTable[arrayId].type==REAL)
															arrayElementSize = insertNumIfNE("8",INTEGER);
														
														//element * pozycja
														writeToOutputByToken(_MUL, realIndex, true, realIndex, true, arrayElementSize, true);
														
														int varWithAddresOfArrayElement = createAdditionalVariable(INTEGER);
														//adres początku tablicy + adres elementu w tablicy i mamy w efekcie adres z wartością w tablicy  
														writeToOutputByToken(_PLUS, varWithAddresOfArrayElement, true, arrayId, false, realIndex, true);
														
														//ustaw, że jest to adres referentychny bo nie wskazuje na wartość lecz na wskaźnik pod którym jest wartość adresu, ustawienei typu na int/real
														symTable[varWithAddresOfArrayElement].isReference=true;
														symTable[varWithAddresOfArrayElement].type=symTable[arrayId].type;
														$$=varWithAddresOfArrayElement;
													}	
				;


procedure_statement: 	ID		 {	// wywołanie func/proc np aaa;WYWOŁANIE BEZ PARAMETRÓW GENERUJ CALL #SSS
									int procF = $1;
									if(procF==-1){
										yyerror("Użycie niezadeklarowanej nazwy.");
										YYERROR;
									}
									
									if(symTable[procF].token == FUN || symTable[procF].token==PROC){
										if(symTable[procF].parameters.size()>0){
											yyerror("Zła liczba parametrów.");
											YYERROR;
										}
										writeToOutput(string("\n\tcall.i #").c_str());writeToOutput(symTable[procF].name.c_str());
									}
									else{
										yyerror("Program oczekiwał nazwy funkcji a otrzymał coś innego.");
										YYERROR;
									}
								}
						| ID '(' expression_list ')'	{	//JAK READ WRITE WYPISZ ..
															//OBLICZ incspCount, FOR {KONWERTUJ TYPY I WRZUĆ NUMY DO PRZEKAZANIA JAKO PARMETRY FUNKCJI GENERUJ PUSHA}
															//USUŃ Z argsVector, ZRÓB ZMIENNĄ NA RETURN I JĄ ZWRÓĆ JAK FUNKCJA GENERUJ CALL I INCSP
															
															int index = $1;
															int r = lookup("read");
															int w = lookup("write");
															if(index==w || index==r){
																//dla każdego elementu z argsVector
																for(int i=0;i<argsVector.size();i++){
																	if($1==w)  writeToOutputByToken(_WRITE,argsVector[i],true, -1, true, -1, true );
																	if($1==r)  writeToOutputByToken(_READ, argsVector[i],true, -1, true, -1, true );
																}
															}
															else{		
																string idName = symTable[$1].name;
																int index = lookupForFunction(idName.c_str());
																if(index==-1){
																	yyerror("Niezadeklarowana nazwa.");
																	YYERROR;
																}
																
																if(symTable[index].token == FUN || symTable[index].token == PROC){
																	//podano za mało parametrów
																	if(argsVector.size()<symTable[index].parameters.size()){
																		yyerror("Nieprawidłowa liczba parametrów.");
																		YYERROR;
																	}
																	
																	
																	// zmienna na rozmiar wrzuconych na stos referencji
																	int incspCount = 0;
																	
																	
																	//iterator po argumentach
																	list<pair<int,arrayRange> >::iterator it=symTable[index].parameters.begin();
																	
																	int startPoint = argsVector.size() - symTable[index].parameters.size();
															
																	// przejdź po argumentach
																	for(int i=startPoint;i<argsVector.size();i++){
																	
																		int id = argsVector[i];
																		
																		// typ argumentu procedury/funkcji
																		int argumentType = (*it).first;
																		
																		
																		if(argumentType==ARRAY){
																			argumentType = (*it).second.argType;
																	
																		}
																		
																		// jeśli przekazujemy NUM to stwórz nowy obiekt w tablicy
																		if(symTable[argsVector[i]].token==NUM) {
																			// zmienna tymczasowa tworz od razu o takim typie, jakiego wymaga funkcja
																			int numVar = createAdditionalVariable(argumentType);
																			
																			writeToOutputByToken(ASSIGN,numVar,true, -1, true, argsVector[i], true);
																			id = numVar;
																		}
																		
																		
																		// typ przekazywany
																		int passedType = symTable[id].type;
																		
																		// typ argumentu funkcji i typ wartosci przekazywanej są różne (INT i REAL) - konwersja
																		if(argumentType!=passedType){
																			int tempVar = createAdditionalVariable(argumentType);
																			writeToOutputByToken(ASSIGN, tempVar, true, -1, true, id, true);
																			id = tempVar;
																		}
																		writeToOutputByToken(_PUSH,id,false,-1, true, -1, true);
																		incspCount+=4; // zwieksz adres parametrów
																		it++;
																	}
																	
																	// usun z wektora argumenty
																	int size = argsVector.size();
																	for(int i = startPoint;i<size;i++) 
																		argsVector.pop_back();
																	
																	
																	if(symTable[index].token==FUN){
																		// zmienna na wartość zwracaną
																		int id = createAdditionalVariable(symTable[index].type);
																		writeToOutputByToken(_PUSH,id,false,-1, true, -1, true);
																		incspCount+=4;	// zwiększ rozmiar 
																		$$ = id;
																	}
																												
																	// generuj call
																	writeToOutputByToken(_CALL, index,true,-1,true,-1,true);
																	
																	stringstream helper;
																	helper << incspCount;
																	
																	//generuj incsp
																	int incspNum = insertNumIfNE(helper.str().c_str(),INTEGER);
																	writeToOutputByToken(_INCSP,incspNum,true,-1,true,-1,true);
																}
																else
																{
																	yyerror("Brak takiej funkcji/procedury.");
																	YYERROR;
																}
															}
															argsVector.clear();
														}
;

expression_list:	expression							{argsVector.push_back($1);} 
					| expression_list ',' expression	{argsVector.push_back($3);}
					;

expression:		simple_expression				{$$=$1;}
				| simple_expression RELOP simple_expression	{	//GENERUJE LABELE I SKACZE W ZALEŻNOŚCI CZY SPEŁNIONY WARUNEK ZWRACA RESULTVAR
																int newLabelPass = createLabel();
																int relopType = $2;
																
																//skok jeżeli warunek spełniony 
																writeToOutputByToken(relopType, newLabelPass, true, $1, true, $3, true);
																
																//wynik operacji RELOP czyli 0 lub 1 
																int resultVar = createAdditionalVariable(INTEGER);
																int badVal = insertNumIfNE("0",INTEGER);
																
																//ustawia resultVar na 0 (warunek nie spełniony, nie przeskoczyliśmy)
																writeToOutputByToken(ASSIGN, resultVar, true, -1, true, badVal, true);
																
																//label ostatni za którym idzie dalsza część programu ten po obu (0 i 1)
																int newLabelFinish = createLabel(); 
																writeToOutputByToken(_JUMP, newLabelFinish, true, -1, true, -1, true);
																
																//jeżeli warunek spełniony
																writeToOutputByToken(_LABEL, newLabelPass, true, -1, true, -1, true);
																int goodVal = insertNumIfNE("1",INTEGER);
																writeToOutputByToken(ASSIGN, resultVar, true, -1, true, goodVal, true);//ustawia resultVar na 1 (warunek spełniony)
																
																//Label za całym wyrażeniem
																writeToOutputByToken(_LABEL, newLabelFinish, true, -1, true, -1, true);
																$$ = resultVar;
															}
				;

simple_expression:	term					
					| SIGN term							{	//DLA PLUSA ZWRÓĆ TERM DLA MINUSA ODEJMIJ OD ZERA I ZWRÓĆ
															if($1==_PLUS) $$=$2;
															else{
																//operacja jak mamy liczbę ujemną 
																$$=createAdditionalVariable(symTable[$2].type); 
																int tempVar = insertNumIfNE("0",symTable[$2].type);
																//SUB //odejmie od 0 naszą wartość z term
																writeToOutputByToken($1, $$, true, tempVar, true, $2, true);
															}
														} 
					| simple_expression SIGN term		{	//GENERUJE OPERACJE + LUB - ZWRACA WYNIK
															int resultType=generateResultType($1, $3);
															$$=createAdditionalVariable(resultType); 
															writeToOutputByToken($2, $$, true, $1, true, $3, true);
														}
					| simple_expression OR term			{	//GENERUJE OR ZWRACA WYNIK
															int tempVar = createAdditionalVariable(INTEGER);
															writeToOutputByToken(OR, tempVar, true, $1, true, $3, true);
															$$ = tempVar;}
					; 
 
term:		factor 
			| term MULOP factor		{	//ZWRACA WYNIK I ROBI OPERACJE DLA * MOD AND DIV
										int resultType=generateResultType($1, $3); // oczekiwany typ wyniku
										$$=createAdditionalVariable(resultType);//zwraca id w TS
										writeToOutputByToken($2, $$, true, $1, true, $3, true);
									}
			;

factor:			variable	{	//PROC NIE MOŻE BO NIE ZWRACA WYNIKU, WIĘC WYWOŁANIE FUNKCJI BEZ PARM  LUB ZMIENNA 
								//JAK FUN GENERUJ PUSH CALL I INCSP JAK ZMIENNA ZWRÓĆ VARIABLE JAK FUN ADRES ZWROTNY
								
								int funCalled = $1;	
								if(symTable[funCalled].token==FUN){
									if(symTable[funCalled].parameters.size()>0){
										yyerror("Wywołanie funkcji przyjmującej parametry bez parametrów");
										YYERROR;
									}
										funCalled = createAdditionalVariable(symTable[funCalled].type);//nowa zmienna na wartość którą zwróci funkcja
										
										writeToOutput(string("\n\tpush.i #").c_str());writeIntToOutput(symTable[funCalled].address);
										writeToOutput(string("\n\tcall.i #").c_str());writeToOutput(symTable[$1].name.c_str());
										
										//funkcja bez parametrów więc incsp = 4 
										writeToOutput(string("\n\tincsp.i #4").c_str());

								}
								else if(symTable[funCalled].token==PROC){
									yyerror("Nie można pobrać wyniku bo procedura go nie zwraca");
									YYERROR;
								}
								$$ = funCalled;
							}								
			| ID '(' expression_list ')' 	{ 	//OBLICZ incspCount, FOR {KONWERTUJ TYPY I WRZUĆ NUMY DO PRZEKAZANIA JAKO PARMETRY FUNKCJI GENERUJ PUSHA}
												//USUŃ Z argsVector, ZRÓB ZMIENNĄ NA RETURN I JĄ ZWRÓĆ JAK FUNKCJA
												//GENERUJ CALL I INCSP

												string name = symTable[$1].name;
												int index = lookupForFunction(name.c_str());
												
												if(index==-1){
													yyerror("Niezadeklarowana nazwa.");
													YYERROR;
												}
												
												if(symTable[index].token == FUN){
													if(argsVector.size()<symTable[index].parameters.size()){
														yyerror("Nieprawidłowa liczba parametrów.");
														YYERROR;
													}
													
													// zmienna na rozmiar wrzuconych na stos referencji
													int incspCount = 0;
									
													//iterator po argumentach
													list<pair<int,arrayRange> >::iterator it=symTable[index].parameters.begin();
									
													int startPoint = argsVector.size() - symTable[index].parameters.size();
									
												// przejdź po argumentach
												for(int i=startPoint;i<argsVector.size();i++){
													int id = argsVector[i];
										
													// typ argumentu procedury/funkcji
													int argumentType = (*it).first;
													if(argumentType==ARRAY) argumentType = (*it).second.argType;
										
										
										
													// jeśli przekazujemy NUM to stwórz nowy obiekt w tablicy
													if(symTable[argsVector[i]].token==NUM) {
														// zmienna tymczasowa tworz od razu o takim typie, jakiego wymaga funkcja
														int numVar = createAdditionalVariable(argumentType);
														writeToOutputByToken(ASSIGN,numVar,true, -1, true, argsVector[i], true);
														id = numVar;
													}
													
													// typ przekazywany
													int passedType = symTable[id].type;

													// typ argumentu funkcji i typ wartosci przekazywanej są różne (INT i REAL) - konwersja
													if(argumentType!=passedType){
														int tempVar = createAdditionalVariable(argumentType);
														writeToOutputByToken(ASSIGN, tempVar, true, -1, true, id, true);
														id = tempVar;
													}
													
													writeToOutputByToken(_PUSH,id,false,-1, true, -1, true);
													incspCount+=4; // zwieksz adres parametrów
													it++;
												}
												// usun z wektora argumenty
												int size = argsVector.size();
												
												for(int i = startPoint;i<size;i++) 
													argsVector.pop_back();
												
												// zmienna na wartość zwracaną
												int id = createAdditionalVariable(symTable[index].type);
												writeToOutputByToken(_PUSH,id,false,-1, true, -1, true);
												incspCount+=4;	// zwiększ rozmiar 
												$$ = id;
									
												// generuj call
												writeToOutputByToken(_CALL, index,true,-1,true,-1,true);
												
												stringstream helper;
												helper << incspCount;
									
												// generuj incsp
												int incspNum = insertNumIfNE(helper.str().c_str(),INTEGER);
												writeToOutputByToken(_INCSP,incspNum,true,-1,true,-1,true);
											}
								
										else if(symTable[index].token==PROC){
											yyerror("Procedury nie zwracają wartości, nie można wykonać operacji!");
											YYERROR;
										}
										else{
											yyerror("Nie znaleziono takiej funkcji/procedury.");
											YYERROR;
										}
								}
			| NUM					
			| '(' expression ')'			{$$=$2;}
			| NOT factor					{	//RÓB LABELE JAK 0 TO SKACZ JAK NIE TO TEŻ SKACZ ...							
												int labelFactorEqualZero = createLabel();
												int zeroId = insertNumIfNE("0",INTEGER);
												
												//jeq jeżeli factor == 0 skacz do miejsca w którym ustawimy wartość na 1 
												writeToOutputByToken(_EQ,labelFactorEqualZero, true, $2, true,  zeroId, true);
												
												//jeżeli factor był inny niż 0 to zapisz 0 to zmiennej jak boło to samo to nie wykona bo przeskoczył
												int varWithNotResult = createAdditionalVariable(INTEGER);
												writeToOutputByToken(ASSIGN,varWithNotResult, true, -1, true, zeroId, true);
												
												//jump na koniec
												int labelFinishNOT = createLabel();
												writeToOutputByToken(_JUMP, labelFinishNOT, true, -1, true, -1, true);
												
												//miejsce w którym wpisujemy 1 (bo factor był 0)
												writeToOutputByToken(_LABEL, labelFactorEqualZero, true, -1, true, -1, true);
												
												int num1 = insertNumIfNE("1",INTEGER);
												//jeżeli factor był 0 to zapisz 1
												writeToOutputByToken(ASSIGN,varWithNotResult, true, -1, true, num1, true);
												
												//label kończący NOT'a
												writeToOutputByToken(_LABEL, labelFinishNOT, true, -1, true, -1, true);
												$$=varWithNotResult;
											}
			;
eof:		DONE							{return 0; }
			;
%%
void yyerror(char const *s){
  printf("Błąd w linii %d: %s \n",lineno, s);
}
