module CPUblit.drawing.foodfill;

import CPUblit.colorspaces;

import CPUblit.drawing.common;

/** 
 * Implements a recursive scanline flood fill algorithm.
 * Params:
 *   x0 = X position of where the flood fill should happen.
 *   y0 = Y position of where the flood fill should happen.
 *   color = The color index to be written.
 *   dest = The destination buffer/image.
 *   destWidth = The width of the destination buffer/image.
 *   transparencyIndex = The index to be replace.
 */
public void floodFill(T)(int x0, int y0, T color, T[] dest, size_t destWidth, T transparencyIndex = T.init) 
		@nogc @safe nothrow pure {
	const size_t destHeight = dest.length / destWidth;
	void _fillLine(int x0, int y0) @nogc nothrow pure {
		if (dest[x0 + (y0 * destWidth)] != transparencyIndex) return;
		int x = x0;
		//Fill line to the right
		while (x < destWidth && dest[x + (y0 * destWidth)] == transparencyIndex) {
			dest[x + (y0 * destWidth)] = color;
			x++;
		}
		x = x0 - 1;
		//Fill line to the left
		while (x >= 0 && dest[x + (y0 * destWidth)] == transparencyIndex) {
			dest[x + (y0 * destWidth)] = color;
			x--;
		}
		x++;
		//Test for scanlines above
		if (y0 > 0) {
			while (x < destWidth && dest[x + (y0 * destWidth)] == color) {
				if (dest[x + ((y0 - 1) * destWidth)] == transparencyIndex) {
					_fillLine(x, y0 - 1);
				}
				x++;
			}
		}
		x--;
		//Test for scanlines below
		if (y0 + 1 < destHeight) {
			while (x < destWidth && dest[x + (y0 * destWidth)] == color) {
				if (dest[x + ((y0 + 1) * destWidth)] == transparencyIndex) {
					_fillLine(x, y0 + 1);
				}
				x--;
			}
		}
	}
	_fillLine(x0, y0);
}
unittest {
	import std.stdio;
	ubyte[] area;
	area.length = 64;
	floodFill(0,0,0x0, area, 8);
	area = [
		0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
		0x0,0x0,0x3,0x3,0x3,0x3,0x0,0x0,
		0x0,0x3,0x0,0x0,0x0,0x0,0x3,0x0,
		0x0,0x3,0x0,0x0,0x0,0x0,0x3,0x0,
		0x0,0x3,0x0,0x0,0x0,0x0,0x3,0x0,
		0x0,0x3,0x0,0x0,0x0,0x0,0x3,0x0,
		0x0,0x0,0x3,0x3,0x3,0x3,0x0,0x0,
		0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	];
	floodFill(3,3,0x4, area, 8);
	printMatrix(area, 8);
}