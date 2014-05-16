module duml.handler;
import duml.defs;
import std.traits : moduleName, BaseTypeTuple, isAbstractClass, FieldTypeTuple, isSomeFunction, ReturnType, isBasicType, isArray, isAssociativeArray, ParameterIdentifierTuple, ParameterTypeTuple, fullyQualifiedName;

pure DumlConstruct handleRegistrationOfType(T, T t = T.init)() if (is(T == class) || __traits(isAbstractClass, T) || is(T == interface)) {
	DumlConstruct ret;
	
	ret.name = DumlConstructName(moduleName!T, __traits(identifier, T), fullyQualifiedName!T);
	
	foreach(i, iUsed; BaseTypeTuple!T) {
		static if (!is(iUsed == Object)) {
			static if (isAbstractClass!iUsed) {
				ret.extends = DumlConstructName(moduleName!iUsed, __traits(identifier, iUsed), fullyQualifiedName!iUsed);
			} else {
				ret.inheritsFrom ~= DumlConstructName(moduleName!iUsed, __traits(identifier, iUsed), fullyQualifiedName!iUsed);
			}
		}
	}
	
	version(DumlIgnoreObject) {
	} else static if (!is(T == Object)) {
		ret.inheritsFrom ~= DumlConstructName("object", "Object", fullyQualifiedName!Object);
	}
	
	foreach(m; __traits(allMembers, T)) {
		static if (isUsable!(T, m) && implementedName!(T, m)) {
			// field
			ret.fields ~= grabField!(typeof(mixin("t." ~ m)), m);
		} else {
			static if (__traits(compiles, typeof(mixin("t." ~ m))) && implementedName!(T, m)) {
				// method
				DumlConstructMethod method;
				method.name = m;
				alias names = ParameterIdentifierTuple!(mixin("t." ~ m));
				foreach(i, v; ParameterTypeTuple!(typeof(mixin("t." ~ m)))) {
					method.arguments ~= grabField!(v, names[i]);
				}
				
				ret.methods ~= method;
			}
		}
	}
	
	//...
	
	return ret;
}

pure bool implementedName(T, string n)() {
	foreach(name; __traits(derivedMembers, T)) {
		if (name == n)
			return true;
	}
	return false;
}

pure DumlConstructField grabField(T, string m, T t = T.init)() {
	DumlConstructField ret;
	static if (T.stringof != typeof(null).stringof) {
		static if (isBasicType!(T)) {
			ret = DumlConstructField(m, DumlConstructName("", T.stringof, fullyQualifiedName!T));
		} else static if (isArray!(T)) {
			foreach(e; [t.init]) {
				ret = DumlConstructField(m, DumlConstructName("", typeof(e).stringof, fullyQualifiedName!(typeof(e))));
			}
		} else static if (isAssociativeArray!(T)) {
			ret = DumlConstructField(m, DumlConstructName("", T.stringof, fullyQualifiedName!T));
		} else {
			ret = DumlConstructField(m, DumlConstructName(moduleName!(T), T.stringof, fullyQualifiedName!T));
		}
	}
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
	return is(T : Object) || is(T == struct);
}