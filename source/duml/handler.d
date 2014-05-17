module duml.handler;
import duml.defs;
import std.traits : moduleName, BaseTypeTuple, isAbstractClass, FieldTypeTuple, isSomeFunction, ReturnType, isBasicType, isArray, isAssociativeArray, ParameterIdentifierTuple, ParameterTypeTuple, fullyQualifiedName, KeyType, ValueType;

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
			ret.fields ~= grabField!(typeof(mixin("t." ~ m)), T, m)(ret);
		} else {
			static if (__traits(compiles, typeof(mixin("t." ~ m))) && implementedName!(T, m)) {
				// method
				DumlConstructMethod method;
				method.name = m;
				alias names = ParameterIdentifierTuple!(mixin("t." ~ m));
				
				foreach(i, v; ParameterTypeTuple!(typeof(mixin("t." ~ m)))) {
					method.arguments ~= grabField!(v, T, names[i])(ret);
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

pure DumlConstructField grabField(T, U, string m, T t = T.init)(ref DumlConstruct data) {
	DumlConstructField ret;
	static if (T.stringof != typeof(null).stringof) {
		static if (isBasicType!(T)) {
			ret = DumlConstructField(m, DumlConstructName("", T.stringof, fullyQualifiedName!T));
			
			if (is(T == class) || is(T == struct) || is(T == union) || is(T == interface))
				static if (!is(U == T))
					data.referencedClasses[ret.type.fullyQuallified] = ret.type;
		} else static if (isArray!(T)) {
			foreach(e; [t.init]) {
				ret = DumlConstructField(m, DumlConstructName("", typeof(e).stringof, fullyQualifiedName!(typeof(e))));
			}
			
			if (is(T == class) || is(T == struct) || is(T == union) || is(T == interface) || is(T == interface))
				static if (!is(U == T))
					data.referencedClasses[ret.type.fullyQuallified] = ret.type;
		} else static if (isAssociativeArray!(T)) {
			DumlConstructField key, value;
			key = grabField!(KeyType!T, U, "")(data);
			value = grabField!(ValueType!T, U, "")(data);
			
			ret = DumlConstructField(m, DumlConstructName(value.type.ofModule, T.stringof, value.type.fullyQuallified ~ "[" ~ key.type.fullyQuallified ~ "]"));
			
			if (is(KeyType!T == class) || is(KeyType!T == struct) || is(KeyType!T == union) || is(KeyType!T == interface))
				static if (!is(U == KeyType!T))
					data.referencedClasses[key.type.fullyQuallified] = key.type;
			if (is(ValueType!T == class) || is(ValueType!T == struct) || is(ValueType!T == union) || is(ValueType!T == interface))
				static if (!is(U == ValueType!T))
					data.referencedClasses[value.type.fullyQuallified] = value.type;
		} else {
			ret = DumlConstructField(m, DumlConstructName(moduleName!(T), T.stringof, fullyQualifiedName!T));
			
			if (is(T == class) || is(T == struct) || is(T == union) || is(T == interface))
				static if (!is(U == T))
					data.referencedClasses[ret.type.fullyQuallified] = ret.type;
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