module dud.pkgdescription.joining;

import std.array : array, empty, front;
import std.algorithm.searching : canFind, find;
import std.algorithm.sorting : sort;
import std.algorithm.iteration : uniq, filter, each;
import std.exception : enforce;
import std.format : format;
import std.traits : FieldNameTuple;
import std.typecons : nullable, Nullable, apply;

import dud.pkgdescription;
import dud.pkgdescription.exception;
import dud.pkgdescription.compare;
import dud.pkgdescription.duplicate;
import dud.pkgdescription.duplicate : ddup = dup;

@safe:

PackageDescription expandConfiguration(ref const(PackageDescription) pkg,
		string confName)
{
	PackageDescription ret = pkg.ddup();
	() @trusted { ret.configurations.clear(); }();

	const(PackageDescription) conf = findConfiguration(pkg, confName);
	joinPackageDescription(ret, pkg, conf);
	return ret;
}

PackageDescription expandBuildType(ref const(PackageDescription) pkg,
		string buildTypeName)
{
	PackageDescription ret = pkg.ddup();
	const(BuildType) buildType = findBuildType(pkg, buildTypeName);
	joinPackageDescription(ret, pkg, buildType.pkg);
	return ret;
}

void joinPackageDescription(ref PackageDescription ret,
		ref const(PackageDescription) orig, ref const(PackageDescription) conf)
{
	import dud.pkgdescription.helper : isMem;
	static foreach(mem; FieldNameTuple!PackageDescription) {
		// override with conf
		static if(canFind(
			[ isMem!"systemDependencies", isMem!"ddoxTool", isMem!"platforms"
			, isMem!"buildOptions"
			], mem))
		{
			__traits(getMember, ret, mem) =
				dud.pkgdescription.duplicate.dup(
					__traits(getMember, conf, mem));
		} else static if(canFind(
			[ isMem!"targetPath", isMem!"targetName", isMem!"mainSourceFile"
			, isMem!"workingDirectory"
			], mem))
		{
			__traits(getMember, ret, mem) = selectIfEmpty(
				__traits(getMember, ret, mem),
				__traits(getMember, conf, mem));
		} else static if(canFind(
			[ isMem!"dflags", isMem!"lflags", isMem!"versions"
			, isMem!"importPaths", isMem!"sourcePaths", isMem!"sourceFiles"
			, isMem!"stringImportPaths" , isMem!"excludedSourceFiles"
			, isMem!"copyFiles" , isMem!"preGenerateCommands"
			, isMem!"postGenerateCommands" , isMem!"preBuildCommands"
			, isMem!"postBuildCommands" , isMem!"preRunCommands"
			, isMem!"postRunCommands", isMem!"libs", isMem!"versionFilters"
			, isMem!"debugVersionFilters", isMem!"debugVersions"
			, isMem!"toolchainRequirements", isMem!"dependencies"
			, isMem!"subConfigurations", isMem!"buildTypes"
			, isMem!"targetType"
			], mem))
		{
			__traits(getMember, ret, mem) =
				join(__traits(getMember, orig, mem),
						__traits(getMember, conf, mem));
		} else static if(canFind(
			[ isMem!"name", isMem!"description", isMem!"homepage"
			, isMem!"license", isMem!"authors"//, isMem!"version_"
			, isMem!"copyright", isMem!"subPackages"
			, isMem!"ddoxFilterArgs", isMem!"configurations"
			, isMem!"buildRequirements"
			], mem))
		{
			// global options not allowed to change by configuration
		} else {
			pragma(msg, mem);
		}
	}
}

String selectIfEmpty(const(String) a, const(String) b) {
	return b.platforms.empty
		? a.ddup()
		: b.ddup();
}

UnprocessedPath selectIfEmpty(const(UnprocessedPath) a,
		const(UnprocessedPath) b)
{
	return b.path.empty
		? a.ddup()
		: b.ddup();
}

Path selectIfEmpty(const(Path) a, const(Path) b) {
	return b.platforms.empty
		? a.ddup()
		: b.ddup();
}

string selectIfEmpty(const(string) a, const(string) b) {
	return b.empty
		? a.ddup()
		: b.ddup();
}

SubConfigs join(ref const(SubConfigs) a, ref const(SubConfigs) b) {
	SubConfigs ret = b.ddup();
	a.unspecifiedPlatform.byKeyValue()
		.filter!(kv => kv.key !in ret.unspecifiedPlatform)
		.each!(kv => ret.unspecifiedPlatform[kv.key] = kv.value);

	foreach(key, value; a.configs) {
		if(key !in ret.configs) {
			ret.configs[key] = string[string].init;
		}
		foreach(key2, value2; value) {
			if(key2 !in ret.configs[key]) {
				ret.configs[key][key2] = value2.ddup();
			}
		}
	}
	return ret;
}

BuildType[string] join(const(BuildType[string]) a,
		const(BuildType[string]) b)
{
	BuildType[string] ret = b.ddup();
	a.byKeyValue()
		.filter!(it => it.key !in ret)
		.each!(bt => ret[bt.key] = bt.value.ddup());
	return ret;
}

Dependency[] join(const(Dependency[]) a, const(Dependency[]) b) {
	Dependency[] ret = b.ddup();
	a.filter!(dep =>
			!canFind!((g, h) => g.name == h.name
				&& g.platforms == h.platforms)(ret, dep))
		.each!(dep => ret ~= dep.ddup());
	return ret;
}

ToolchainRequirement[Toolchain] join(const(ToolchainRequirement[Toolchain]) a,
		const(ToolchainRequirement[Toolchain]) b)
{
	ToolchainRequirement[Toolchain] ret = dud.pkgdescription.duplicate.dup(a);
	b.byKeyValue()
		.each!(it => ret[it.key] =
				dud.pkgdescription.duplicate.dup(it.value));
	return ret;
}

Paths join(const(Paths) a, const(Paths) b) {
	Paths ret = dud.pkgdescription.duplicate.dup(a);
	b.platforms
		.filter!(it =>
				!canFind!((g, h) => areEqual(g, h))(a.platforms, it))
		.each!(it => ret.platforms ~= dud.pkgdescription.duplicate.dup(it));
	return ret;
}

TargetType join(const(TargetType) a, const(TargetType) b) {
	return b != TargetType.autodetect
		? b
		: a;
}

Strings join(const(Strings) a, const(Strings) b) {
	Strings ret = dud.pkgdescription.duplicate.dup(a);
	b.platforms
		.filter!(it =>
				!canFind!((g, h) => areEqual(g, h))(a.platforms, it))
		.each!(it => ret.platforms ~= dud.pkgdescription.duplicate.dup(it));
	return ret;
}

string[] join(const(string[]) a, const(string[]) b) {
	string[] ret = (dud.pkgdescription.duplicate.dup(a)
			~ dud.pkgdescription.duplicate.dup(b)).sort.uniq.array;
	return ret;
}

//
// Helper
//

const(BuildType) findBuildType(const PackageDescription pkg,
	string buildTypeName)
{
	const(BuildType)* ret = buildTypeName in pkg.buildTypes;
	enforce!UnknownBuildType(ret !is null,
		format("'%s' is a unknown buildType of package '%s'", pkg.name));
	return *ret;
}

const(PackageDescription) findConfiguration(const PackageDescription pkg,
	string confName)
{
	const(PackageDescription)* ret = confName in pkg.configurations;
	enforce!UnknownConfiguration(ret !is null,
		format("'%s' is a unknown configuration of package '%s'", pkg.name));
	return *ret;
}
