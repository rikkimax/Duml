﻿module duml.defs;
import duml.handler;
import std.range : isOutputRange;

private {
	DumlConstruct[string] definitions;
}

void registerType(T...)() {
	import std.traits : fullyQualifiedName, BaseTypeTuple, moduleName;
	foreach(U; T) {
		static if (is(U == class)) {
			if (fullyQualifiedName!U !in definitions) {
				auto def = handleRegistrationOfType!U;
				
				bool ignore;
				version(DumlIgnoreObject) {
					if (def.name.ofModule == "object") {
						ignore = true;
					}
				}
				
				if (!ignore) {
					definitions[fullyQualifiedName!U] = def;
					foreach(V; BaseTypeTuple!U) {
						version(DumlIgnoreObject) {
							static if (!is(V == Object)) {
								registerType!V;
							}
						} else {
							registerType!V;
						}
					}
					foreach(func; definitions[fullyQualifiedName!U].callerClasses.values) {
						func();
					}
				}
			}
		} else static if (is(U == struct) || is(U == union)) {
			if (fullyQualifiedName!U !in definitions) {
				auto def = handleRegistrationOfType!U;
				
				bool ignore;
				version(DumlIgnoreObject) {
					if (def.name.ofModule == "object") {
						ignore = true;
					}
				}
				
				if (!ignore) {
					definitions[fullyQualifiedName!U] = def;
					
					foreach(func; definitions[fullyQualifiedName!U].callerClasses.values) {
						func();
					}
				}
			}
		} else static if (U.stringof.length > 7 && U.stringof[0 .. 7] == "module " && __traits(compiles, {mixin("import " ~ moduleName!U ~ ";");})) {
			enum ModName = moduleName!U ~ ".__MODULE__";
			if (ModName !in definitions) {
				auto def = handleRegistrationOfType!U;
				
				bool ignore;
				version(DumlIgnoreObject) {
					if (def.name.ofModule == "object") {
						ignore = true;
					}
				}
				
				if (!ignore) {
					definitions[ModName] = def;
					
					foreach(func; definitions[ModName].callerClasses.values) {
						func();
					}
				}
			}
		}
	}
}

void outputPlantUML(ref string ret) {
	import std.array : appender;
	auto text = appender!string;
	outputPlantUML(text);
	ret = text.data;
}

void outputPlantUML(T)(T t) if (isOutputRange!(T, string)) {
	t.put("@startuml\n");
	
	foreach(k, v; definitions) {
		t.put("""
namespace " ~ v.name.ofModule ~ " {
    class " ~ v.name.ofClass ~ " {");
		
		foreach(field; v.fields) {
			t.put("""
        " ~ visibilityChar(field.protection) ~ field.name ~ " : " ~ (v.name.ofModule == field.type.ofModule ? field.type.ofClass : field.type.fullyQuallified));
		}
		
		foreach(method; v.methods) {
			t.put("""
        " ~ visibilityChar(method.protection) ~ method.name ~ "(");
			
			foreach(i, arg; method.arguments) {
				t.put(method.argStorageClasses[i] ~ arg.name ~ " : " ~ (v.name.ofModule == arg.type.ofModule ? arg.type.ofClass : arg.type.fullyQuallified));
				if (i < method.arguments.length - 1)
					t.put(", ");
			}
			
			t.put(") : " ~ (v.name.ofModule == method.returnType.ofModule ? method.returnType.ofClass : method.returnType.fullyQuallified));
		}
		
		t.put("""
    }
""");
		
		bool appendNewLine;
		
		foreach(k2, refc; v.referencedClasses) {
			appendNewLine = true;
			if (k2 !in v.hasAliasedClasses) {
				bool got = false;
				foreach(i; v.inheritsFrom) {
					if (i.fullyQuallified == k2)
						got = true;
				}
				if (!got)
					t.put("\n    " ~ v.name.ofClass ~ " *--> " ~ (v.name.ofModule == refc.ofModule ? refc.ofClass : refc.fullyQuallified).replace("(", " ").replace(")", " "));
			}
		}
		
		foreach(refc; v.hasAliasedClasses) {
			appendNewLine = true;
			t.put("\n    " ~ v.name.ofClass ~ " o--> " ~ (v.name.ofModule == refc.ofModule ? refc.ofClass : refc.fullyQuallified).replace("(", " ").replace(")", " "));
		}
		
		if (v.extends.ofClass != "") {
			appendNewLine = true;
			t.put("\n    " ~ v.name.fullyQuallified.replace("(", " ").replace(")", " ") ~ " --|> abstract " ~ v.extends.fullyQuallified.replace("(", " ").replace(")", " ") ~ "\n");
			version(DumlIgnoreObject) {
			} else {
				t.put("    " ~ (v.name.ofModule == "object" ? v.extends.ofClass : v.extends.fullyQuallified) ~ " --|> interface object.Object");
			}
		}
		
		foreach(i; v.inheritsFrom) {
			appendNewLine = true;
			t.put("""
    "  ~ (v.name.ofModule == i.ofModule ? v.name.ofClass : v.name.fullyQuallified) ~ " --|> interface " ~ (v.name.ofModule == i.ofModule ? i.ofClass : i.fullyQuallified).replace("(", " ").replace(")", " "));
		}
		
		if (appendNewLine)
			t.put("\n");
		
		t.put("}\n");
	}
	
	t.put("\n@enduml\n");
}

void outputToFile(string directory="umloutput", string javaExecLocation="java", string plantUmlLocation="plantuml.jar", string graphizDotLocation=null) {
	import std.file : write, rename, exists, mkdir;
	import std.process : execute, environment;
	import std.path : buildPath;
	
	if (!exists(directory)) mkdir(directory);
	
	string[string] env;
	if (graphizDotLocation is null || environment.get("GRAPHVIZ_DOT") is null)
		env["GRAPHVIZ_DOT"] = graphizDotLocation;
	
	string text;
	outputPlantUML(text);
	
	write(buildPath(directory, "input.plantuml"), text);
	execute([javaExecLocation, "-jar", plantUmlLocation, buildPath(directory, "input.plantuml"), "-tsvg"], env);
	rename(buildPath(directory, "input.svg"), buildPath(directory, "output.svg"));
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
	DumlConstructName[string] hasAliasedClasses;
	
	void function()[string] callerClasses;
}

struct DumlConstructName {
	string ofModule;
	string ofClass;
	string fullyQuallified;
}

enum DumlDefProtection {
	Public = "public",
	Private = "private",
	Protected = "protected",
	Export = "export",
	Package = "package"
}

struct DumlConstructField {
	string name;
	DumlConstructName type;
	DumlDefProtection protection;
}

struct DumlConstructMethod {
	string name;
	DumlConstructName returnType;
	DumlConstructField[] arguments;
	string[] argStorageClasses;
	
	DumlDefProtection protection;
}

pure string visibilityChar(DumlDefProtection p) {
	switch(p) {
		case DumlDefProtection.Private:
			return "-";
		case DumlDefProtection.Protected:
			return "#";
		case DumlDefProtection.Package:
			return "~";
			
		case DumlDefProtection.Export:
		case DumlDefProtection.Public:
		default:
			return "+";
	}
}