module dud.options;

import std.getopt;
import std.traits : FieldNameTuple;

private struct OptionUDA {
	string s;
	string l;
	string documentation;
}

private template buildSelector(alias thing) {
	enum attr = __traits(getAttributes, thing);
	static if(attr.length == 1) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		static if(is(FirstType == OptionUDA)) {

			static assert(First.s.length == 1 || First.s.length == 0);
			static assert(First.l.length > 1 || First.l.length == 0);

			static if(First.s.length > 0 && First.l.length > 0) {
				enum buildSelector = First.s ~ "|" ~ First.l;
			} else static if(First.s.length == 0 && First.l.length > 0) {
				enum buildSelector = First.l;
			} else static if(First.s.length > 0 && First.l.length == 0) {
				enum buildSelector = First.s;
			} else {
				enum buildSelector = "";
			}
		}
	} else {
		enum buildSelector = "";
	}
}

struct OptionReturn(Option) {
	const Option options;
	const CommonOptions common;
}

void getOptions(T)(ref T t, ref string[] args) {
	static foreach(mem; FieldNameTuple!T) {
		getopt(args, "No explanatio here",
			buildSelector!(__traits(getMember, T, mem)),
			&__traits(getMember, t, mem));
	}
}

OptionReturn!ConvertOptions getConvertOptions(ref string[] args) {
	ConvertOptions conv;
	getOptions(conv, args);

	CommonOptions common = getCommonOptions(args);

	return OptionReturn!(ConvertOptions)(conv, common);
}

enum ConvertTargetFormat {
	undefined,
	sdl,
	json
}

struct ConvertOptions {
	@OptionUDA("i", "input", "The filename of the dub file to convert")
	string inputFilename;

	@OptionUDA("o", "output", "The filename of the output")
	string outputFilename;

	@OptionUDA("f", "format", "The type to convert to")
	ConvertTargetFormat outputTargetType;
}

struct CommonOptions {
	@OptionUDA("h", "help", "Display general or command specific help")
	bool help;

	@OptionUDA("v", "verbose", "Print diagnostic output")
	bool verbose;

	@OptionUDA("", "vverbose", "Print debug output")
	bool vverbose;
}

CommonOptions getCommonOptions(ref string[] args) {
	CommonOptions com;
	getOptions(com, args);
	return com;
}
