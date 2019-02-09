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
version(LDC){
	import inteli.emmintrin;
	import ldc.simd;
	package immutable __m128i SSE2_NULLVECT;
	package immutable __vector(ushort[8]) ALPHABLEND_SSE2_CONST1 = [1,1,1,1,1,1,1,1];
	package immutable __vector(ushort[8]) ALPHABLEND_SSE2_CONST256 = [256,256,256,256,256,256,256,256];
	package immutable __vector(ubyte[16]) ALPHABLEND_SSE2_MASK = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0];
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, size_t length){
	import core.stdc.string;
	memcpy(dest, src, length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, size_t length){
	import core.stdc.string;
	memcpy(cast(void*)dest, cast(void*)src, length * 2);
}
/**
 * Implements a two plus one operand alpha-blending algorithm for 32bit bitmaps. Automatic alpha-mask generation follows this formula:
 * src[B,G,R,A] --> mask [A,A,A,A]
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, size_t length){
	version(LDC){
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
	}else version(X86){
		version(MMX){
			int target8 = length/8, target4 = length%2;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, target8;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movq	MM3, [ESI];
				movq	MM1, MM3;
				pand	MM1, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movq	MM0, MM1;
				pslld	MM0, 8;
				por		MM1, MM0;	//mask is ready for RA
				pslld	MM1, 16;
				por		MM0, MM1; //mask is ready for BGRA
				movq	MM1, MM0;
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				movq	MM6, ALPHABLEND_MMX_CONST256;
				movq	MM7, MM6;
				movq	MM4, ALPHABLEND_MMX_CONST1;
				movq	MM5, MM4;
			
				paddusw	MM4, MM0;	//1 + alpha01
				paddusw	MM5, MM1; //1 + alpha23 
				psubusw	MM6, MM0;	//256 - alpha01
				psubusw	MM7, MM1; //256 - alpha23
			
				//moving the values to their destinations
				movq	MM0, MM3;	//src01
				movq	MM1, MM0; //src23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM4, MM0;	//src01 * (1 + alpha01)
				pmullw	MM5, MM1;	//src23 * (1 + alpha23)
				movq	MM0, [EDI];	//dest01
				movq	MM1, MM0;		//dest23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM6, MM0;	//dest01 * (256 - alpha)
				pmullw	MM7, MM1; //dest23 * (256 - alpha)
		
				paddusw	MM4, MM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	MM5, MM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	MM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	MM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	MM4, MM5;
		
				movq	[EDI], MM4;
				//add		EBX, 16;
				add		ESI, 8;
				add		EDI, 8;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;
				fourpixelblend:
				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;
				fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
			

				movd	MM0, [EDI];
				movd	MM1, [ESI];
				punpcklbw	MM0, MM2;//dest
				punpcklbw	MM1, MM2;//src
				movups	MM6, MM1;
				pand	MM6, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	MM7, MM6;
				pslld	MM6, 8;
				por		MM7, MM6;	//mask is ready for RA
				pslld	MM7, 16;
				por		MM6, MM7; //mask is ready for GRA
				punpcklbw	MM7, MM2;
				movaps	MM4, ALPHABLEND_MMX_CONST256;
				movaps	MM5, ALPHABLEND_MMX_CONST1;
				
				paddusw MM5, MM6;//1+alpha
				psubusw	MM4, MM6;//256-alpha
				
				pmullw	MM0, MM4;//dest*(256-alpha)
				pmullw	MM1, MM5;//src*(1+alpha)
				paddusw	MM0, MM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	MM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	MM0, MM2;
				
				movd	[EDI], MM0;	

			endofalgorithm:
				emms;
			}
		}else{
			asm @nogc {
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 04;
				jz		endofalgorithm;
				jl		onepixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			fourpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [ESI];
				movups	XMM1, XMM3;
				//pand	XMM1, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM0, XMM1;
				pslld	XMM0, 8;
				por		XMM1, XMM0;	//mask is ready for RA
				pslld	XMM1, 16;
				por		XMM0, XMM1; //mask is ready for BGRA
				movups	XMM1, XMM0;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, ALPHABLEND_SSE2_CONST256;
				movups	XMM7, XMM6;
				movups	XMM4, ALPHABLEND_SSE2_CONST1;
				movups	XMM5, XMM4;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[EDI], XMM4;
				//add		EBX, 16;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 4;
				cmp		ECX, 4;
				jge		fourpixelblend;
				jecxz	endofalgorithm;

			onepixelblend:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [EDI];
				movd	XMM1, [ESI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movups	XMM6, XMM1;
				//pand	XMM6, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, ALPHABLEND_SSE2_CONST256;
				movaps	XMM5, ALPHABLEND_SSE2_CONST1;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[EDI], XMM0;
				
				add		ESI, 4;
				add		EDI, 4;
				dec		ECX;
				cmp		ECX, 0;
				jg		onepixelblend;
				//loop	onepixelblend;

			endofalgorithm:
				nop		;
			}
		}
	}else version(X86_64){
		size_t target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RCX, target16;
				movups	XMM8, ALPHABLEND_SSE2_CONST256;
				movups	XMM9, ALPHABLEND_SSE2_CONST1;
				movups	XMM10, ALPHABLEND_SSE2_MASK;
				cmp		RCX, 8;
				jl		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [RSI];
				movups	XMM1, XMM3;
				pand	XMM1, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM0, XMM1;
				pslld	XMM0, 8;
				por		XMM1, XMM0;	//mask is ready for RA
				pslld	XMM1, 16;
				por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM1, XMM0;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, XMM8;
				movups	XMM7, XMM8;
				movups	XMM4, XMM9;
				movups	XMM5, XMM9;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[RDI], XMM4;
				//add		EBX, 16;
				add		RSI, 16;
				add		RDI, 16;
				dec		RCX;
				cmp		RCX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		RCX, target4;
				cmp		RCX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [RDI];
				movd	XMM1, [RSI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movups	XMM6, XMM1;
				pand	XMM6, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, XMM8;
				movaps	XMM5, XMM9;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[RDI], XMM0;
				
				add		RSI, 4;
				add		RDI, 4;/**/
				dec		RCX;
				cmp		RCX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
		}
	}else{
		for(int i ; i < length ; i++){
			switch(src.ColorSpaceARGB.alpha){
				case 0: 
					break;
				case 255: 
					dest = src;
					break;
				default:
					int src1 = 1 + src.ColorSpaceARGB.alpha;
					int src256 = 256 - src.ColorSpaceARGB.alpha;
					dest.ColorSpaceARGB.red = cast(ubyte)((src.ColorSpaceARGB.red * src1 + dest.ColorSpaceARGB.red * src256)>>8);
					dest.ColorSpaceARGB.green = cast(ubyte)((src.ColorSpaceARGB.green * src1 + dest.ColorSpaceARGB.green * src256)>>8);
					dest.ColorSpaceARGB.blue = cast(ubyte)((src.ColorSpaceARGB.blue * src1 + dest.ColorSpaceARGB.blue * src256)>>8);
					break;
			}
			src++;
			dest++;
		}
	}
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used.
 */
