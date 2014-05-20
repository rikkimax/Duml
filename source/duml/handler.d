module duml.handler;
import duml.defs;
import std.traits;
import std.string : toLower, indexOf;

pure DumlConstruct handleRegistrationOfType(T)() if (is(T == class) || __traits(isAbstractClass, T) || is(T == interface)) {
	DumlConstruct ret;
	
	foreach(i, iUsed; BaseTypeTuple!T) {
		static if (!__traits(isSame, T, Object) && !__traits(isSame, iUsed, Object)) {
			static if (isAbstractClass!iUsed) {
				ret.extends = DumlConstructName(moduleName!iUsed, __traits(identifier, iUsed), fullyQualifiedName!iUsed);
			} else {
				ret.inheritsFrom ~= DumlConstructName(moduleName!iUsed, __traits(identifier, iUsed), fullyQualifiedName!iUsed);
			}
		}
	}
	
	version(DumlIgnoreObject) {
	} else static if (!__traits(isSame, T, Object)) {
		ret.inheritsFrom ~= DumlConstructName("object", "Object", fullyQualifiedName!Object);
	}
	
	handleRegistrationOfTypeBase!T(ret);
	ret.callerClasses[fullyQualifiedName!T] = &registerType!(mixin(moduleName!T));
	
	return ret;
}

pure DumlConstruct handleRegistrationOfType(T)() if (is(T == struct) || is(T == union)) {
	DumlConstruct ret;
	
	handleRegistrationOfTypeBase!T(ret);
	
	return ret;
}

pure bool isModule(alias U)() {
	return U.stringof.length > 7 && U.stringof[0 .. 7] == "module " && __traits(compiles, {mixin("import " ~ moduleName!U ~ ";");});
}

DumlConstruct handleRegistrationOfType(alias T)() if (isModule!T) {
	DumlConstruct ret;
	ret.name = DumlConstructName(moduleName!T, "_MODULE_", moduleName!T ~ "._MODULE_");
	mixin("import t = " ~ moduleName!T ~ ";");
	
	foreach(m; __traits(allMembers, t)) {
		static if (m == "object") {
		} else static if (__traits(compiles, typeof(mixin("t." ~ m)))) {			
			static if (__traits(compiles, {mixin("typeof(t." ~ m ~ ") X;");})) {
				class N {mixin("typeof(t." ~ m ~ ") X;");}
				
				static if (isUsable!(N, "X") && implementedName!(N, "X")) {
					// field
					DumlConstructField field = grabField!(typeof(mixin("t." ~ m)), t, m)(ret);
					field.protection = cast(DumlDefProtection)__traits(getProtection, mixin("t." ~ m));
					ret.fields ~= field;
				}
			} else static if (__traits(compiles, typeof(mixin("t." ~ m))) && is(typeof(mixin("t." ~ m)) == function)) {
				// function
				DumlConstructMethod method;
				method.name = m;
				alias SCT = ParameterStorageClassTuple!(mixin("t." ~ m));
				
				static if (__traits(compiles, ParameterIdentifierTuple!(mixin("t." ~ m)))) {
					alias names = ParameterIdentifierTuple!(mixin("t." ~ m));
					
					foreach(i, v; ParameterTypeTuple!(typeof(mixin("t." ~ m)))) {
						method.arguments ~= grabField!(v, T, names[i])(ret);
						method.argStorageClasses ~= getSCValue(SCT[i]);
					}
				} else {
					foreach(i, v; ParameterTypeTuple!(typeof(mixin("t." ~ m)))) {
						method.arguments ~= grabField!(v, T, "...")(ret);
						method.argStorageClasses ~= getSCValue(SCT[i]);
					}
				}
				
				static if (is(ReturnType!(typeof(mixin("t." ~ m))) == void)) {
					method.returnType = DumlConstructName("", "void", "void");
				} else {
					method.returnType = grabField!(ReturnType!(typeof(mixin("t." ~ m))), T, "")(ret).type;
				}
				
				method.protection = cast(DumlDefProtection)__traits(getProtection, mixin("t." ~ m));
				
				ret.methods ~= method;
			}
		} else {
			mixin("alias U = t." ~ m ~ ";");
			static if (is(U == class) || is(U == struct) || is(U == union) || is(U == interface)) {
				ret.callerClasses[fullyQualifiedName!U] = &registerType!(U);
			}
		}
	}
	
	return ret;
}

