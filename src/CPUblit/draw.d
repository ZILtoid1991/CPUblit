module CPUblit.draw;

import CPUblit.colorspaces;
/**
 * Draws a line using a fixed point method. Is capable of drawing lines diagonally.
 */
public void drawLine(T)(int x0, int y0, int x1, int y1, T color, T* dest, size_t destWidth) @nogc nothrow pure {
	if(x1 < x0){
		const int k = x1;
		x1 = x0;
		x0 = k;
	}
	if(y1 < y0){
		const int k = y1;
		y1 = y0;
		y0 = k;
	}
	const int dx = x1 - x0;
	const int dy = y1 - y0;
	if(!dx || !dy){
		if(!dy){
			sizediff_t offset = destWidth * y1;
			for(int x = x0; x <= x1; x++){
				dest[offset + x] = color;
			}
		}else{
			sizediff_t offset = destWidth * y0 + x0;
			for(int y = y0; y <= y1; y++){
				dest[offset] = color;
				offset += destWidth;
			}
		}
	}else if(dx>=dy){
		int D = 2*dy - dx;
		int y = y0;
		for(int x = x0 ; x <= x1 ; x++){
			dest[destWidth * y + x] = color;
			if(D > 0){
				y += 1;
				D -= 2 * dx;
			}
			D += 2 * dx;
		}
	}else{
		int D = 2 * dx - dy;
		int x = x0;
		for(int y = y0 ; y <= y1 ; y++){
			dest[destWidth * y + x] = color;
			if(D > 0){
				x += 1;
				D -= 2 * dy;
			}
			D += 2 * dy;
		}
	}
}
/**
 * Draws a line with the given pattern.
 */
public void drawLinePattern(T)(int x0, int y0, int x1, int y1, T[] pattern, T* dest, size_t destWidth) @nogc nothrow pure {
	if(x1 < x0){
		const int k = x1;
		x1 = x0;
		x0 = k;
	}
	if(y1 < y0){
		const int k = y1;
		y1 = y0;
		y0 = k;
	}
	const int dx = x1 - x0;
	const int dy = y1 - y0;
	size_t patternPos;
	if(!dx || !dy){
		if(!dy){
			sizediff_t offset = destWidth * y1;
			for(int x = x0 ; x <= x1 ; x++){
				dest[offset + x] = pattern[(patternPos++) % pattern.length];
				
			}
		}else{
			sizediff_t offset = destWidth * y0 + x0;
			for(int y = y0 ; y <= y1 ; y++){
				dest[offset] = pattern[(patternPos++) % pattern.length];
				
				offset += destWidth;
			}
		}
	}else if(dx>=dy){
		int D = 2 * dy - dx;
		int y = y0;
		for(int x = x0 ; x <= x1 ; x++){
			dest[destWidth * y + x] = pattern[(patternPos++) % pattern.length];
			//patternPos = patternPos + 1 < pattern.length ? patternPos + 1 : 0;
			if(D > 0){
				y += 1;
				D -= 2 * dx;
			}
			D += 2 * dx;
		}
	}else{
		int D = 2 * dx - dy;
		int x = x0;
		for(int y = y0 ; y <= y1 ; y++){
			dest[destWidth * y + x] = pattern[(patternPos++) % pattern.length];
			//patternPos = patternPos + 1 < pattern.length ? patternPos + 1 : 0;
			if(D > 0){
				x += 1;
				D -= 2 * dy;
			}
			D += 2 * dy;
		}
	}
}
/**
 * Draws a rectangle.
 */
public void drawRectangle(T)(int x0, int y0, int x1, int y1, T color, T*dest, size_t destWidth) @nogc nothrow pure {
	/+static if(!(T.stringof == "ubyte" || T.stringof == "ushort" || T.stringof == "uint" || T.stringof == "Color32Bit")) {
		static assert(0, "Template parameter '" ~ T.stringof ~ "' is not supported!");
	}+/
	drawLine(x0,y0,x0,y1,color,dest,destWidth);
	drawLine(x0,y0,x1,y0,color,dest,destWidth);
	drawLine(x1,y0,x1,y1,color,dest,destWidth);
	drawLine(x0,y1,x1,y1,color,dest,destWidth);
}
/**
 * Draws a filled rectangle.
 */
public void drawFilledRectangle(T) (int x0, int y0, int x1, int y1, T color, T* dest, size_t destWidth) @nogc nothrow 
		pure {
	import core.stdc.string : memset;
	import core.stdc.wchar_ : wmemset;
	if(x1 < x0){
		const int k = x1;
		x1 = x0;
		x0 = k;
	}
	if(y1 < y0){
		const int k = y1;
		y1 = y0;
		y0 = k;
	}
	int width = x1 - x0;
	dest += x0;
	for (int y = y0 ; y <= y1 ; y++) {
		static if (is(T == ubyte)) {
			memset(dest + (y * destWidth), color, width);
		} else static if (is(T == ushort)) {
			T* dest0 = dest + (y * destWidth);
			for (int x ; x < width ; x++) {
				dest0[x] = color;
			}
		} else static if (is(T == uint)) {
			wmemset(dest + (y * destWidth), color, width);
		}
	}
}
/**
 * Flood fills a bitmap at the given point.
 */
public void floodFill(T)(int x0, int y0, T color, T* dest, size_t destWidth, size_t destLength, 
		T transparencyIndex = T.init) @nogc nothrow pure {
	//check for boundaries of the bitmap
	if(x0 > 0 && y0 > 0){
		const size_t yOffset = y0 * destWidth;
		if(x0 < destWidth && yOffset < destLength){
			//check if the current pixel is "transparent"
			T* p = dest + yOffset + x0;
			if(transparencyIndex == *(p)){
				*p = color;
				floodFill(x0 + 1, y0, color, dest, destWidth, destLength, transparencyIndex);
				floodFill(x0 - 1, y0, color, dest, destWidth, destLength, transparencyIndex);
				floodFill(x0, y0 + 1, color, dest, destWidth, destLength, transparencyIndex);
				floodFill(x0, y0 - 1, color, dest, destWidth, destLength, transparencyIndex);
			}
		}
	}
}
unittest{
	import std.conv : to;
	{	//test if only the first line is being drawn.
		ubyte[256*256] virtualImage;
		drawLine(0, 0, 255, 0, 0xFF, virtualImage.ptr, 256);
		for(int x ; x < 256 ; x++){
			assert(virtualImage[x] == 0xFF);
		}
		for(int x ; x < 256 ; x++){
			assert(virtualImage[256 + x] == 0x00);
		}
	}
	{	//test if only the first row is being drawn.
		ubyte[256*256] virtualImage;
		drawLine(0, 0, 0, 255, 0xFF, virtualImage.ptr, 256);
		for(int y ; y < 256 ; y++){
			assert(virtualImage[256 * y] == 0xFF);
		}
		for(int y ; y < 256 ; y++){
			assert(virtualImage[(256 * y) + 1] == 0x00);
		}
	}
	{	//test if only the first line is being drawn.
		ubyte[256*256] virtualImage;
		ubyte[3] pattern = [0x20,0xFF,0x33];
		drawLinePattern(0, 0, 255, 0, pattern, virtualImage.ptr, 256);
		for(int x ; x < 256 ; x++){
			assert(virtualImage[x] == pattern[x%3], "Error at position " ~ to!string(x));
		}
		for(int x ; x < 256 ; x++){
			assert(virtualImage[256 + x] == 0x00);
		}
	}
	
}