public @nogc void copy32bit(uint* src, uint* dest, size_t length){
	import core.stdc.string;
	memcpy(dest, src, length * 4);
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Mask is placeholder.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, size_t length, ubyte* mask){
	copy8bit(src,dest,length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Mask is a placeholder for easy exchangeability with other functions.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, size_t length, ushort* mask){
	copy16bit(src,dest,length);
}
/**
 * Implements a three plus one operand alpha-blending algorithm for 32bit bitmaps. For masking, use Pixel32Bit.AlphaMask from CPUblit.colorspaces.
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, size_t length, uint* mask){
	version(LDC){
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
	}else version(X86){
		version(MMX){
			int target8 = length/8, target4 = length%2;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, target8;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movq	MM3, [ESI];
				/*movq	MM1, MM3;
				pand	MM1, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movq	MM0, MM1;
				pslld	MM0, 8;
				por		MM1, MM0;	//mask is ready for RA
				pslld	MM1, 16;
				por		MM0, MM1; //mask is ready for BGRA*/
				movq	MM0, [EBX];
				movq	MM1, MM0;
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				movq	MM6, ALPHABLEND_MMX_CONST256;
				movq	MM7, MM6;
				movq	MM4, ALPHABLEND_MMX_CONST1;
				movq	MM5, MM4;
			
				paddusw	MM4, MM0;	//1 + alpha01
				paddusw	MM5, MM1; //1 + alpha23 
				psubusw	MM6, MM0;	//256 - alpha01
				psubusw	MM7, MM1; //256 - alpha23
			
				//moving the values to their destinations
				movq	MM0, MM3;	//src01
				movq	MM1, MM0; //src23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM4, MM0;	//src01 * (1 + alpha01)
				pmullw	MM5, MM1;	//src23 * (1 + alpha23)
				movq	MM0, [EDI];	//dest01
				movq	MM1, MM0;		//dest23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM6, MM0;	//dest01 * (256 - alpha)
				pmullw	MM7, MM1; //dest23 * (256 - alpha)
		
				paddusw	MM4, MM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	MM5, MM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	MM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	MM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	MM4, MM5;
		
				movq	[EDI], MM4;
				//add		EBX, 16;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;
				fourpixelblend:
				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;
				fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
			

				movd	MM0, [EDI];
				movd	MM1, [ESI];
				punpcklbw	MM0, MM2;//dest
				punpcklbw	MM1, MM2;//src
				movups	MM6, MM1;
				pand	MM6, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	MM7, MM6;
				pslld	MM6, 8;
				por		MM7, MM6;	//mask is ready for RA
				pslld	MM7, 16;
				por		MM6, MM7; //mask is ready for GRA
				punpcklbw	MM7, MM2;
				movaps	MM4, ALPHABLEND_MMX_CONST256;
				movaps	MM5, ALPHABLEND_MMX_CONST1;
				
				paddusw MM5, MM6;//1+alpha
				psubusw	MM4, MM6;//256-alpha
				
				pmullw	MM0, MM4;//dest*(256-alpha)
				pmullw	MM1, MM5;//src*(1+alpha)
				paddusw	MM0, MM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	MM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	MM0, MM2;
				
				movd	[EDI], MM0;	

			endofalgorithm:
				emms;
			}
		}else{
			int target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, target16;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [ESI];
				movups	XMM1, [EBX];
				//pand	XMM1, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				//movups	XMM0, XMM1;
				//pslld	XMM0, 8;
				//por		XMM1, XMM0;	//mask is ready for RA
				//pslld	XMM1, 16;
				//por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM0, XMM1;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, ALPHABLEND_SSE2_CONST256;
				movups	XMM7, XMM6;
				movups	XMM4, ALPHABLEND_SSE2_CONST1;
				movups	XMM5, XMM4;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[EDI], XMM4;
				//add		EBX, 16;
				add		ESI, 16;
				add		EDI, 16;
				add		EBX, 16;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [EDI];
				movd	XMM1, [ESI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movd	XMM6, [EBX];
				/*pand	XMM6, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA*/
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, ALPHABLEND_SSE2_CONST256;
				movaps	XMM5, ALPHABLEND_SSE2_CONST1;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[EDI], XMM0;
				
				add		ESI, 4;
				add		EDI, 4;/**/
				add		EBX, 4;
				dec		ECX;
				cmp		ECX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
			}
		}
	}else version(X86_64){
		size_t target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RBX, mask[RBP];
				mov		RCX, target16;
				cmp		RCX, 0;
				movups	XMM8, ALPHABLEND_SSE2_CONST256;
				movups	XMM9, ALPHABLEND_SSE2_CONST1;
				movups	XMM10, ALPHABLEND_SSE2_MASK;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [RSI];
				/*movups	XMM1, XMM3;
				pand	XMM1, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM0, XMM1;
				pslld	XMM0, 8;
				por		XMM1, XMM0;	//mask is ready for RA
				pslld	XMM1, 16;
				por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM0, [RBX];
				movups	XMM1, XMM0;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, XMM8;
				movups	XMM7, XMM8;
				movups	XMM4, XMM9;
				movups	XMM5, XMM9;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[RDI], XMM4;
				//add		EBX, 16;
				add		RSI, 16;
				add		RDI, 16;
				add		RBX, 16;
				dec		RCX;
				cmp		RCX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		RCX, target4;
				cmp		RCX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [RDI];
				movd	XMM1, [RSI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movups	XMM6, [RBX];
				/*pand	XMM6, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA*/
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, XMM8;
				movaps	XMM5, XMM9;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[RDI], XMM0;
				
				add		RSI, 4;
				add		RDI, 4;/**/
				add		RBX, 4;
				dec		RCX;
				cmp		RCX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
		}
	}else{
		for(int i ; i < length ; i++){
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
		}
	}
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used. Mask is placeholder.
 */
