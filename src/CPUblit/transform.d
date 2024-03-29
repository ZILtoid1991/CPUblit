module CPUblit.transform;

import CPUblit.colorspaces;
import bitleveld.datatypes;

/+/** 
 * Horizontal scaling using nearest integer algorithm for per-line operations. Mainly created to solve problems in
 * PixelPerfectEngine with sprite scaling
 * Params:
 *   src = Source of the line to be transformed. Must be large enough to support the destination output with the given
 *   transformation params.
 *   dest = Destination of the transformed line.
 *   length = Length of the output. Must be less or eaqual than the dest buffer. Use function "scaleNearestLength" to 
 *   calculate the needed output length.
 *   trfmParam = Transformation parameter.
 *   offset = Offset in the source line. This allows the source line to be offset by the given amount of fractional 
 *   pixels. Default value is zero.
 */
public void horizontalScaleNearest(T)(T* src, T* dest, sizediff_t length, int trfmParam, size_t offset = 0) 
		@nogc pure nothrow {
	if(trfmParam < 0){
		offset = (length<<10) - 1024 - offset;
	}
	while (length > 0) {
		*dest = src[offset>>>10];
		offset += trfmParam;
		length--;
		dest++;
	}
}+/
/** 
 * Horizontal scaling using nearest integer algorithm for per-line operations. Intended to use with arrays that might
 * contain elements less than 8 bit in length.
 * Params:
 *   src = Source of the line to be transformed. Must be large enough to support the destination output with the given
 *   transformation params.
 *   dest = Destination of the transformed line.
 *   length = Length of the output. Must be less or eaqual than the dest buffer. Use function "scaleNearestLength" to 
 *   calculate the needed output length.
 *   trfmParam = Transformation parameter.
 *   offset = Offset in the source line. This allows the source line to be offset by the given amount of fractional 
 *   pixels. Default value is zero.
 */
public void horizontalScaleNearest(ArrayType)(ArrayType src, ArrayType dest, sizediff_t length, int trfmParam, 
		sizediff_t offset = 0) @nogc pure nothrow {
	if(trfmParam < 0) {
		trfmParam *= -1;
		for (sizediff_t i ; i < length ; i++) {
			dest[i] = src[src.length - (offset>>>10) - 1];
			offset += trfmParam;
		}
	} else {
		for (sizediff_t i ; i < length ; i++) {
			dest[i] = src[offset>>>10];
			offset += trfmParam;
		}
	}
}
/+/** 
 * Horizontal scaling using nearest integer algorithm for per-line operations. Uses pointers for both the palette and
 * source. Intended for 8 bit or larger data.
 * Params:
 *   src = Source of the line to be transformed. Must be large enough to support the destination output with the given
 *   transformation params.
 *   dest = Destination of the transformed line.
 *   palette = Palette. Should have enough elements for every index, or ensure that source wouldn't point that far.
 *   length = Length of the output. Must be less or eaqual than the dest buffer. Use function "scaleNearestLength" to 
 *   calculate the needed output length.
 *   trfmParam = Transformation parameter.
 *   offset = Offset in the source line. This allows the source line to be offset by the given amount of fractional 
 *   pixels. Default value is zero.
 */
public void horizontalScaleNearestAndCLU(T, U)(T* src, U* dest, U* palette, sizediff_t length, int trfmParam, 
		size_t offset = 0) @nogc pure nothrow {
	if(trfmParam < 0){
		offset += (length<<10) - 1024 - offset;
	}
	while (length > 0) {
		*dest = palette[src[offset>>>10]];
		offset += trfmParam;
		length--;
		dest++;
	}
}+/
/** 
 * Horizontal scaling using nearest integer algorithm for per-line operations. Uses arrays for source (compatible with 
 * data types smaller than 8 bit)
 * Params:
 *   src = Source of the line to be transformed. Must be large enough to support the destination output with the given
 *   transformation params.
 *   dest = Destination of the transformed line.
 *   palette = Palette. Should have enough elements for every index, or ensure that source wouldn't point that far.
 *   length = Length of the output. Must be less or eaqual than the dest buffer. Use function "scaleNearestLength" to 
 *   calculate the needed output length.
 *   trfmParam = Transformation parameter.
 *   offset = Offset in the source line. This allows the source line to be offset by the given amount of fractional 
 *   pixels. Default value is zero.
 */
