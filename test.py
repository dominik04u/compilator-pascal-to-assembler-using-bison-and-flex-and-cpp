import subprocess,sys,string


print ">>>>>>>>>>>>>>>>>>>>>>>>KOMPILACJA MOJEGO KOMPILATORA"
bashCommand = "make"
process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
output = process.communicate()[0]
print output

print ">>>>>>>>>>>>>>>>>>>>>>>>KOMPILACJA PLIKU "+sys.argv[1]+".pas MOIM KOMPILATOREM"
bashCommand = "./comp vm/"+sys.argv[1]+".pas";
process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
output = process.communicate()[0]
print output


print ">>>>>>>>>>>>>>>>>>>>>>>>KOMPILACJA PLIKU "+sys.argv[1]+".pas INNYM KOMPILATOREM"
bashCommand = "sh buildother.sh "+sys.argv[1];
process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
output = process.communicate()[0]
print output


moj = open('output.asm', 'r').read().split("\n")
nmoj = open('vm/output.asm', 'r').read().split("\n")






tmp = [];
if len(moj) > len(nmoj):
	tmp = nmoj
else:
	tmp = moj

zle = 0
print "MOJ                            | NMOJ                         | STAN"
for i in range(len(tmp)):
	
	print moj[i].translate(None, string.whitespace).ljust(30),
	print "|",
	print nmoj[i].split(";")[0].translate(None, string.whitespace).ljust(30),
	print "|",

	
	if nmoj[i].split(";")[0].translate(None, string.whitespace) == moj[i].translate(None, string.whitespace):
		print "OK"
	else:
		print "ZLEEEEEEEEEEE"
		zle +=1

print "Zlych linii: " + str(zle)

