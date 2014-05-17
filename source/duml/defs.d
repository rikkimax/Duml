module duml.defs;
import duml.handler;

private {
	DumlConstruct[string] definitions;
}

void registerType(T...)() {
	import std.traits : fullyQualifiedName, BaseTypeTuple;
	foreach(U; T) {
		static if (is(U == class)) {
			if (fullyQualifiedName!U !in definitions) {
				definitions[fullyQualifiedName!U] = handleRegistrationOfType!U;
				foreach(V; BaseTypeTuple!U) {
					version(DumlIgnoreObject) {
						static if (!is(V == Object)) {
							registerType!V;
						}
					} else {
						registerType!V;
					}
				}
				foreach(func; definitions[fullyQualifiedName!U].callerClasses) {
					func();
				}
			}
		}
	}
}

string outputPlantUML() {
	string ret;
	ret ~= "@startuml\n";
	
	foreach(k, v; definitions) {
		ret ~= """
namespace " ~ v.name.ofModule ~ " {
	class " ~ v.name.ofClass ~ " {";
		foreach(field; v.fields) {
			ret ~= """
	    " ~ field.name ~ " : " ~ (v.name.ofModule == field.type.ofModule ? field.type.ofClass : field.type.fullyQuallified);
		}
		
		foreach(method; v.methods) {
			ret ~= """
	    " ~ method.name ~ "(";
			
			foreach(arg; method.arguments) {
				ret ~= arg.name ~ " : " ~ (v.name.ofModule == arg.type.ofModule ? arg.type.ofClass : arg.type.fullyQuallified) ~ ", ";
			}
			if (method.arguments.length > 0)
				ret.length -= 2;
			
			ret ~= ") : " ~ (v.name.ofModule == method.returnType.ofModule ? method.returnType.ofClass : method.returnType.fullyQuallified);
		}
		
		ret ~= """
	}
""";
		foreach(refc; v.referencedClasses) {
			ret ~= "\n    " ~ v.name.ofClass ~ " *--> " ~ (v.name.ofModule == refc.ofModule ? refc.ofClass : refc.fullyQuallified);
		}
		
		
		if (v.extends.ofClass != "") {
			ret ~= "\n    " ~ v.name.fullyQuallified ~ " --|> abstract " ~ v.extends.fullyQuallified ~ "\n";
			version(DumlIgnoreObject) {
			} else {
				ret ~= "    " ~ (v.name.ofModule == "object" ? v.extends.ofClass : v.extends.fullyQuallified) ~ " --|> interface object.Object";
			}
		}
		foreach(i; v.inheritsFrom) {
			ret ~= """
	"  ~ (v.name.ofModule == i.ofModule ? v.name.ofClass : v.name.fullyQuallified) ~ " --|> interface " ~ (v.name.ofModule == i.ofModule ? i.ofClass : i.fullyQuallified);
		}
		
		ret ~= "\n}\n";
	}
	
	ret ~= "\n@enduml\n";	
	return ret;
}

void outputToFile(string directory="umloutput", string javaExecLocation="java", string plantUmlLocation="plantuml.jar", string graphizDotLocation=null) {
	import std.file : write, rename, exists, mkdir;
	import std.process : execute;
	import std.path : buildPath;
	
	if (!exists(directory)) mkdir(directory);
	
	write(buildPath(directory, "input.plantuml"), outputPlantUML());
	execute([javaExecLocation, "-jar", plantUmlLocation, buildPath(directory, "input.plantuml")], ["GRAPHVIZ_DOT" : graphizDotLocation]);
	rename(buildPath(directory, "input.png"), buildPath(directory, "output.png"));
}

/**
 * Internal
 */
struct DumlConstruct {
	DumlConstructName name;
	
	DumlConstructName extends;
	DumlConstructName[] inheritsFrom;
	
	DumlConstructField[] fields;
	DumlConstructMethod[] methods;
	DumlConstructName[string] referencedClasses;
	
	void function()[] callerClasses;
}

struct DumlConstructName {
	string ofModule;
	string ofClass;
	string fullyQuallified;
}

struct DumlConstructField {
	string name;
	DumlConstructName type;
}

struct DumlConstructMethod {
	string name;
	DumlConstructName returnType;
	DumlConstructField[] arguments;
}