pure void handleRegistrationOfTypeBase(alias T)(ref DumlConstruct ret) {
	ret.name = DumlConstructName(moduleName!T, __traits(identifier, T), fullyQualifiedName!T);
	
	static if (__traits(compiles, {T t = T.init;})) {
		T t = T.init;
	} else static if (__traits(compiles, {T t = new T;})) {
		T t = new T;
	} else {
	}
	
	foreach(m; __traits(allMembers, T)) {
		static if (__traits(compiles, typeof(mixin("t." ~ m)))) {
			static if (!isCallable!(mixin("t." ~ m)) && isUsable!(T, m)) {
				// field
				DumlConstructField field = grabField!(typeof(mixin("t." ~ m)), T, m)(ret);
				field.protection = cast(DumlDefProtection)__traits(getProtection, mixin("t." ~ m));
				ret.fields ~= field;
			} else static if (is(typeof(mixin("t." ~ m)) == function) || is(typeof(mixin("t." ~ m)) == delegate)) {
				// method
				static if (!__traits(hasMember, Object, m) || is(T == Object)) {
					
					DumlConstructMethod method;
					method.name = m;
					alias SCT = ParameterStorageClassTuple!(mixin("t." ~ m));
					
					static if (__traits(compiles, ParameterIdentifierTuple!(mixin("t." ~ m)))) {
						alias names = ParameterIdentifierTuple!(mixin("t." ~ m));
						
						foreach(i, v; ParameterTypeTuple!(typeof(mixin("t." ~ m)))) {
							method.arguments ~= grabField!(v, T, names[i])(ret);
							method.argStorageClasses ~= getSCValue(SCT[i]);
						}
					} else {
						foreach(i, v; ParameterTypeTuple!(typeof(mixin("t." ~ m)))) {
							method.arguments ~= grabField!(v, T, "...")(ret);
							method.argStorageClasses ~= getSCValue(SCT[i]);
						}
					}
					
					static if (is(ReturnType!(typeof(mixin("t." ~ m))) == void)) {
						method.returnType = DumlConstructName("", "void", "void");
					} else {
						method.returnType = grabField!(ReturnType!(typeof(mixin("t." ~ m))), T, "")(ret).type;
					}
					
					method.protection = cast(DumlDefProtection)__traits(getProtection, mixin("t." ~ m));
					
					ret.methods ~= method;
				}
			}
		}
	}
	
	foreach(a; __traits(getAliasThis, T)) {
		alias U = typeof(__traits(getMember, t, a));
		ret.hasAliasedClasses[fullyQualifiedName!U] = DumlConstructName(moduleName!U, __traits(identifier, U), fullyQualifiedName!U);
		ret.callerClasses[fullyQualifiedName!U] = &registerType!U;
	}
}

pure string getSCValue(ubyte v) {
	string ret;
	
	if ((v & ParameterStorageClass.scope_) == ParameterStorageClass.scope_)
		ret ~= "scope ";
	if ((v & ParameterStorageClass.out_) == ParameterStorageClass.out_)
		ret ~= "out ";
	if ((v & ParameterStorageClass.ref_) == ParameterStorageClass.ref_)
		ret ~= "ref ";
	if ((v & ParameterStorageClass.lazy_) == ParameterStorageClass.lazy_)
		ret ~= "lazy ";
	
	if (ret.length == 0)
		ret = "in ";
	
	return ret;
}

pure bool implementedName(T, string n)() {
	foreach(name; __traits(derivedMembers, T)) {
		if (name == n)
			return true;
	}
	return false;
}

