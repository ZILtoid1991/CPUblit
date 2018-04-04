module CPUblit.draw;

import CPUblit.colorspaces;
/**
 * Draws a line using a fixed point method. Is capable of drawing lines diagonally.
 */
public @nogc void drawLine(T)(int x0, int y0, int x1, int y1, T color, T* dest, int destWidth){
	static if(!(T == "ubyte" || T == "ushort" || T == "Color32Bit")){
		static assert("Template parameter '" ~ T.stringof ~ "' is not supported!");
	}
	if(x1 < x0){
		int k = x1;
		x1 = x0;
		x0 = k;
	}
	if(y1 < y0){
		int k = y1;
		y1 = y0;
		y0 = k;
	}
	int dx = x1 - x0;
	int dy = y1 - y0;
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
		for(int x = x0; x <= x1; x++){
			dest[destWidth * y + x] = color;
			if(D > 0){
				y += 1;
				D -= 2*dx;
			}
			D += 2*dx;
		}
	}else{
		int D = 2*dx - dy;
		int x = x0;
		for(int y = y0; y <= y1; y++){
			dest[destWidth * y + x] = color;
			if(D > 0){
				x += 1;
				D -= 2*dy;
			}
			D += 2*dy;
		}
	}
}
/**
 * Draws a rectangle.
 */
public @nogc void drawRectangle(T)(int x0, int y0, int x1, int y1, T color, T*dest, int destWidth){
	static if(!(T == "ubyte" || T == "ushort" || T == "Color32Bit")){
		static assert("Template parameter '" ~ T.stringof ~ "' is not supported!");
	}
	drawLine(x0,y0,x0,y1,color,dest,destWidth);
	drawLine(x0,y0,x1,y0,color,dest,destWidth);
	drawLine(x1,y0,x1,y1,color,dest,destWidth);
	drawLine(x0,y1,x1,y1,color,dest,destWidth);
}
/**
 * Draws a filled rectangle.
 * TODO: Upgrade algorhithm to use SSE2/MMX for faster filling.
 */
public @nogc void drawFilledRectangle(T)(int x0, int y0, int x1, int y1, T color, T* dest, int destWidth){
	if(x1 < x0){
		int k = x1;
		x1 = x0;
		x0 = k;
	}
	if(y1 < y0){
		int k = y1;
		y1 = y0;
		y0 = k;
	}
	int targetWidth = y1 - y0;
	
	while(targetWidth){
		drawLine!T(x0, y0, x1, y0, color, dest, destWidth);
		targetWidth--;
	}
}