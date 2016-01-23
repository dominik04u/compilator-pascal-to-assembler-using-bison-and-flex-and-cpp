%{
#include "global.h"
#include "parser.h"
int lineno = 1;
%}
digit 		[0-9]
letter		[a-zA-Z]
relop		"="|"<>"|"<"|"<="|">="|">"
assign		":="
mulop		"*"|"mod"|"/"|"and"|"div"
sign		"+"|"-"	
array		"array"
of			"of"
function	"function"
procedure	"procedure"
integer		"integer"
realWord	"real"
id			{letter}({letter}|{digit})*
int			{digit}+
exponent 	[eE][+-]?{int}
real		{int}("."{int}){exponent}?
%%
[\t | " "]+	
[ \n ]		{lineno++;} 
program		{return PROGRAM;}
begin		{return BEGINN;}
end			{return END;}
var 		{return VAR;}
{integer}	{yylval = INTEGER; return INTEGER;}
{realWord}	{yylval = REAL; return REAL;}
not			{return NOT;}
or			{return OR;}
if			{return IF;}
then		{return THEN;}
else		{return ELSE;}
do			{return DO;}
while		{return WHILE;}
{array}		{return ARRAY;}
{of}		{return OF;}
{function}	{return FUN;}
{procedure}	{return PROC;}
{relop}		{yylval = getToken(yytext); return RELOP;}
{mulop}		{yylval = getToken(yytext); return MULOP;}
{sign}		{yylval = getToken(yytext); return SIGN;}
{assign}	{return ASSIGN;}
{id}		{
				int p = lookupIfExist (yytext); 
				if (p == -1) p = insert (yytext, ID, NONE);
				yylval = p; 
				return ID;
			}
{int}		{
				int p = lookupIfExist (yytext); 
				if (p == -1) p = insert (yytext, NUM, INTEGER);
				yylval = p; 
				return NUM;
			}
{real}		{	
				int p = lookupIfExist (yytext); 
				if (p == -1) p = insert (yytext, NUM, REAL);
				yylval = p; 
				return NUM;
			}
<<EOF>>		{return DONE;}
.			{return *yytext;}
%%