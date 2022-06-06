module CPUblit.drawing.bezier;

import inteli.emmintrin;
import std.math;

import CPUblit.colorspaces;

import CPUblit.drawing.common;

import CPUblit.drawing.line;
/*
 * Functions for drawing quadratic and cubic Bézier curves.
 *
 * Points are in [x,y] format.
 */
/** 
 * Draws a quadratic bezier curve by segments.
 * Params:
 *   p0 = Point 0 of the quadratic Bézier.
 *   p1 = Point 1 of the quadratic Bézier.
 *   p2 = Point 2 of the quadratic Bézier.
 *   color = The color, which the Bézier must be drawn with
 *   dest = Destination image/buffer.
 *   destWidth = Width of destination image/buffer.
 *   segments = How many segments should the curve have. A value of 1 will just connect the beginning and end points, 
 * a high-enough value will essentially draw the line pixel-by-pixel.
 */
public void quadraticBezier(T)(__m128d p0, __m128d p1, __m128d p2, T color, T[] dest, size_t destWidth, int segments) 
		@safe @nogc nothrow pure {
	const double tFract = 1.0 / segments;
	__m128d from = p0, to;
	for (int i ; i < segments ; i++) {
		const double tF = tFract * i, tT = tFract * (i + 1);
		/* __m128d from = __m128d(pow(1 - tF, 2)) * p0 + __m128d(2) * __m128d(1 - tF) * p1 + __m128d(pow(tF, 2)) * p2; */
		/* __m128d */ 
		/* to = __m128d(pow(1 - tT, 2)) * p0 + __m128d(2) * __m128d(1 - tT) * p1 + __m128d(pow(tT, 2)) * p2; */
		to = p1 + (__m128d(pow(1 - tT, 2)) * (p0 - p1)) + (__m128d(pow(tT, 2)) * (p2 - p1));
		drawLine(cast(int)nearbyint(from[0]), cast(int)nearbyint(from[1]), cast(int)nearbyint(to[0]), 
				cast(int)nearbyint(to[1]), color, dest, destWidth);
		from = to;
	}
}
/** 
 * Draws a cubic bezier curve by segments.
 * Params:
 *   p0 = Point 0 of the cubic Bézier.
 *   p1 = Point 1 of the cubic Bézier.
 *   p2 = Point 2 of the cubic Bézier.
 *   p3 = Point 3 of the cubic Bézier.
 *   color = The color, which the Bézier must be drawn with
 *   dest = Destination image/buffer.
 *   destWidth = Width of destination image/buffer.
 *   segments = How many segments should the curve have. A value of 1 will just connect the beginning and end points, 
 * a high-enough value will essentially draw the line pixel-by-pixel.
 */
public void cubicBezier(T)(__m128d p0, __m128d p1, __m128d p2, __m128d p3, T color, T[] dest, size_t destWidth, 
		int segments) @safe @nogc nothrow pure {
	const double tFract = 1.0 / segments;
	__m128d from = p0, to;
	for (int i ; i < segments ; i++) {
		const double /* tF = tFract * i, */ tT = tFract * (i + 1);
		/* __m128d from = __m128d(pow(1 - tF, 3)) * p0 + __m128d(3) * __m128d(pow(1 - tF, 2)) * __m128d(tF) * p1 + 
				__m128d(3) * __m128d(1 - tF) * __m128d(pow(tF, 2)) * p2 + __m128d(pow(tF, 3)) * p3; */
		/* __m128d */ 
		to = __m128d(pow(1 - tT, 3)) * p0 + __m128d(3) * __m128d(pow(1 - tT, 2)) * __m128d(tT) * p1 +
				__m128d(3) * __m128d(1 - tT) * __m128d(pow(tT, 2)) * p2 + __m128d(pow(tT, 3)) * p3;
		drawLine(cast(int)nearbyint(from[0]), cast(int)nearbyint(from[1]), cast(int)nearbyint(to[0]), 
				cast(int)nearbyint(to[1]), color, dest, destWidth);
		from = to;
	}
}

unittest {
	//Use a small enough area (8x8), so it can be easily tested for things.
	import std.stdio;
	ubyte[] area;
	area.length = 64;
	writeln("Bezier ([0,0],[7,0],[7,7])");
	fillWithSingleValue(area, cast(ubyte)'-');
	quadraticBezier(__m128d([0,0]), __m128d([7,0]), __m128d([7,7]),cast(ubyte)'X',area, 8, 5);
	printMatrix(cast(char[])area, 8);
	writeln("Bezier ([0,0],[0,7],[7,7])");
	fillWithSingleValue(area, cast(ubyte)'-');
	quadraticBezier(__m128d([0,0]), __m128d([0,7]), __m128d([7,7]),cast(ubyte)'X',area, 8, 5);
	printMatrix(cast(char[])area, 8);
	writeln("Bezier ([0,0],[7,7],[0,7])");
	fillWithSingleValue(area, cast(ubyte)'-');
	quadraticBezier(__m128d([0,0]), __m128d([7,7]), __m128d([0,7]),cast(ubyte)'X',area, 8, 7);
	printMatrix(cast(char[])area, 8);
	writeln("Bezier ([0,0],[0,7],[7,7],[7,0])");
	fillWithSingleValue(area, cast(ubyte)'-');
	cubicBezier(__m128d([0,0]), __m128d([0,7]), __m128d([7,7]), __m128d([7,0]),cast(ubyte)'X',area, 8, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Bezier ([0,0],[7,7],[0,7],[7,0])");
	fillWithSingleValue(area, cast(ubyte)'-');
	cubicBezier(__m128d([0,0]), __m128d([7,7]), __m128d([0,7]), __m128d([7,0]),cast(ubyte)'X',area, 8, 13);
	printMatrix(cast(char[])area, 8);
	writeln("Bezier ([0,0],[7,0],[0,7],[7,7])");
	fillWithSingleValue(area, cast(ubyte)'-');
	cubicBezier(__m128d([0,0]), __m128d([7,0]), __m128d([0,7]), __m128d([7,7]),cast(ubyte)'X',area, 8, 13);
	printMatrix(cast(char[])area, 8);
}
/*
RANT:

While it's technically possible to draw Bézier curves pixel-by-pixel, getting hold of the actual mathematical formula 
of it is impossible. Most of the time I only hear people suggesting me to just use a library that already has it, and
when I mention that D doesn't have many libraries, I get the suggestion of switching to a trendier, more popular one,
that forces you to write in functional style, because currently that's the hot new thing in programming.

To FP fans: I often use FP paradigms, but completely ditching an imperfect paradigm for another isn't going to play out
well. Just because some idiot doing OOP badly doesn't mean all OOP is bad, and I'm pretty sure that we will see a lot
of jank in FP too. I cannot wait for all the morons that pass around the program state between functions instead of 
using atoms!
*/