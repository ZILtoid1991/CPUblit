module CPUblit.colorlookup;
/**
 * CPUblit
 * Color look-up and planar to chunky (coming soon) conversion functions.
 */


public import CPUblit.colorspaces;
import bitleveld.datatypes;
/**
 * Converts an indexed image of type T (eg. ubyte, ushort) into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 */
public void colorLookup(T, U)(T* src, U* dest, U* palette, size_t length) @nogc pure nothrow {
	while(length){
		*dest = palette[*src];
		src++;
		dest++;
		length--;
	}
}
/**
 * Converts a 4 Bit indexed image into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 * Word order is: 0xF0 even, 0x0F odd.
 */
public void colorLookup4Bit(U)(ubyte* src, U* dest, U* palette, size_t length, int offset = 0) @nogc pure nothrow {
	colorLookup4Bit!(NibbleArray)(NibbleArray(src[0..length/2], length), dest, palette, offset);
}
/**
 * Converts a 4 Bit indexed image into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 * Uses a NibbleArray as a backend.
 */
public void colorLookup4Bit(T,U)(T src, U* dest, U* palette, int offset = 0) @nogc pure nothrow
		if(T.mangleof == NibbleArray.mangleof || T.mangleof == NibbleArrayR.mangleof) {
	for ( ; offset < src.length ; offset++) {
		*dest = palette[src[offset]];
		dest++;
	}
}
/**
 * Converts a 2 Bit indexed image into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 * Word order is: 0: 0b11_00_00_00 1: 0b00_11_00_00 2: 0b00_00_11_00 3: 0b00_00_00_11
 */
public void colorLookup2Bit(U)(ubyte* src, U* dest, U* palette, size_t length, int offset = 0) @nogc pure nothrow {
	colorLookup2Bit!(QuadArray)(QuadArray(src[0..length/4]), dest, palette, offset);
}
/**
 * Converts a 2 Bit indexed image into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 * Uses a QuadArray as a backend.
 */
public void colorLookup2Bit(T,U)(T src, U* dest, U* palette, int offset = 0) @nogc pure nothrow 
		if(T.mangleof == QuadArray.mangleof || T.mangleof == QuadArrayR.mangleof){
	for ( ; offset < src.length ; offset++){
		*dest = palette[src[offset]];
		dest++;
	}
}
@nogc pure nothrow unittest {
	ubyte[256] a, b;
	uint[256] c, d;
	ushort[256] e;
	colorLookup(a.ptr, c.ptr, d.ptr, 255);
	colorLookup(e.ptr, c.ptr, d.ptr, 255);
	colorLookup2Bit(a.ptr, c.ptr, d.ptr, 255, 1);
	colorLookup2Bit(a.ptr, c.ptr, d.ptr, 255, 0);
	colorLookup4Bit(a.ptr, c.ptr, d.ptr, 254, 1);
	colorLookup4Bit(a.ptr, c.ptr, d.ptr, 254, 0);
}