pure DumlConstructField grabField(T, alias U, string m, bool isPtr=false)(ref DumlConstruct data) {
	DumlConstructField ret;
	static if (T.stringof != typeof(null).stringof) {
		static if (is(T : void)) {
			ret = DumlConstructField(m, DumlConstructName("", "void" ~ (isPtr ? "*" : ""), "void" ~ (isPtr ? "*" : "")));
		} else static if (__traits(compiles, {T t = T.init;}) || __traits(compiles, {T t = new T;})) {
			static if (__traits(compiles, {T t = T.init;})) {
				T t = T.init;
			} else static if (__traits(compiles, {T t = new T;})) {
				T t = new T;
			}
			
			static if (isPointer!T) {
				ret = grabField!(PointerTarget!T, U, m, true)(data);
			} else static if (isBasicType!(T)) {
				ret = DumlConstructField(m, DumlConstructName("", T.stringof ~ (isPtr ? "*" : ""), fullyQualifiedName!T ~ (isPtr ? "*" : "")));
			} else static if (isArray!(T)) {
				foreach(e; [t.init]) {
					static if (__traits(compiles, fullyQualifiedName!(typeof(e)))) {
						ret = DumlConstructField(m, DumlConstructName("", typeof(e).stringof ~ (isPtr ? "*" : ""), fullyQualifiedName!(typeof(e)) ~ (isPtr ? "*" : "")));
					}
				}
				
				if (is(T == class) || is(T == struct) || is(T == union) || is(T == interface) || is(T == interface)) {
					static if (!is(U == T)) {
						data.referencedClasses[ret.type.fullyQuallified] = ret.type;
						static if (__traits(compiles, fullyQualifiedName!T))
							data.callerClasses[fullyQualifiedName!T] = &registerType!T;
					}
				}
			} else static if (isAssociativeArray!(T)) {
				DumlConstructField key, value;
				key = grabField!(KeyType!T, U, "")(data);
				value = grabField!(ValueType!T, U, "")(data);
				
				ret = DumlConstructField(m, DumlConstructName(value.type.ofModule, T.stringof ~ (isPtr ? "*" : ""), value.type.fullyQuallified ~ "[" ~ key.type.fullyQuallified ~ "]" ~ (isPtr ? "*" : "")));
				
				if (is(KeyType!T == class) || is(KeyType!T == struct) || is(KeyType!T == union) || is(KeyType!T == interface)) {
					static if (!is(U == KeyType!T)) {
						data.referencedClasses[key.type.fullyQuallified] = key.type;
						data.callerClasses[fullyQualifiedName!(KeyType!T)] = &registerType!(KeyType!T);
					}
				}
				if (is(ValueType!T == class) || is(ValueType!T == struct) || is(ValueType!T == union) || is(ValueType!T == interface)) {
					static if (!is(U == ValueType!T)) {
						data.referencedClasses[value.type.fullyQuallified] = value.type;
						data.callerClasses[fullyQualifiedName!(ValueType!T)] = &registerType!(ValueType!T);
					}
				}
			} else static if (__traits(compiles, {string mname = moduleName!T; })) {
				ret = DumlConstructField(m, DumlConstructName(moduleName!T, __traits(identifier, T), fullyQualifiedName!T));
				
				static if (is(T == class) || is(T == struct) || is(T == union) || is(T == interface)) {
					static if (!is(U == T) && !__traits(isSame, T, U)) {
						data.referencedClasses[ret.type.fullyQuallified] = ret.type;
						data.callerClasses[fullyQualifiedName!T] = &registerType!T;
					}
				}
			}
		}
	}
	ret.type.ofClass = ret.type.ofClass.replace("(", " ").replace(")", " ");
	ret.type.fullyQuallified = ret.type.fullyQuallified.replace("(", " ").replace(")", " ");
	
	return ret;
}

pure bool isUsable(C, string m)() {
	C c = newValueOfType!C;
	
	static if (__traits(compiles, {auto value = typeof(mixin("c." ~ m)).init;}) || __traits(compiles, {bool isa = isArray!(typeof(mixin("c." ~ m)));})) {
		static if (!__traits(hasMember, Object, m) &&
		           !isSomeFunction!(mixin("c." ~ m)) &&
		           !(m.length >= 2 && m[0 .. 2] == "op") &&
		           !__traits(isVirtualMethod, mixin("c." ~ m))) {
			
			return true;
		} else {
			return false;
		}
	} else {
		return false;
	}
}

pure T newValueOfType(T)() {
	static if (isAnObjectType!T) {
		static if (__traits(compiles, {T value = new T();})) {
			return new T();
		} else static if (__traits(compiles, {T value = new T;})) {
			return new T;
		} else {
			return T.init;
		}
	} else {
		return T.init;
	}
}

pure bool isAnObjectType(T)() {
	return is(T : Object) || is(T == struct) || is(T == union);
}

pure string replace(string text, string oldText, string newText, bool caseSensitive = true, bool first = false) {
	string ret;
	string tempData;
	bool stop;
	foreach(char c; text) {
		if (tempData.length > oldText.length && !stop) {
			ret ~= tempData;
			tempData = "";
		}
		if (((oldText[0 .. tempData.length] != tempData && caseSensitive) || (oldText[0 .. tempData.length].toLower() != tempData.toLower() && !caseSensitive)) && !stop) {
			ret ~= tempData;
			tempData = "";
		}
		tempData ~= c;
		if (((tempData == oldText && caseSensitive) || (tempData.toLower() == oldText.toLower() && !caseSensitive)) && !stop) {
			ret ~= newText;
			tempData = "";
			stop = first;
		}
	}
	if (tempData != "") {
		ret ~= tempData;	
	}
	return ret;
}