public @nogc void copy32bit(uint* src, uint* dest, size_t length, uint* mask){
	copy32bit(src,dest,length);
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length){
	copy8bit(src,dest1,length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, ushort* dest1, size_t length){
	copy16bit(src,dest1,length);
}
/**
 * Implements a three plus one operand alpha-blending algorithm for 32bit bitmaps. Automatic alpha-mask generation follows this formula:
 * src[B,G,R,A] --> mask [A,A,A,A]
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, uint* dest1, size_t length){
	version(LDC){
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
	}else version(X86){
		version(MMX){
			int target8 = length/8, target4 = length%2;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, target8;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movq	MM3, [ESI];
				movq	MM1, MM3;
				pand	MM1, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movq	MM0, MM1;
				pslld	MM0, 8;
				por		MM1, MM0;	//mask is ready for RA
				pslld	MM1, 16;
				por		MM0, MM1; //mask is ready for BGRA
				movq	MM1, MM0;
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				movq	MM6, ALPHABLEND_MMX_CONST256;
				movq	MM7, MM6;
				movq	MM4, ALPHABLEND_MMX_CONST1;
				movq	MM5, MM4;
			
				paddusw	MM4, MM0;	//1 + alpha01
				paddusw	MM5, MM1; //1 + alpha23 
				psubusw	MM6, MM0;	//256 - alpha01
				psubusw	MM7, MM1; //256 - alpha23
			
				//moving the values to their destinations
				movq	MM0, MM3;	//src01
				movq	MM1, MM0; //src23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM4, MM0;	//src01 * (1 + alpha01)
				pmullw	MM5, MM1;	//src23 * (1 + alpha23)
				movq	MM0, [EDI];	//dest01
				movq	MM1, MM0;		//dest23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM6, MM0;	//dest01 * (256 - alpha)
				pmullw	MM7, MM1; //dest23 * (256 - alpha)
		
				paddusw	MM4, MM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	MM5, MM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	MM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	MM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	MM4, MM5;
		
				movq	[EDX], MM4;
				//add		EBX, 16;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;
				fourpixelblend:
				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;
				fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
			

				movd	MM0, [EDI];
				movd	MM1, [ESI];
				punpcklbw	MM0, MM2;//dest
				punpcklbw	MM1, MM2;//src
				movups	MM6, MM1;
				pand	MM6, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	MM7, MM6;
				pslld	MM6, 8;
				por		MM7, MM6;	//mask is ready for RA
				pslld	MM7, 16;
				por		MM6, MM7; //mask is ready for GRA
				punpcklbw	MM7, MM2;
				movaps	MM4, ALPHABLEND_MMX_CONST256;
				movaps	MM5, ALPHABLEND_MMX_CONST1;
				
				paddusw MM5, MM6;//1+alpha
				psubusw	MM4, MM6;//256-alpha
				
				pmullw	MM0, MM4;//dest*(256-alpha)
				pmullw	MM1, MM5;//src*(1+alpha)
				paddusw	MM0, MM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	MM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	MM0, MM2;
				
				movd	[EDX], MM0;	

			endofalgorithm:
				emms;
			}
		}else{
			int target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, target16;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [ESI];
				movups	XMM1, XMM3;
				pand	XMM1, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM0, XMM1;
				pslld	XMM0, 8;
				por		XMM1, XMM0;	//mask is ready for RA
				pslld	XMM1, 16;
				por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM1, XMM0;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, ALPHABLEND_SSE2_CONST256;
				movups	XMM7, XMM6;
				movups	XMM4, ALPHABLEND_SSE2_CONST1;
				movups	XMM5, XMM4;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[EDI], XMM4;
				//add		EBX, 16;
				add		ESI, 16;
				add		EDI, 16;
				add		EDX, 16;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [EDI];
				movd	XMM1, [ESI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movups	XMM6, XMM1;
				pand	XMM6, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, ALPHABLEND_SSE2_CONST256;
				movaps	XMM5, ALPHABLEND_SSE2_CONST1;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[EDI], XMM0;
				
				add		ESI, 4;
				add		EDI, 4;/**/
				add		EDX, 4;
				dec		ECX;
				cmp		ECX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
			}
		}
	}else version(X86_64){
		size_t target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RDX, dest1[RBP];
				mov		RCX, target16;
				cmp		RCX, 0;
				movups	XMM8, ALPHABLEND_SSE2_CONST256;
				movups	XMM9, ALPHABLEND_SSE2_CONST1;
				movups	XMM10, ALPHABLEND_SSE2_MASK;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [RSI];
				movups	XMM1, XMM3;
				pand	XMM1, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM0, XMM1;
				pslld	XMM0, 8;
				por		XMM1, XMM0;	//mask is ready for RA
				pslld	XMM1, 16;
				por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM1, XMM0;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, XMM8;
				movups	XMM7, XMM8;
				movups	XMM4, XMM9;
				movups	XMM5, XMM9;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[RDX], XMM4;
				//add		EBX, 16;
				add		RSI, 16;
				add		RDI, 16;
				add		RDX, 16;
				dec		RCX;
				cmp		RCX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		RCX, target4;
				cmp		RCX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [RDI];
				movd	XMM1, [RSI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movups	XMM6, XMM1;
				pand	XMM6, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, XMM8;
				movaps	XMM5, XMM9;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[RDI], XMM0;
				
				add		RSI, 4;
				add		RDI, 4;
				add		RDX, 4;
				dec		RCX;
				cmp		RCX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
		}
	}else{
		for(int i ; i < length ; i++){
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
		}
	}	
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public @nogc void copy32bit(uint* src, uint* dest, uint* dest1, size_t length){
	copy32bit(src, dest1, length);
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Dest and mask are placeholders.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length, ubyte* mask){
	copy8bit(src,dest1,length);
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Dest and mask is placeholder.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, ushort* dest1, size_t length, ushort* mask){
	copy16bit(src,dest1,length);
}
/**
 * Implements a four plus one operand alpha-blending algorithm for 32bit bitmaps. For masking, use Pixel32Bit.AlphaMask from CPUblit.colorspaces.
 * Output is copied into a memory location specified by dest1.
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, uint* dest1, size_t length, uint* mask){
	version(LDC){
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
	}else version(X86){
		version(MMX){
			int target8 = length/8, target4 = length%2;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, target8;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movq	MM3, [ESI];
				/*movq	MM1, MM3;
				pand	MM1, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movq	MM0, MM1;
				pslld	MM0, 8;
				por		MM1, MM0;	//mask is ready for RA
				pslld	MM1, 16;
				por		MM0, MM1; //mask is ready for BGRA*/
				movq	MM0, [EBX];
				movq	MM1, MM0;
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				movq	MM6, ALPHABLEND_MMX_CONST256;
				movq	MM7, MM6;
				movq	MM4, ALPHABLEND_MMX_CONST1;
				movq	MM5, MM4;
			
				paddusw	MM4, MM0;	//1 + alpha01
				paddusw	MM5, MM1; //1 + alpha23 
				psubusw	MM6, MM0;	//256 - alpha01
				psubusw	MM7, MM1; //256 - alpha23
			
				//moving the values to their destinations
				movq	MM0, MM3;	//src01
				movq	MM1, MM0; //src23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM4, MM0;	//src01 * (1 + alpha01)
				pmullw	MM5, MM1;	//src23 * (1 + alpha23)
				movq	MM0, [EDI];	//dest01
				movq	MM1, MM0;		//dest23
				punpcklbw	MM0, MM2;
				punpckhbw	MM1, MM2;
				pmullw	MM6, MM0;	//dest01 * (256 - alpha)
				pmullw	MM7, MM1; //dest23 * (256 - alpha)
		
				paddusw	MM4, MM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	MM5, MM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	MM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	MM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	MM4, MM5;
		
				movq	[EDX], MM4;
				//add		EBX, 16;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;
				fourpixelblend:
				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;
				fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
			

				movd	MM0, [EDI];
				movd	MM1, [ESI];
				punpcklbw	MM0, MM2;//dest
				punpcklbw	MM1, MM2;//src
				movups	MM6, MM1;
				pand	MM6, ALPHABLEND_MMX_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	MM7, MM6;
				pslld	MM6, 8;
				por		MM7, MM6;	//mask is ready for RA
				pslld	MM7, 16;
				por		MM6, MM7; //mask is ready for GRA
				punpcklbw	MM7, MM2;
				movaps	MM4, ALPHABLEND_MMX_CONST256;
				movaps	MM5, ALPHABLEND_MMX_CONST1;
				
				paddusw MM5, MM6;//1+alpha
				psubusw	MM4, MM6;//256-alpha
				
				pmullw	MM0, MM4;//dest*(256-alpha)
				pmullw	MM1, MM5;//src*(1+alpha)
				paddusw	MM0, MM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	MM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	MM0, MM2;
				
				movd	[EDX], MM0;	

			endofalgorithm:
				emms;
			}
		}else{
			int target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, target16;
				cmp		ECX, 0;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [ESI];
				movups	XMM1, [EBX];
				//pand	XMM1, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				//movups	XMM0, XMM1;
				//pslld	XMM0, 8;
				//por		XMM1, XMM0;	//mask is ready for RA
				//pslld	XMM1, 16;
				//por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM0, XMM1;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, ALPHABLEND_SSE2_CONST256;
				movups	XMM7, XMM6;
				movups	XMM4, ALPHABLEND_SSE2_CONST1;
				movups	XMM5, XMM4;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[EDX], XMM4;
				//add		EBX, 16;
				add		ESI, 16;
				add		EDI, 16;
				add		EBX, 16;
				add		EDX, 16;
				dec		ECX;
				cmp		ECX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		ECX, target4;
				cmp		ECX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [EDI];
				movd	XMM1, [ESI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movd	XMM6, [EBX];
				/*pand	XMM6, ALPHABLEND_SSE2_MASK;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA*/
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, ALPHABLEND_SSE2_CONST256;
				movaps	XMM5, ALPHABLEND_SSE2_CONST1;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[EDX], XMM0;
				
				add		ESI, 4;
				add		EDI, 4;/**/
				add		EBX, 4;
				add		EDX, 4;
				dec		ECX;
				cmp		ECX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
			}
		}
	}else version(X86_64){
		size_t target16 = length/4, target4 = length%4;
			asm @nogc {
				//setting up the pointer registers and the counter register
				//mov		EBX, alpha[EBP];
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RBX, mask[RBP];
				mov		RDX, dest1[RBP];
				mov		RCX, target16;
				cmp		RCX, 0;
				movups	XMM8, ALPHABLEND_SSE2_CONST256;
				movups	XMM9, ALPHABLEND_SSE2_CONST1;
				movups	XMM10, ALPHABLEND_SSE2_MASK;
				jz		fourpixelblend; //skip 16 byte operations if not needed
				//iteration cycle entry point
			sixteenpixelblend:
				//create alpha mask on the fly
				movups	XMM3, [RSI];
				/*movups	XMM1, XMM3;
				pand	XMM1, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM0, XMM1;
				pslld	XMM0, 8;
				por		XMM1, XMM0;	//mask is ready for RA
				pslld	XMM1, 16;
				por		XMM0, XMM1; //mask is ready for BGRA/**/
				movups	XMM0, [RBX];
				movups	XMM1, XMM0;
				
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				movups	XMM6, XMM8;
				movups	XMM7, XMM8;
				movups	XMM4, XMM9;
				movups	XMM5, XMM9;
			
				paddusw	XMM4, XMM0;	//1 + alpha01
				paddusw	XMM5, XMM1; //1 + alpha23 
				psubusw	XMM6, XMM0;	//256 - alpha01
				psubusw	XMM7, XMM1; //256 - alpha23
				
				//moving the values to their destinations

				movups	XMM0, XMM3;	//src01
				movups	XMM1, XMM0; //src23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM4, XMM0;	//src01 * (1 + alpha01)
				pmullw	XMM5, XMM1;	//src23 * (1 + alpha23)
				movups	XMM0, [EDI];	//dest01
				movups	XMM1, XMM0;		//dest23
				punpcklbw	XMM0, XMM2;
				punpckhbw	XMM1, XMM2;
				pmullw	XMM6, XMM0;	//dest01 * (256 - alpha)
				pmullw	XMM7, XMM1; //dest23 * (256 - alpha)
			
				paddusw	XMM4, XMM6;	//(src01 * (1 + alpha01)) + (dest01 * (256 - alpha01))
				paddusw	XMM5, XMM7; //(src * (1 + alpha)) + (dest * (256 - alpha))
				psrlw	XMM4, 8;		//(src * (1 + alpha)) + (dest * (256 - alpha)) / 256
				psrlw	XMM5, 8;
				//moving the result to its place;
				//pxor	MM2, MM2;
				packuswb	XMM4, XMM5;
			
				movups	[RDX], XMM4;
				//add		EBX, 16;
				add		RSI, 16;
				add		RDI, 16;
				add		RBX, 16;
				add		RDX, 16;
				dec		RCX;
				cmp		RCX, 0;
				jnz		sixteenpixelblend;

			fourpixelblend:

				mov		RCX, target4;
				cmp		RCX, 0;
				jz		endofalgorithm;

			fourpixelblendloop:

				//movd	XMM6, [EBX];//alpha
				

				movd	XMM0, [RDI];
				movd	XMM1, [RSI];
				punpcklbw	XMM0, XMM2;//dest
				punpcklbw	XMM1, XMM2;//src
				movups	XMM6, [RBX];
				/*pand	XMM6, XMM10;	//pixel & 0x000000FF,0x000000FF,0x000000FF,0x000000FF
				movups	XMM7, XMM6;
				pslld	XMM6, 8;
				por		XMM7, XMM6;	//mask is ready for RA
				pslld	XMM7, 16;
				por		XMM6, XMM7; //mask is ready for BGRA*/
				
				punpcklbw	XMM6, XMM2;
				
				movaps	XMM4, XMM8;
				movaps	XMM5, XMM9;
				
				paddusw XMM5, XMM6;//1+alpha
				psubusw	XMM4, XMM6;//256-alpha
				
				pmullw	XMM0, XMM4;//dest*(256-alpha)
				pmullw	XMM1, XMM5;//src*(1+alpha)
				paddusw	XMM0, XMM1;//(src*(1+alpha))+(dest*(256-alpha))
				psrlw	XMM0, 8;//(src*(1+alpha))+(dest*(256-alpha))/256
				
				packuswb	XMM0, XMM2;
				
				movd	[RDI], XMM0;
				
				add		RSI, 4;
				add		RDI, 4;/**/
				add		RBX, 4;
				add		RDX, 4;
				dec		RCX;
				cmp		RCX, 0;
				jnz		fourpixelblendloop;

			endofalgorithm:
				;
		}
	}else{
		for(int i ; i < length ; i++){
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
		}
	}
}
/**
 * Copies a 32bit image onto another without blitter. No transparency is used. Dest and mask is placeholder.
 */
