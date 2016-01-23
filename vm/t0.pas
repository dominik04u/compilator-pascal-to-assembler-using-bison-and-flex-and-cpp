program example(input, output);
var x,y: integer;
var o :array [1..10] of integer;

begin
  o[2]:=1;
  o[1]:=o[2];
  o[1]:=o[2];
  write(o[2])
end.
