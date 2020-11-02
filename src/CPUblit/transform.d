module CPUblit.transform;

import CPUblit.colorspaces;
import bitleveld.datatypes;

/**
 * Horizontal scaling using nearest integer algorithm for per-line operations.
 * Works with most datatypes. Use a separate one for 4 bit.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void horizontalScaleNearest(T)(T* src, T* dest, sizediff_t length, int trfmParam) @nogc pure nothrow {
	int trfmParamA = trfmParam;
	sizediff_t offset;
	length <<= 10;
	if(trfmParam < 0){
		offset += length-1024;
		trfmParamA *= -1;
	}
	while(length > 0){
		*dest = src[offset>>>10];
		offset += trfmParam;
		length -= trfmParamA;
		dest++;
	}
}
/**
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations.
 * Works with most datatypes. Use a separate one for 4 bit.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void horizontalScaleNearestAndCLU(T, U)(T* src, U* dest, U* palette, sizediff_t length, const int trfmParam)
		@nogc pure nothrow {
	int trfmParamA = trfmParam;
	sizediff_t offset;
	length <<= 10;
	if(trfmParam < 0){
		offset += length-1024;
		trfmParamA *= -1;
	}
	while(length > 0){
		*dest = palette[(src[offset>>>10])];
		offset += trfmParam;
		length -= trfmParamA;
		dest++;
	}
}
/**
 * Horizontal scaling using nearest integer algorithm for per-line operations.
 * Works with 4 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void horizontalScaleNearest4Bit(ubyte* src, ubyte* dest, sizediff_t length, sizediff_t offset, 
		const int trfmParam) @nogc pure nothrow {
	int trfmParamA = trfmParam;
	length <<= 10;
	offset <<= 10;
	if(trfmParam < 0){
		offset += length-1024;
		trfmParamA *= -1;
	}
	while(length > 0){
		const ubyte temp = (offset>>>10) & 1 ?  src[offset>>>11] & 0x0F : src[offset>>>11] >> 4;
		*dest |= length & 1 ? temp : temp << 4;
		offset += trfmParam;
		length -= trfmParamA;
		dest++;
	}
}
/**
 * Horizontal scaling using nearest integer algorithm for per-line operations.
 * Works with 16, 8, 4, and 2 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 * `ArrayType` should be bitleveld's NibbleArray or QuadArray, but also works with regular D arrays.
 */
public void horizontalScaleNearest(ArrayType)(ArrayType src, ArrayType dest, sizediff_t length, sizediff_t offset, 
		const int trfmParam) @nogc pure nothrow {
	int trfmParamA = trfmParam;
	size_t destPtr;
	length <<= 10;
	offset <<= 10;
	if(trfmParam < 0){
		offset += length-1024;
		trfmParamA *= -1;
	}
	while(length > 0){
		dest[destPtr] = src[offset>>>10];
		offset += trfmParam;
		length -= trfmParamA;
		destPtr++;
	}
}
/**
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations.
 * Works with 4 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void horizontalScaleNearest4BitAndCLU(U)(ubyte* src, U* dest, U* palette, sizediff_t length, sizediff_t offset, 
		const int trfmParam) @nogc pure nothrow {
	int trfmParamA = trfmParam;
	length <<= 10;
	offset <<= 10;
	if(trfmParam < 0){
		offset += length-1024;
		trfmParamA *= -1;
	}
	while(length > 0){
		const ubyte temp = (offset>>>10) & 1 ?  src[offset>>>11] & 0x0F : src[offset>>>11] >> 4;
		*dest = palette[temp];
		offset += trfmParam;
		length -= trfmParam;
		dest++;
	}
}
/**
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations.
 * Works with 16, 8, 4, and 2 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 * `ArrayType` should be bitleveld's NibbleArray or QuadArray, but also works with regular D arrays.
 */
public void horizontalScaleNearestAndCLU(PaletteType, ArrayType)(ArrayType src, PaletteType* dest, PaletteType* palette, 
		sizediff_t length, sizediff_t offset, const int trfmParam) @nogc pure nothrow {
	int trfmParamA = trfmParam;
	length <<= 10;
	offset <<= 10;
	if(trfmParam < 0){
		offset += length-1024;
		trfmParamA *= -1;
	}
	while(length > 0){
		*dest = palette[src[offset>>>10]];
		offset += trfmParam;
		length -= trfmParamA;
		dest++;
	}
}
/**
 * Returns the needed length of dest for the given trfmParam if the "nearest integer algorithm" used.
 * Works with both horizontal and vertical algorithms.
 */
public size_t scaleNearestLength(size_t origLen, int trfmParam) @nogc @safe pure nothrow {
	if(trfmParam < 0)
		trfmParam *= -1;
	return cast(size_t)(cast(double)origLen * (1024.0 / cast(double)trfmParam));
}
pure nothrow unittest{
	import std.conv : to;
	uint[256] a, b;
	ubyte[256] c;
	//force the compiler to check the scalers
	horizontalScaleNearest(a.ptr, b.ptr, 16, 2048);
	horizontalScaleNearestAndCLU(c.ptr,a.ptr,b.ptr,16,2048);
	horizontalScaleNearest4BitAndCLU(c.ptr,a.ptr,b.ptr,16,0,2048);
	assert(20 == scaleNearestLength(10, 512), "Error while testing function `scaleNearestLength`. Expected value: 20 " ~
			"Returned value: " ~ to!string(scaleNearestLength(10, 512)));
	assert(20 == scaleNearestLength(10, -512), "Error while testing function `scaleNearestLength`. Expected value: 20 " ~
			"Returned value: " ~ to!string(scaleNearestLength(10, -512)));
}