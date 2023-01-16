module CPUblit.drawing.line;

import CPUblit.colorspaces;

import CPUblit.drawing.common;

import std.math;

/*
 * Functions to draw straight lines, and filled and unfilled boxes.
 *
 * As of now, there are no functions that can do anti-aliasing.
 */
/** 
 * Draws a line using a fixed point method. Is capable of drawing lines diagonally.
 * Params:
 *   x0 = The X coordinate of the first point.
 *   y0 = The Y coordinate of the first point.
 *   x1 = The X coordinate of the second point.
 *   y1 = The Y coordinate of the second point.
 *   color = The color of the line.
 *   dest = Where the line should be drawn.
 *   destWidth = The width of the destination buffer, ideally divisible without remainder by dest.length.
 */
public void drawLine(T)(int x0, int y0, int x1, int y1, T color, T[] dest, size_t destWidth) @safe @nogc nothrow pure {
	if (x0 < 0 || x0 >= destWidth) return;
	if (x1 < 0 || x1 >= destWidth) return;
	if (y0 < 0 || y0 >= (dest.length / destWidth)) return;
	if (y1 < 0 || y1 >= (dest.length / destWidth)) return;
	const int dirX = x1 < x0 ? -1 : 1, dirY = y1 < y0 ? -1 : 1;
	const int dx = abs(x1 - x0);
	const int dy = abs(y1 - y0);
	if (!dx || !dy) {
		if (!dy) {
			const sizediff_t offset = (destWidth * y0) + x0;
			for (int x ; x <= dx ; x++) {
				dest[offset + (x * dirX)] = color;
			}
		} else {
			sizediff_t offset = destWidth * y0 + x0;
			for (int y ; y <= dy ; y++) {
				dest[offset] = color;
				offset += destWidth * dirY;
			}
		}
	} else if(dx>=dy) {
		const double yS = cast(double)dy / dx * dirY;
		double y = 0;
		const sizediff_t offset = destWidth * y0 + x0;
		for (int x ; x <= dx ; x++) {
			dest[offset + (x * dirX) + (cast(int)nearbyint(y) * destWidth)] = color;
			y += yS;
		}
	} else {
		const double xS = cast(double)dx / dy * dirX;
		double x = 0;
		sizediff_t offset = destWidth * y0 + x0;
		for (int y ; y <= dy ; y++) {
			dest[offset + cast(int)nearbyint(x)] = color;
			offset += destWidth * dirY;
			x += xS;
		}
	}
}
/** 
 * Draws a line with the given pattern. Is capable of drawing lines diagonally.
 * NOTE: The way this function operates will shear lines with patterns.
 * Params:
 *   x0 = The X coordinate of the first point.
 *   y0 = The Y coordinate of the first point.
 *   x1 = The X coordinate of the second point.
 *   y1 = The Y coordinate of the second point.
 *   pattern = The pattern that should be used when drawing the line.
 *   dest = Where the line should be drawn.
 *   destWidth = The width of the destination buffer, ideally divisible without remainder by dest.length.
 */
public void drawLinePattern(T)(int x0, int y0, int x1, int y1, T[] pattern, T[] dest, size_t destWidth) 
		@safe @nogc nothrow pure {
	if (x0 < 0 || x0 >= destWidth) return;
	if (x1 < 0 || x1 >= destWidth) return;
	if (y0 < 0 || y0 >= (dest.length / destWidth)) return;
	if (y1 < 0 || y1 >= (dest.length / destWidth)) return;
	const int dirX = x1 < x0 ? -1 : 1, dirY = y1 < y0 ? -1 : 1;
	const int dx = abs(x1 - x0);
	const int dy = abs(y1 - y0);
	size_t patternPos;
	if (!dx || !dy) {
		if (!dy) {
			const sizediff_t offset = (destWidth * y0) + x0;
			for (int x ; x <= dx ; x++) {
				dest[offset + (x * dirX)] = pattern[(patternPos++) % pattern.length];
			}
		} else {
			sizediff_t offset = destWidth * y0 + x0;
			for (int y ; y <= dy ; y++) {
				dest[offset] = pattern[(patternPos++) % pattern.length];
				offset += destWidth * dirY;
			}
		}
	} else if(dx>=dy) {
		const double yS = cast(double)dy / dx * dirY;
		double y = 0;
		const sizediff_t offset = destWidth * y0 + x0;
		for (int x ; x <= dx ; x++) {
			dest[offset + (x * dirX) + (cast(int)nearbyint(y) * destWidth)] = pattern[(patternPos++) % pattern.length];
			y += yS;
		}
	} else {
		const double xS = cast(double)dx / dy * dirX;
		double x = 0;
		sizediff_t offset = destWidth * y0 + x0;
		for (int y ; y <= dy ; y++) {
			dest[offset + cast(int)nearbyint(x)] = pattern[(patternPos++) % pattern.length];
			offset += destWidth * dirY;
			x += xS;
		}
	}
}
/**
 * Draws a rectangle.
 */
