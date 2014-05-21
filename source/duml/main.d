module duml.main;
import duml.defs;

void main() {
	//registerType!(S1, duml.main, T1);
	//registerType!(std.algorithm, std.array, std.ascii, std.base64, std.bigint, std.bitmanip, std.compiler, std.complex,
	//              std.concurrency, std.container, std.conv, std.csv, std.datetime, std.encoding, std.exception, std.file, std.format, std.functional);
	
	void registerModule(string m)() {
		mixin("import " ~ m ~ ";");
		registerType!(mixin(m));
	}
	
	registerModule!"std.algorithm";
	registerModule!"std.array";
	registerModule!"std.ascii";
	registerModule!"std.base64";
	registerModule!"std.bigint";
	registerModule!"std.bitmanip";
	registerModule!"std.compiler";
	//registerModule!"std.complex";
	registerModule!"std.concurrency";
	registerModule!"std.container";
	registerModule!"std.conv";
	registerModule!"std.csv";
	registerModule!"std.datetime";
	registerModule!"std.encoding";
	registerModule!"std.exception";
	registerModule!"std.file";
	registerModule!"std.format";
	registerModule!"std.functional";
	
	registerModule!"std.getopt";
	registerModule!"std.json";
	registerModule!"std.math";
	registerModule!"std.mathspecial";
	registerModule!"std.metastrings";
	registerModule!"std.mmfile";
	registerModule!"std.numeric";
	registerModule!"std.outbuffer";
	registerModule!"std.parallelism";
	registerModule!"std.path";
	registerModule!"std.process";
	
	//registerModule!"std.random";
	registerModule!"std.range";
	registerModule!"std.regex";
	registerModule!"std.signals";
	registerModule!"std.socket";
	//registerModule!"std.socketstream";
	registerModule!"std.stdio";
	//registerModule!"std.cstream";
	//registerModule!"std.stream";
	registerModule!"std.string";
	registerModule!"std.system";
	
	registerModule!"std.traits";
	registerModule!"std.typecons";
	registerModule!"std.typetuple";
	//registerModule!"std.uni";
	registerModule!"std.uri";
	registerModule!"std.utf";
	registerModule!"std.uuid";
	//registerModule!"std.variant";
	registerModule!"std.xml";
	registerModule!"std.zip";
	
	//registerModule!"std.net.curl"; // curl may not be installed
	registerModule!"std.net.isemail";
	//registerModule!"std.digest.crc";
	registerModule!"std.digest.digest";
	//registerModule!"std.digest.md";
	//registerModule!"std.digest.ripemd";
	//registerModule!"std.digest.sha";
	registerModule!"std.windows.charset";
	
	
	
	version(Windows) {
		outputToFile("umloutput", "java", "winplantuml/plantuml.jar", "winplantuml/graphviz/bin/dot.exe");
	} else {
		// honestly I don't know how to use it here. As its just an example.
		pragma(msg, "You may want to change the config in main.d for java/plantuml.jar/dot.exe for graphiz");
		outputToFile("umloutput", "java", "plantuml.jar"); // don't assume dot location
	}
}

int xMyValue;

class T1 {
	string prop1;
	int[string] prop2;
	int prop3;
}

abstract class T2A1 {
	ubyte anotherprop;
}

class T2 : T2A1 {
	string prop1;
	int[string] prop2;
}

interface T3A1 {
	
}

class T3 : T3A1 {
	string prop1;
	int[string] prop2;
}

class T4 {
	string prop1;
	int[string] prop2;
	
	void myfunc(){}
	int myfunc2(){return 0;}
	void myfunc3(int a){}
}

class T5_1 {
	void* x;
}

class T5 {
	T5_1[string] values;
	
	void myfunc(void*){}
	void* myfunc2(){return null;}
}

class T6 {
	void myfunc(byte arg1, byte arg2){}
}

class T7_1 {
	ubyte b;
}

class T7 {
	T7_1 v;
	alias v this;
}

shared class T8 {
	ubyte v;
}

class T9 {
	shared ubyte v;
}

struct S1 {
	ubyte x;
}

struct S2_1 {
	ubyte x;
}

class S2_C2 {
	ubyte y;
}

struct S2 {
	S2_1 v;
	S2_C2 v2;
}

class T10 {
	final void somefinalfunc(){}
}