public @nogc void copy32bit(uint* src, uint* dest, uint* dest1, size_t length, uint* mask){
	copy32bit(src,dest1,length);
}
/**
 * Text blitter, mainly intended for single color texts, can work in other applications as long as they're correctly formatted,
 * meaning: transparent pixels = 0, colored pixels = T.max 
 */
public @nogc void textBlitter(T)(T* src, T* dest, size_t length, T color){
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 16;
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
public @nogc void textBlitter(T)(T* src, T* dest, T* dest1, size_t length, T color){
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 16;
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
public @nogc void blitter(T)(T* src, T* dest, size_t length){
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
public @nogc void blitter(T)(T* src, T* dest, T* dest1, size_t length){
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
public @nogc void blitter(T)(T* src, T* dest, T* dest1, size_t length, T* mask){
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
public @nogc void blitter(T)(T* src, T* dest,  size_t length, T* mask){
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
			__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
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
			__vector(ubyte[16]) colorV = [color, color, color, color, color, color, color, color, color, color, color, color, 
					color, color, color, color];
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			__vector(ushort[8]) colorV = [color, color, color, color, color, color, color, color];
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			__vector(uint[4]) colorV = [color, color, color, color];
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
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
public @nogc void xorBlitter(T)(T* dest, size_t length, T color){
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			__vector(ubyte[16]) colorV = [color, color, color, color, color, color, color, color, color, color, color, color, 
					color, color, color, color];
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			__vector(ushort[8]) colorV = [color, color, color, color, color, color, color, color];
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			__vector(uint[4]) colorV = [color, color, color, color];
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
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
unittest{
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
}