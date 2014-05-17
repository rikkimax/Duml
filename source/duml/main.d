module duml.main;
import duml.defs;

void main() {
	registerType!T1;
	registerType!(T2, T3, T4, T5, T6);
	version(Windows) {
		outputToFile("umloutput", "java", "winplantuml/plantuml.jar", "winplantuml/graphviz/bin/dot.exe");
	} else {
		// honestly I don't know how to use it here. As its just an example.
		pragma(msg, "You may want to change the config in main.d for java/plantuml.jar/dot.exe for graphiz");
		outputToFile("umloutput", "java", "plantuml.jar", "dot");
	}
}

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