public void horizontalScaleNearestAndCLU(ArrayType, U)(ArrayType src, U* dest, U* palette, sizediff_t length, 
		int trfmParam, sizediff_t offset = 0) @nogc pure nothrow {
	if(trfmParam < 0) {
		trfmParam *= -1;
		for (sizediff_t i ; i < length ; i++) {
			dest[i] = palette[src[src.length - (offset>>>10) - 1]];
			offset += trfmParam;
		}
	} else {
		for (sizediff_t i ; i < length ; i++) {
			dest[i] = palette[src[offset>>>10]];
			offset += trfmParam;
		}
	}
}
/**
 * Horizontal scaling using nearest integer algorithm for per-line operations. (Old, might get deprecated later on)
 * Works with most datatypes. Use a separate one for 4 bit.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void _horizontalScaleNearest(T)(T* src, T* dest, sizediff_t length, int trfmParam) @nogc pure nothrow {
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
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations. (Old, might get deprecated later on)
 * Works with most datatypes. Use a separate one for 4 bit.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void _horizontalScaleNearestAndCLU(T, U)(T* src, U* dest, U* palette, sizediff_t length, const int trfmParam)
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
 * Horizontal scaling using nearest integer algorithm for per-line operations. (Old, might get deprecated later on)
 * Works with 4 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void _horizontalScaleNearest4Bit(ubyte* src, ubyte* dest, sizediff_t length, sizediff_t offset, 
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
 * Horizontal scaling using nearest integer algorithm for per-line operations. (Old, might get deprecated later on)
 * Works with 16, 8, 4, and 2 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 * `ArrayType` should be bitleveld's NibbleArray or QuadArray, but also works with regular D arrays.
 */
public void _horizontalScaleNearest(ArrayType)(ArrayType src, ArrayType dest, sizediff_t length, sizediff_t offset, 
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
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations. (Old, might get deprecated later on)
 * Works with 4 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public void _horizontalScaleNearest4BitAndCLU(U)(ubyte* src, U* dest, U* palette, sizediff_t length, sizediff_t offset, 
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
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations. (Old, might get deprecated later on)
 * Works with 16, 8, 4, and 2 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 * `ArrayType` should be bitleveld's NibbleArray or QuadArray, but also works with regular D arrays.
 */
public void _horizontalScaleNearestAndCLU(PaletteType, ArrayType)(ArrayType src, PaletteType* dest, PaletteType* palette, 
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
 * Returns the needed length of dest for the given trfmParam if the "nearest integer algorithm" used. (Old, might get deprecated later on)
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
	NibbleArray d = NibbleArray(c[0..$], 512), f = NibbleArray(c[0..$], 512);
	QuadArray e = QuadArray(c[0..$], 1024), g = QuadArray(c[0..$], 1024);
	//old scalers
	_horizontalScaleNearest(a.ptr, b.ptr, 16, 2048);
	_horizontalScaleNearestAndCLU(c.ptr,a.ptr,b.ptr,16,2048);
	_horizontalScaleNearest4BitAndCLU(c.ptr,a.ptr,b.ptr,16,0,2048);
	_horizontalScaleNearestAndCLU(d, a.ptr, b.ptr, 256, 0, 2048);
	_horizontalScaleNearestAndCLU(e, a.ptr, b.ptr, 256, 0, 2048);
	
	horizontalScaleNearest(a, b, scaleNearestLength(100, 1000), 1000, 20);
	horizontalScaleNearest(a, b, scaleNearestLength(100, -1000), -1000, 20);
	horizontalScaleNearest(d, f, scaleNearestLength(200, 1000), 1000, 56);
	horizontalScaleNearest(d, f, scaleNearestLength(200, -1000), -1000, 58);
	horizontalScaleNearest(e, g, scaleNearestLength(200, 1100), 1100, 53);
	horizontalScaleNearest(e, g, scaleNearestLength(200, -1100), -1100, 53);

	horizontalScaleNearestAndCLU(c, a.ptr, b.ptr, scaleNearestLength(130, 1200), 1200, 94);
	horizontalScaleNearestAndCLU(c, a.ptr, b.ptr, scaleNearestLength(130, -1200), -1200, 0);
	horizontalScaleNearestAndCLU(d, a.ptr, b.ptr, scaleNearestLength(130, 1200), 1200, 94);
	horizontalScaleNearestAndCLU(d, a.ptr, b.ptr, scaleNearestLength(130, -1200), -1200, 94);
	horizontalScaleNearestAndCLU(e, a.ptr, b.ptr, scaleNearestLength(130, 1200), 1200, 94);
	horizontalScaleNearestAndCLU(e, a.ptr, b.ptr, scaleNearestLength(130, -1200), -1200, 94);
	assert(20 == scaleNearestLength(10, 512), "Error while testing function `scaleNearestLength`. Expected value: 20 " ~
			"Returned value: " ~ to!string(scaleNearestLength(10, 512)));
	assert(20 == scaleNearestLength(10, -512), "Error while testing function `scaleNearestLength`. Expected value: 20 " ~
			"Returned value: " ~ to!string(scaleNearestLength(10, -512)));
}