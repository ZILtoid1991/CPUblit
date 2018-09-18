module CPUblit.transform;

import CPUblit.colorspaces;

/**
 * Horizontal scaling using nearest integer algorithm for per-line operations.
 * Works with most datatypes. Use a separate one for 4 bit.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public @nogc void horizontalScaleNearest(T)(T* src, T* dest, size_t length, int trfmParam){
	if(trfmParam < 0)
		src += length;
	sizediff_t offset;
	while(length){
		*dest = src[offset>>>10];
		offset += trfmParam;
		length--;
		dest++;
	}
}
/**
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations.
 * Works with most datatypes. Use a separate one for 4 bit.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public @nogc void horizontalScaleNearestAndCLU(T, U)(T* src, U* dest, U* palette, size_t length, const int trfmParam){
	if(trfmParam < 0)
		src += length;
	sizediff_t offset;
	while(length){
		*dest = palette[(src[offset>>>10])];
		offset += trfmParam;
		length--;
		dest++;
	}
}
/**
 * Horizontal scaling using nearest integer algorithm for per-line operations.
 * Works with 4 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public @nogc void horizontalScaleNearest4Bit(ubyte* src, ubyte* dest, size_t length, sizediff_t offset, 
		const int trfmParam){
	if(trfmParam < 0)
		src += length;
	//sizediff_t offset;
	offset <<= 10;
	while(length){
		const ubyte temp = (offset>>>10) & 1 ?  src[offset>>>11] & 0x0F : src[offset>>>11] >> 4;
		*dest |= length & 1 ? temp : temp << 4;
		offset += trfmParam;
		length--;
		dest++;
	}
}
/**
 * Horizontal scaling and color lookup using nearest integer algorithm for per-line operations.
 * Works with 4 bit datatypes.
 * Lenght determines the source's length.
 * trfmParam describes how the transformation is done. 1024 results in the same exact line. Larger values cause shrinkage, smaller omes growth. Negative values cause reflections.
 */
public @nogc void horizontalScaleNearest4BitAndCLU(U)(ubyte* src, U* dest, U* palette, size_t length, sizediff_t offset, 
		const int trfmParam){
	if(trfmParam < 0)
		src += length;
	//sizediff_t offset;
	offset <<= 10;
	while(length){
		const ubyte temp = (offset>>>10) & 1 ?  src[offset>>>11] & 0x0F : src[offset>>>11] >> 4;
		*dest = palette[temp];
		offset += trfmParam;
		length--;
		dest++;
	}
}
/**
 * Returns the needed length of dest for the given trfmParam if the "nearest integer algorithm" used.
 * Works with both horizontal and vertical algorithms.
 */
public @nogc size_t scaleNearestLength(size_t origLen, int trfmParam){
	if(trfmParam < 0)
		trfmParam *= -1;
	return (origLen * trfmParam)>>10;
}
unittest{
	uint[256] a, b;
	ubyte[256] c;
	//force the compiler to check the scalers
	horizontalScaleNearest(a.ptr, b.ptr, 16, 2048);
	horizontalScaleNearestAndCLU(c.ptr,a.ptr,b.ptr,16,2048);
	horizontalScaleNearest4BitAndCLU(c.ptr,a.ptr,b.ptr,16,0,2048);
}