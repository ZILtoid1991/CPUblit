module CPUblit.composing;

import CPUblit.colorspaces;
import CPUblit.system;

/**
 * CPUblit
 * Low-level image composing functions
 * Author: Laszlo Szeremi
 * Contains 2, 3, and 4 operand functions.
 * All blitter follows this formula: dest1 = (dest & mask) | src
 * Two plus one operand blitter is done via evaluation on systems that don't support vector operations.
 * Alpha-blending function formula: dest1 = (src * (1 + alpha) + dest * (256 - alpha)) >> 8
 * Where it was possible I implemented vector support. Due to various quirks I needed (such as the ability of load unaligned values, and load less than 128/64bits), I often 
 * had to rely on assembly. As the functions themselves aren't too complicated it wasn't an impossible task, but makes debugging time-consuming.
 * See specific functions for more information. 
 */

//import core.simd;
static if (USE_INTEL_INTRINSICS) {
	import inteli.emmintrin;
	//import ldc.simd;
	package immutable __m128i SSE2_NULLVECT;
	package immutable __vector(ushort[8]) ALPHABLEND_SSE2_CONST1 = [1,1,1,1,1,1,1,1];
	package immutable __vector(ushort[8]) ALPHABLEND_SSE2_CONST256 = [256,256,256,256,256,256,256,256];
	package immutable __vector(ubyte[16]) ALPHABLEND_SSE2_MASK = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0];
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used.
 */