public void drawRectangle(T)(int x0, int y0, int x1, int y1, T color, T[] dest, size_t destWidth) 
		@safe @nogc nothrow pure {
	drawLine(x0,y0,x0,y1,color,dest,destWidth);
	drawLine(x0,y0,x1,y0,color,dest,destWidth);
	drawLine(x1,y0,x1,y1,color,dest,destWidth);
	drawLine(x0,y1,x1,y1,color,dest,destWidth);
}
public void drawFilledRectangle(T)(int x0, int y0, int x1, int y1, T color, T[] dest, size_t destWidth) 
		@trusted @nogc nothrow pure {
	assert(x0 >= 0 && x0 < destWidth);
	assert(x1 >= 0 && x1 < destWidth);
	assert(y0 >= 0 && y0 < dest.length / destWidth);
	assert(y1 >= 0 && y1 < dest.length / destWidth);
	_drawFilledRectangle(x0, y0, x1, y1, color, dest, destWidth);
}
/**
 * Draws a filled rectangle.
 */
public void _drawFilledRectangle(T) (int x0, int y0, int x1, int y1, T color, T[] dest, size_t destWidth) 
		@system @nogc nothrow pure {
	import core.stdc.string : memset;
	import core.stdc.wchar_ : wmemset;
	if (x1 < x0) {
		const int k = x1;
		x1 = x0;
		x0 = k;
	}
	if (y1 < y0) {
		const int k = y1;
		y1 = y0;
		y0 = k;
	}
	int width = x1 - x0 + 1;
	//dest += x0;
	for (int y = y0 ; y <= y1 ; y++) {
		static if (is(T == ubyte)) {
			memset(dest.ptr + (y * destWidth) + x0, color, width);
		} else static if (is(T == ushort)) {
			T* dest0 = dest + (y * destWidth);
			for (int x ; x < width ; x++) {
				dest0[x] = color;
			}
		} else static if (is(T == uint)) {
			wmemset(dest.ptr + (y * destWidth) + x0, color, width);
		}
	}
}

unittest {
	//Use a small enough area (8x8), so it can be easily tested for things.
	import std.stdio;
	ubyte[] area, pattern = [cast(ubyte)'X',cast(ubyte)'O'];
	area.length = 64;
	writeln("Horizontal line");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,7,0,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Vertical line");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,0,7,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal line 1");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,7,7,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal line 2");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,6,7,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal line 3");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,5,7,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal line 4");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,4,7,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal line 5");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(4,7,1,1,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal line 6");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLine(0,0,2,7,cast(ubyte)'X',area, 8);
	printMatrix(cast(char[])area, 8);

	writeln("Horizontal pattern line");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLinePattern(0,0,7,0,pattern,area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Vertical pattern line");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLinePattern(0,0,0,7,pattern,area, 8);
	printMatrix(cast(char[])area, 8);
	writeln("Diagonal pattern line");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawLinePattern(0,0,7,7,pattern,area, 8);
	printMatrix(cast(char[])area, 8);

	writeln("Empty Rectangle");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawRectangle(2,2,5,5,'O',area,8);
	printMatrix(cast(char[])area, 8);
	writeln("Filled Rectangle");
	fillWithSingleValue(area, cast(ubyte)'-');
	drawFilledRectangle(2,2,5,5,'O',area,8);
	printMatrix(cast(char[])area, 8);
}