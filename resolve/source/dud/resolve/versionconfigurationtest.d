module dud.resolve.versionconfigurationtest;

@safe pure:

import dud.resolve.versionconfiguration;
import dud.resolve.conf;
import dud.resolve.confs;
import dud.resolve.positive;
import dud.semver.semver;
import dud.semver.setoperation;
import dud.semver.parse;
import dud.semver.versionunion;
import dud.semver.versionrange;

import std.format : format;
import std.stdio;

private:

immutable SemVer s10 = SemVer(1,0,0);
immutable SemVer s15 = SemVer(1,5,0);
immutable SemVer s20 = SemVer(2,0,0);
immutable SemVer s25 = SemVer(2,5,0);
immutable SemVer s30 = SemVer(3,0,0);

immutable allS = [s10, s15, s20, s25, s30];

immutable Conf c1 = Conf("", IsPositive.yes);
immutable Conf c2 = Conf("", IsPositive.no);
immutable Conf c3 = Conf("foo", IsPositive.yes);
immutable Conf c4 = Conf("foo", IsPositive.no);
immutable Conf c5 = Conf("bar", IsPositive.yes);
immutable Conf c6 = Conf("bar", IsPositive.no);

immutable allC = [c1, c2, c3, c4, c5, c6];

VerConGen verConGen(uint seed) {
	import std.random : Random;

	VerConGen ret;
	ret.rnd = Random(seed);
	return ret;
}

struct VerConGen {
@safe pure:
	import std.random : Random, uniform, randomCover;
	import std.algorithm.iteration : map;
	import std.range : take, iota;
	import std.array : array;
	Random rnd;

	bool empty;
	VersionConfiguration front;

	VersionRange newVersionRange() {
		const sl = uniform(0, allS.length - 1, this.rnd);
		const sh = uniform(sl, allS.length, this.rnd);
		return VersionRange(
				allS[sl],
				uniform(0, 100, this.rnd) < 50 && sl != sh
					? Inclusive.no
					: Inclusive.yes,
				allS[sh],
				uniform(0, 100, this.rnd) < 50 && sl != sh
					? Inclusive.no
					: Inclusive.yes);
	}

	void popFront() {
		const cl = uniform(1, 4, this.rnd);
		const vrC = uniform(1, 3, this.rnd);

		const vrs = iota(vrC).map!(it => newVersionRange()).array;

		this.front = VersionConfiguration(
			vrs.VersionUnion,
			allC.randomCover(this.rnd).take(cl).array.Confs);

	}
}

immutable vc1 = VersionConfiguration(
		VersionUnion([VersionRange(s15, Inclusive.yes, s25, Inclusive.yes)]),
		Confs([c1, c3]));

immutable vc2 = VersionConfiguration(
		VersionUnion([VersionRange(s15, Inclusive.yes, s25, Inclusive.yes)]),
		Confs([c3]));

immutable vc3 = VersionConfiguration(
		VersionUnion([VersionRange(s15, Inclusive.yes, s25, Inclusive.yes)]),
		Confs([c1]));