public void copy8bit(ubyte* src, ubyte* dest, size_t length) @nogc pure nothrow {
	import core.stdc.string;
	memcpy(dest, src, length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used.
 */
public void copy16bit(ushort* src, ushort* dest, size_t length) @nogc pure nothrow {
	import core.stdc.string;
	memcpy(cast(void*)dest, cast(void*)src, length * 2);
}
/**
 * Implements a two plus one operand alpha-blending algorithm for 32bit bitmaps. Automatic alpha-mask generation follows this formula:
 * src[B,G,R,A] --> mask [A,A,A,A]
 * TODO: add template to make it able to specify the alpha channel.
 */
public void alphaBlend32bit(uint* src, uint* dest, size_t length) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		while(length >= 4){
			__m128i src0 = _mm_loadu_si128(cast(__m128i*)src);
			__m128i dest0 = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i mask = src0 & cast(__m128i)ALPHABLEND_SSE2_MASK;
			mask |= _mm_slli_epi32(mask, 8);
			mask |= _mm_slli_epi32(mask, 16);//[A,A,A,A]
			__m128i mask_lo = _mm_unpacklo_epi8(mask, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(mask, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(src0, SSE2_NULLVECT), mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(dest0, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			length -= 4;
		}
		if(length >= 2){
			__m128i src0 = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i dest0 = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i mask = src0 & cast(__m128i)ALPHABLEND_SSE2_MASK;
			mask |= _mm_slli_epi32(mask, 8);
			mask |= _mm_slli_epi32(mask, 16);//[A,A,A,A]
			__m128i mask_lo = _mm_unpacklo_epi8(mask, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if(length){
			__m128i src0 = _mm_cvtsi32_si128(*cast(int*)src);
			__m128i dest0 = _mm_cvtsi32_si128(*cast(int*)dest);
			__m128i mask = src0 & cast(__m128i)ALPHABLEND_SSE2_MASK;
			mask |= _mm_slli_epi32(mask, 8);
			mask |= _mm_slli_epi32(mask, 16);//[A,A,A,A]
			__m128i mask_lo = _mm_unpacklo_epi8(mask, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			*cast(int*)dest = _mm_cvtsi128_si32(_mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}else{
		/+Pixel32Bit lsrc = *cast(Pixel32Bit*)src, ldest = *cast(Pixel32Bit*)dest;
		for(int i ; i < length ; i++){
			switch(lsrc.ColorSpaceARGB.alpha){
				case 0: 
					break;
				case 255: 
					ldest = lsrc;
					break;
				default:
					const int src1 = 1 + lsrc.ColorSpaceARGB.alpha;
					const int src256 = 256 - lsrc.ColorSpaceARGB.alpha;
					ldest.ColorSpaceARGB.red = cast(ubyte)((lsrc.ColorSpaceARGB.red * src1 + ldest.ColorSpaceARGB.red * src256)>>8);
					ldest.ColorSpaceARGB.green = cast(ubyte)((lsrc.ColorSpaceARGB.green * src1 + ldest.ColorSpaceARGB.green * src256)>>8);
					ldest.ColorSpaceARGB.blue = cast(ubyte)((lsrc.ColorSpaceARGB.blue * src1 + ldest.ColorSpaceARGB.blue * src256)>>8);
					break;
			}
			src++;
			*cast(Pixel32Bit*)dest = ldest;
			dest++;
		}+/
	}
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used.
 */
public void copy32bit(uint* src, uint* dest, size_t length) @nogc pure nothrow {
	import core.stdc.string;
	memcpy(dest, src, length * 4);
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Mask is placeholder.
 */
public void copy8bit(ubyte* src, ubyte* dest, size_t length, ubyte* mask) @nogc pure nothrow {
	copy8bit(src,dest,length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Mask is a placeholder for easy exchangeability with other functions.
 */
public void copy16bit(ushort* src, ushort* dest, size_t length, ushort* mask) @nogc pure nothrow {
	copy16bit(src,dest,length);
}
/**
 * Implements a three plus one operand alpha-blending algorithm for 32bit bitmaps. For masking, use Pixel32Bit.AlphaMask from CPUblit.colorspaces.
 */
public void alphaBlend32bit(uint* src, uint* dest, size_t length, uint* mask) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		while(length >= 4){
			__m128i src0 = _mm_loadu_si128(cast(__m128i*)src);
			__m128i dest0 = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i mask0 = _mm_loadu_si128(cast(__m128i*)mask);
			__m128i mask_lo = _mm_unpacklo_epi8(mask0, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(mask0, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(src0, SSE2_NULLVECT), mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(dest0, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			mask += 4;
			length -= 4;
		}
		if(length >= 2){
			__m128i src0 = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i dest0 = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i mask0 = _mm_loadl_epi64(cast(__m128i*)mask);
			__m128i mask_lo = _mm_unpacklo_epi8(mask0, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			mask += 2;
			length -= 2;
		}
		if(length){
			__m128i src0 = _mm_cvtsi32_si128(*cast(int*)src);
			__m128i dest0 = _mm_cvtsi32_si128(*cast(int*)dest);
			__m128i mask0 = _mm_cvtsi32_si128(*cast(int*)mask);
			__m128i mask_lo = _mm_unpacklo_epi8(mask0, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			*cast(int*)dest = _mm_cvtsi128_si32(_mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}else{
		/+for(int i ; i < length ; i++){
			switch(mask.AlphaMask.value){
				case 0: 
					break;
				case 255: 
					dest = src;
					break;
				default:
					int src1 = 1 + mask.AlphaMask.value;
					int src256 = 256 - mask.AlphaMask.value;
					dest.ColorSpaceARGB.red = cast(ubyte)((src.ColorSpaceARGB.red * src1 + dest.ColorSpaceARGB.red * src256)>>8);
					dest.ColorSpaceARGB.green = cast(ubyte)((src.ColorSpaceARGB.green * src1 + dest.ColorSpaceARGB.green * src256)>>8);
					dest.ColorSpaceARGB.blue = cast(ubyte)((src.ColorSpaceARGB.blue * src1 + dest.ColorSpaceARGB.blue * src256)>>8);
					break;
			}
			src++;
			dest++;
			mask++;
		}+/
	}
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used. Mask is placeholder.
 */
public void copy32bit(uint* src, uint* dest, size_t length, uint* mask) @nogc pure nothrow {
	copy32bit(src,dest,length);
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public void copy8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length) @nogc pure nothrow {
	copy8bit(src,dest1,length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public void copy16bit(ushort* src, ushort* dest, ushort* dest1, size_t length) @nogc pure nothrow {
	copy16bit(src,dest1,length);
}
/**
 * Implements a three plus one operand alpha-blending algorithm for 32bit bitmaps. Automatic alpha-mask generation follows this formula:
 * src[B,G,R,A] --> mask [A,A,A,A]
 */
public void alphaBlend32bit(uint* src, uint* dest, uint* dest1, size_t length) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		while(length >= 4){
			__m128i src0 = _mm_loadu_si128(cast(__m128i*)src);
			__m128i dest0 = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i mask = src0 | cast(__m128i)ALPHABLEND_SSE2_MASK;
			mask |= _mm_slli_epi32(mask, 8);
			mask |= _mm_slli_epi32(mask, 16);//[A,A,A,A]
			__m128i mask_lo = _mm_unpacklo_epi8(mask, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(mask, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(src0, SSE2_NULLVECT), mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(dest0, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest1, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest1 += 4;
			length -= 4;
		}
		if(length >= 2){
			__m128i src0 = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i dest0 = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i mask = src0 | cast(__m128i)ALPHABLEND_SSE2_MASK;
			mask |= _mm_slli_epi32(mask, 8);
			mask |= _mm_slli_epi32(mask, 16);//[A,A,A,A]
			__m128i mask_lo = _mm_unpacklo_epi8(mask, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest1, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest1 += 2;
			length -= 2;
		}
		if(length){
			__m128i src0 = _mm_cvtsi32_si128(*cast(int*)src);
			__m128i dest0 = _mm_cvtsi32_si128(*cast(int*)dest);
			__m128i mask = src0 | cast(__m128i)ALPHABLEND_SSE2_MASK;
			mask |= _mm_slli_epi32(mask, 8);
			mask |= _mm_slli_epi32(mask, 16);//[A,A,A,A]
			__m128i mask_lo = _mm_unpacklo_epi8(mask, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			*cast(int*)dest1 = _mm_cvtsi128_si32(_mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}else{
		/+for(int i ; i < length ; i++){
			switch(src.ColorSpaceARGB.alpha){
				case 0: 
					break;
				case 255: 
					dest = src;
					break;
				default:
					int src1 = 1 + src.ColorSpaceARGB.alpha;
					int src256 = 256 - src.ColorSpaceARGB.alpha;
					dest1.ColorSpaceARGB.red = cast(ubyte)((src.ColorSpaceARGB.red * src1 + dest.ColorSpaceARGB.red * src256)>>8);
					dest1.ColorSpaceARGB.green = cast(ubyte)((src.ColorSpaceARGB.green * src1 + dest.ColorSpaceARGB.green * src256)>>8);
					dest1.ColorSpaceARGB.blue = cast(ubyte)((src.ColorSpaceARGB.blue * src1 + dest.ColorSpaceARGB.blue * src256)>>8);
					break;
			}
			src++;
			dest++;
			dest1++;
		}+/
	}	
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public void copy32bit(uint* src, uint* dest, uint* dest1, size_t length) @nogc pure nothrow {
	copy32bit(src, dest1, length);
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Dest and mask are placeholders.
 */
public void copy8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length, ubyte* mask) @nogc pure nothrow {
	copy8bit(src,dest1,length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Dest and mask is placeholder.
 */
public void copy16bit(ushort* src, ushort* dest, ushort* dest1, size_t length, ushort* mask) @nogc pure nothrow {
	copy16bit(src,dest1,length);
}
/**
 * Implements a four plus one operand alpha-blending algorithm for 32bit bitmaps. For masking, use Pixel32Bit.AlphaMask from CPUblit.colorspaces.
 * Output is copied into a memory location specified by dest1.
 */
public void alphaBlend32bit(uint* src, uint* dest, uint* dest1, size_t length, uint* mask) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		while(length >= 4){
			__m128i src0 = _mm_loadu_si128(cast(__m128i*)src);
			__m128i dest0 = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i mask0 = _mm_loadu_si128(cast(__m128i*)mask);
			__m128i mask_lo = _mm_unpacklo_epi8(mask0, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(mask0, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(src0, SSE2_NULLVECT), mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(dest0, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest1, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest1 += 4;
			mask += 4;
			length -= 4;
		}
		if(length >= 2){
			__m128i src0 = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i dest0 = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i mask0 = _mm_loadl_epi64(cast(__m128i*)mask);
			__m128i mask_lo = _mm_unpacklo_epi8(mask0, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest1, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest1 += 2;
			mask += 2;
			length -= 2;
		}
		if(length){
			__m128i src0 = _mm_cvtsi32_si128(*cast(int*)src);
			__m128i dest0 = _mm_cvtsi32_si128(*cast(int*)dest);
			__m128i mask0 = _mm_cvtsi32_si128(*cast(int*)mask);
			__m128i mask_lo = _mm_unpacklo_epi8(mask0, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(src0, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(dest0, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			*cast(int*)dest1 = _mm_cvtsi128_si32(_mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}else{
		/+for(int i ; i < length ; i++){
			switch(mask.AlphaMask.value){
				case 0: 
					break;
				case 255: 
					dest = src;
					break;
				default:
					int src1 = 1 + mask.AlphaMask.value;
					int src256 = 256 - mask.AlphaMask.value;
					dest1.ColorSpaceARGB.red = cast(ubyte)((src.ColorSpaceARGB.red * src1 + dest.ColorSpaceARGB.red * src256)>>8);
					dest1.ColorSpaceARGB.green = cast(ubyte)((src.ColorSpaceARGB.green * src1 + dest.ColorSpaceARGB.green * src256)>>8);
					dest1.ColorSpaceARGB.blue = cast(ubyte)((src.ColorSpaceARGB.blue * src1 + dest.ColorSpaceARGB.blue * src256)>>8);
					break;
			}
			src++;
			dest++;
			dest1++;
			mask++;
		}+/
	}
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used. Dest and mask is placeholder.
 */
public void copy32bit(uint* src, uint* dest, uint* dest1, size_t length, uint* mask) @nogc pure nothrow {
	copy32bit(src,dest1,length);
}
/**
 * Text blitter, mainly intended for single color texts, can work in other applications as long as they're correctly formatted,
 * meaning: transparent pixels = 0, colored pixels = T.max 
 */
public void textBlitter(T)(T* src, T* dest, size_t length, T color) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			__vector(ushort[8]) colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			__vector(uint[4]) colorV;
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		static foreach(i; 0 .. (MAINLOOP_LENGTH)){
			colorV[i] = color;
		}
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src) & cast(__m128i)colorV;
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src) & cast(__m128i)colorV;
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src)) & cast(__m128i)colorV;
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			*cast(int*)dest = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				const ubyte mask = *src ? ubyte.min : ubyte.max;
				*dest = (*src & color) | (*dest & mask);
				src++;
				dest++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				const ushort mask = *src ? ushort.min : ushort.max;
				*dest = (*src /+& color+/) | (*dest & mask);
			}
		}
	}else{
		while(length){
			const ubyte mask = *src ? T.min : T.max;
			*dest = (*src & color) | (*dest & mask);
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Text blitter, mainly intended for single color texts, can work in other applications as long as they're correctly formatted,
 * meaning: transparent pixels = 0, colored pixels = T.max 
 */
public void textBlitter(T)(T* src, T* dest, T* dest1, size_t length, T color) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			__vector(ushort[8]) colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			__vector(uint[4]) colorV;
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		static foreach(i; 0 .. (MAINLOOP_LENGTH)){
			colorV[i] = color;
		}
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src) & cast(__m128i)colorV;
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storeu_si128(cast(__m128i*)dest1, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			dest1 += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src) & cast(__m128i)colorV;
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storel_epi64(cast(__m128i*)dest1, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			dest1 += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src)) & cast(__m128i)colorV;
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			*cast(int*)dest1 = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				dest1 += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				const T mask = *src ? T.min : T.max;
				*dest1 = (*src & color) | (*dest & mask);
				src++;
				dest++;
				dest1++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				const T mask = *src ? T.min : T.max;
				*dest1 = (*src & color) | (*dest & mask);
			}
		}
	}else{
		while(length){
			const T mask = *src ? T.min : T.max;
			*dest1 = (*src & color) | (*dest & mask);
			src++;
			dest++;
			dest1++;
			length--;
		}
	}
}
/**
 * Blitter function. Composes an image onto another (per line) with transparency using the logical function of:
 * dest = src | (dest & mask) => mask = src ? 0 : T.max.
 * On 32 bit images, it's sufficent to have only the alpha channel set to zero.
 */
public void blitter(T)(T* src, T* dest, size_t length) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_MASK, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_MASK, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_MASK, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			*cast(int*)dest = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				const ubyte mask = *src ? ubyte.min : ubyte.max;
				*dest = *src | (*dest & mask);
				src++;
				dest++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				const ushort mask = *src ? ushort.min : ushort.max;
				*dest = *src | (*dest & mask);
			}
		}
	}else{
		while(length){
			const ubyte mask = *src ? T.min : T.max;
			*dest = *src | (*dest & mask);
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Blitter function. Composes an image onto another (per line) with transparency using the logical function of:
 * dest1 = src | (dest & mask) => mask = src ? 0 : T.max.
 * On 32 bit images, it's sufficent to have only the alpha channel set to zero.
 */
public void blitter(T)(T* src, T* dest, T* dest1, size_t length) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_MASK, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storeu_si128(cast(__m128i*)dest1, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			dest1 += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_MASK, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			_mm_storel_epi64(cast(__m128i*)dest1, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			dest1 += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			static if(T.stringof == "ubyte")
				__m128i mask = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "ushort")
				__m128i mask = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(T.stringof == "uint")
				__m128i mask = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_MASK, SSE2_NULLVECT);
			destV = srcV | (destV & mask);
			*cast(int*)dest1 = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				dest1 += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				const ubyte mask = *src ? ubyte.min : ubyte.max;
				*dest1 = *src | (*dest & mask);
				src++;
				dest++;
				dest1++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				const ushort mask = *src ? ushort.min : ushort.max;
				*dest1 = *src | (*dest & mask);
			}
		}
	}else{
		while(length){
			const ubyte mask = *src ? T.min : T.max;
			*dest1 = *src | (*dest & mask);
			src++;
			dest++;
			dest1++;
			length--;
		}
	}
}
/**
 * Blitter function. Composes an image onto another (per line) with transparency using the logical function of:
 * dest1 = src | (dest & mask).
 */
public void blitter(T)(T* src, T* dest, T* dest1, size_t length, T* mask) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 16;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			destV = srcV | (destV & maskV);
			_mm_storeu_si128(cast(__m128i*)dest1, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			dest1 += MAINLOOP_LENGTH;
			mask += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			destV = srcV | (destV & maskV);
			_mm_storel_epi64(cast(__m128i*)dest1, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			dest1 += HALFLOAD_LENGTH;
			mask += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			__m128i maskV = _mm_cvtsi32_si128((*cast(int*)mask));
			destV = srcV | (destV & maskV);
			*cast(int*)dest1 = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				dest1 += QUTRLOAD_LENGTH;
				mask += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest1 = *src | (*dest & *mask);
				src++;
				dest++;
				dest1++;
				mask++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest1 = *src | (*dest & *mask);
			}
		}
	}else{
		while(length){
			*dest1 = *src | (*dest & *mask);
			src++;
			dest++;
			dest1++;
			mask++;
			length--;
		}
	}
}
/**
 * Blitter function. Composes an image onto another (per line) with transparency using the logical function of:
 * dest1 = src | (dest & mask).
 */
public void blitter(T)(T* src, T* dest,  size_t length, T* mask) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			destV = srcV | (destV & maskV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			//dest1 += MAINLOOP_LENGTH;
			mask += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			destV = srcV | (destV & maskV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			//dest1 += HALFLOAD_LENGTH;
			mask += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			__m128i maskV = _mm_cvtsi32_si128((*cast(int*)mask));
			destV = srcV | (destV & maskV);
			*cast(int*)dest = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				//dest1 += QUTRLOAD_LENGTH;
				mask += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest = *src | (*dest & *mask);
				src++;
				dest++;
				//dest1++;
				mask++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest = *src | (*dest & *mask);
			}
		}
	}else{
		while(length){
			*dest1 = *src | (*dest & *mask);
			src++;
			dest++;
			//dest1++;
			mask++;
			length--;
		}
	}
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public @nogc void xorBlitter(T)(T* dest, T* dest1, size_t length, T color){
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			__vector(ushort[8]) colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			__vector(uint[4]) colorV;
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		for (int i ; i < colorV.length ; i++){
			colorV[i] = color;
		}
		while(length >= MAINLOOP_LENGTH){
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_xor_si128(destV, colorV);
			_mm_storeu_si128(cast(__m128i*)dest1, destV);
			dest += MAINLOOP_LENGTH;
			dest1 += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i destV = _mm_loadl_epi64(cast(__m64*)dest);
			destV = _mm_xor_si128(destV, colorV);
			_mm_storel_epi64(cast(__m64*)dest1, destV);
			dest += HALFLOAD_LENGTH;
			dest1 += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			destV = _mm_xor_si128(destV, colorV);
			*cast(int*)dest1 = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				dest += QUTRLOAD_LENGTH;
				dest1 += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest1 = color ^ *dest;
				dest++;
				dest1++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest1 = color ^ *dest;
			}
		}
	}else{
		while(length){
			*dest1 = color ^ *dest;
			dest++;
			dest1++;
			length--;
		}
	}
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public void xorBlitter(T)(T* dest, size_t length, T color) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			__vector(ushort[8]) colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			__vector(uint[4]) colorV;
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		for (int i ; i < colorV.length ; i++){
			colorV[i] = color;
		}
		while(length >= MAINLOOP_LENGTH){
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_xor_si128(destV, colorV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			dest += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i destV = _mm_loadl_epi64(cast(__m64*)dest);
			destV = _mm_xor_si128(destV, colorV);
			_mm_storel_epi64(cast(__m64*)dest, destV);
			dest += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			destV = _mm_xor_si128(destV, colorV);
			*cast(int*)dest = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				dest += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest = color ^ *dest;
				dest++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest = color ^ *dest;
			}
		}
	}else{
		while(length){
			*dest = color ^ *dest;
			dest++;
			length--;
		}
	}
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public void xorBlitter(T)(T* src, T* dest, size_t length) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_xor_si128(destV, srcV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			dest += MAINLOOP_LENGTH;
			src += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m64*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m64*)dest);
			destV = _mm_xor_si128(destV, srcV);
			_mm_storel_epi64(cast(__m64*)dest, destV);
			dest += HALFLOAD_LENGTH;
			src += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			destV = _mm_xor_si128(destV, srcV);
			*cast(int*)dest = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				dest += QUTRLOAD_LENGTH;
				src += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest = *src ^ *dest;
				dest++;
				src++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest = *src ^ *dest;
			}
		}
	}else{
		while(length){
			*dest = *src ^ *dest;
			dest++;
			src++;
			length--;
		}
	}
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public void xorBlitter(T)(T* src, T* dest, T* dest1, size_t length) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_xor_si128(destV, srcV);
			_mm_storeu_si128(cast(__m128i*)dest1, destV);
			dest += MAINLOOP_LENGTH;
			dest1 += MAINLOOP_LENGTH;
			src += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m64*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m64*)dest);
			destV = _mm_xor_si128(destV, srcV);
			_mm_storel_epi64(cast(__m64*)dest1, destV);
			dest += HALFLOAD_LENGTH;
			dest1 += HALFLOAD_LENGTH;
			src += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			destV = _mm_xor_si128(destV, srcV);
			*cast(int*)dest1 = _mm_cvtsi128_si32(destV);
			static if(T.stringof != "uint"){
				dest += QUTRLOAD_LENGTH;
				dest1 += QUTRLOAD_LENGTH;
				src += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest = *src ^ *dest;
				dest++;
				dest1++;
				src++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest1 = *src ^ *dest;
			}
		}
	}else{
		while(length){
			*dest = *src ^ *dest;
			dest++;
			dest1++;
			src++;
			length--;
		}
	}
}
@nogc pure nothrow unittest {
	uint[256] a, b;
	ushort[256] c, d;
	ubyte[256] e, f;
	blitter(a.ptr, b.ptr, 255);
	blitter(a.ptr, b.ptr, b.ptr, 255);
	blitter(a.ptr, b.ptr, b.ptr, 255, b.ptr);
	blitter(a.ptr, b.ptr, 255, b.ptr);
	blitter(c.ptr, d.ptr, 255);
	blitter(c.ptr, d.ptr, d.ptr, 255);
	blitter(c.ptr, d.ptr, d.ptr, 255, d.ptr);
	blitter(c.ptr, d.ptr, 255, d.ptr);
	blitter(e.ptr, f.ptr, 255);
	blitter(e.ptr, f.ptr, f.ptr, 255);
	blitter(e.ptr, f.ptr, f.ptr, 255, f.ptr);
	blitter(e.ptr, f.ptr, 255, f.ptr);

	textBlitter(a.ptr, b.ptr, 255, cast(ubyte)50);
	textBlitter(a.ptr, b.ptr, b.ptr, 255, cast(ubyte)50);
	textBlitter(c.ptr, d.ptr, 255, cast(ubyte)50);
	textBlitter(c.ptr, d.ptr, d.ptr, 255, cast(ubyte)50);
	textBlitter(e.ptr, f.ptr, 255, 50);
	textBlitter(e.ptr, f.ptr, f.ptr, 255, 50);

	xorBlitter(a.ptr, b.ptr, 255, a[0]);
	xorBlitter(a.ptr, 255, a[0]);
}