immutable vc4 = VersionConfiguration(
		VersionUnion([VersionRange(s20, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c1, c3]));

immutable vc5 = VersionConfiguration(
		VersionUnion([VersionRange(s10, Inclusive.yes, s15, Inclusive.yes)]),
		Confs([c1, c3]));

immutable vc6 = VersionConfiguration(
		VersionUnion([VersionRange(s25, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c1, c3]));

immutable vc7 = VersionConfiguration(
		VersionUnion([VersionRange(s25, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c1, c4]));

immutable vc8 = VersionConfiguration(
		VersionUnion([VersionRange(s25, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c3]));

immutable vc9 = VersionConfiguration(
		VersionUnion([VersionRange(s25, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c1]));

immutable vcA = VersionConfiguration(
		VersionUnion([VersionRange(s25, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c5]));

// allowsAll

unittest {
	assert(allowsAll(vc9, vc8));
	assert(allowsAll(vc9, vc9));
	assert(allowsAll(vc9, vcA));
}

unittest {
	assert(!allowsAll(vc6, vc1));
	assert(!allowsAll(vc6, vc2));
	assert(!allowsAll(vc6, vc3));
	assert(!allowsAll(vc6, vc4));
	assert(!allowsAll(vc6, vc5));
	assert(!allowsAll(vc6, vc6));

	assert(!allowsAll(vc5, vc1));
	assert(!allowsAll(vc5, vc2));
	assert(!allowsAll(vc5, vc3));
	assert(!allowsAll(vc5, vc4));
	assert(!allowsAll(vc5, vc5));
	assert(!allowsAll(vc5, vc6));

	assert(!allowsAll(vc4, vc1));
	assert(!allowsAll(vc4, vc2));
	assert(!allowsAll(vc4, vc3));
	assert(!allowsAll(vc4, vc4));
	assert(!allowsAll(vc4, vc5));
	assert(!allowsAll(vc4, vc6));

	assert( allowsAll(vc3, vc1));
	assert( allowsAll(vc3, vc2));
	assert( allowsAll(vc3, vc3));
	assert(!allowsAll(vc3, vc4));
	assert(!allowsAll(vc3, vc5));
	assert(!allowsAll(vc3, vc6));

	assert(!allowsAll(vc2, vc1));
	assert( allowsAll(vc2, vc2));
	assert(!allowsAll(vc2, vc3));
	assert(!allowsAll(vc2, vc4));
	assert(!allowsAll(vc2, vc5));
	assert(!allowsAll(vc2, vc6));

	assert(!allowsAll(vc1, vc1));
	assert( allowsAll(vc1, vc2));
	assert(!allowsAll(vc1, vc3));
	assert(!allowsAll(vc1, vc4));
	assert(!allowsAll(vc1, vc5));
	assert(!allowsAll(vc1, vc6));
}

// allowsAny

unittest {
	assert( allowsAny(vc6, vc1));
	assert( allowsAny(vc6, vc2));
	assert( allowsAny(vc6, vc3));
	assert( allowsAny(vc6, vc4));
	assert(!allowsAny(vc6, vc5));
	assert( allowsAny(vc6, vc6));

	assert( allowsAny(vc5, vc1));
	assert( allowsAny(vc5, vc2));
	assert( allowsAny(vc5, vc3));
	assert(!allowsAny(vc5, vc4));
	assert( allowsAny(vc5, vc5));
	assert(!allowsAny(vc5, vc6));

	assert( allowsAny(vc4, vc1));
	assert( allowsAny(vc4, vc2));
	assert( allowsAny(vc4, vc3));
	assert( allowsAny(vc4, vc4));
	assert(!allowsAny(vc4, vc5));
	assert( allowsAny(vc4, vc6));

	assert( allowsAny(vc3, vc1));
	assert(!allowsAny(vc3, vc2));
	assert( allowsAny(vc3, vc3));
	assert( allowsAny(vc3, vc4));
	assert( allowsAny(vc3, vc5));
	assert( allowsAny(vc3, vc6));

	assert( allowsAny(vc2, vc1));
	assert( allowsAny(vc2, vc2));
	assert( allowsAny(vc2, vc3));
	assert( allowsAny(vc2, vc4));
	assert( allowsAny(vc2, vc5));
	assert( allowsAny(vc2, vc6));

	assert( allowsAny(vc1, vc1));
	assert( allowsAny(vc1, vc2));
	assert( allowsAny(vc1, vc3));
	assert( allowsAny(vc1, vc4));
	assert( allowsAny(vc1, vc5));
	assert( allowsAny(vc1, vc6));
}

unittest {
	import std.range : take;
	auto r1 = verConGen(1337);
	auto r2 = verConGen(1338);
	foreach(it; take(r1, 1000)) {
		foreach(jt; take(r2, 1000)) {
			const al = allowsAll(it, jt);
			if(al) {
				assert(allowsAny(it, jt), format("\nit: %s\njt: %s", it, jt));
			}
		}
	}
}

// intersectionOf


/+
void testRelation(const(VersionConfiguration) a, const(VersionConfiguration) b,
		const(SetRelation) exp, int line = __LINE__)
{
	import std.exception : enforce;
	import core.exception : AssertError;
	const(SetRelation) rslt = relation(a, b);
	enforce!AssertError(rslt == exp,
		format("\na: %s\nb: %s\nexp: %s\nrsl: %s", a, b, exp, rslt),
		__FILE__, line);

}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
				, Confs([Conf("", IsPositive.yes)])
			);
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.no)])
				, Confs([Conf("", IsPositive.yes)])
			);
	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, c, Inclusive.no)])
				, Confs([Conf("", IsPositive.yes)])
			);
	auto v4 = VersionConfiguration(
			VersionUnion([VersionRange(b, Inclusive.yes, c, Inclusive.no)])
				, Confs([Conf("", IsPositive.yes)])
			);

	testRelation(v1, v2, SetRelation.overlapping);
	testRelation(v1, v3, SetRelation.subset);
	testRelation(v2, v4, SetRelation.disjoint);
	testRelation(v1, v4, SetRelation.overlapping);
}

__EOF__

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
			, Confs([Conf("conf1", IsPositive.yes)]));
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.no)])
			, Confs([Conf("", IsPositive.yes)]));
	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
			, Confs([Conf("conf2", IsPositive.yes)]));

	testRelation(v1, v1, SetRelation.subset);
	testRelation(v1, v2, SetRelation.overlapping);
	testRelation(v1, v3, SetRelation.disjoint);

	testRelation(v2, v1, SetRelation.subset);
	testRelation(v2, v2, SetRelation.subset);
	testRelation(v2, v3, SetRelation.subset);

	testRelation(v3, v1, SetRelation.disjoint);
	testRelation(v3, v2, SetRelation.overlapping);
	testRelation(v3, v3, SetRelation.subset);
}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ])
			, Confs([Conf("", IsPositive.yes)])
		);

	auto v2 = v1.invert();
	assert(relation(v1, v2) == SetRelation.disjoint);
}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, e, Inclusive.yes)])
			, Confs([Conf("conf1", IsPositive.yes)]));
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(b, Inclusive.yes, c, Inclusive.no)])
			, Confs([Conf("", IsPositive.yes)]));

	auto v12 = intersectionOf(v1, v2);
	debug writeln(v12);
	testRelation(v1, v12, SetRelation.overlapping);
	testRelation(v2, v12, SetRelation.overlapping);

	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(d, Inclusive.yes, e, Inclusive.no)])
			, Confs([Conf("conf1", IsPositive.yes)]));
	testRelation(v3, v12, SetRelation.subset);
	testRelation(v12, v3, SetRelation.subset);
}
+/
