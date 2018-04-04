module CPUblit.composing;

import CPUblit.colorspaces;

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
//package immutable ubyte[16] NULLVECT_SSE2;
package immutable uint[4] BLT32BITTESTER_SSE2 = [0x01000000,0x01000000,0x01000000,0x01000000];
package immutable ushort[8] ALPHABLEND_SSE2_CONST1 = [1,1,1,1,1,1,1,1];
package immutable ushort[8] ALPHABLEND_SSE2_CONST256 = [256,256,256,256,256,256,256,256];
package immutable ubyte[16] ALPHABLEND_SSE2_MASK = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0];
//package immutable ubyte[8] NULLVECT_MMX;
package immutable uint[2] BLT32BITTESTER_MMX = [0x01000000,0x01000000];
package immutable ushort[4] ALPHABLEND_MMX_CONST1 = [1,1,1,1];
package immutable ushort[4] ALPHABLEND_MMX_CONST256 = [256,256,256,256];
package immutable ubyte[8] ALPHABLEND_MMX_MASK = [255,0,0,0,255,0,0,0];
/**
 * Two plus one operand blitter for 8 bit values. Automatic mask-generation is used from the source's color index with the following formula:
 * mask = src == 0x00 ? 0xFF : 0x00
 */
public @nogc void blitter8bit(ubyte* src, ubyte* dest, size_t length){
	version(X86){
		version(MMX){
			asm @nogc{
				pxor	MM7, MM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, MM7;
				pcmpeqb	MM2, MM0;
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDI], MM1;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movq	MM2, MM7;
				pcmpeqb	MM2, MM0;
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDI], MM1;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				cmp		AL, 0;
				jz		step;
				mov		AL, [EDI];
			step:
				mov		[EDI], AL;
				cmp		ECX, 0;
				inc		ESI;
				inc		EDI;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				emms;
			}
		}else{
			asm @nogc{
				pxor	XMM7, XMM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 16;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDI], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 16;
				cmp		ECX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		ECX, 8;
				jl		fourpixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDI], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 8;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				cmp		AL, 0;
				jz		step;
				mov		AL, [EDI];
			step:
				mov		[EDI], AL;
				cmp		ECX, 0;
				inc		ESI;
				inc		EDI;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			pxor	XMM7, XMM7;
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RCX, length;
			cmp		RCX, 16;
			jl		eightpixel;
		sixteenpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqb	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDI], XMM1;
			add		RSI, 16;
			add		RDI, 16;
			sub		RCX, 16;
			cmp		RCX, 16;
			jge		sixteenpixelloop;
		eightpixel:
			cmp		RCX, 8;
			jl		fourpixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqb	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDI], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			sub		RCX, 8;
		fourpixel:
			cmp		RCX, 4;
			jl		singlepixelloop;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqb	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			sub		RCX, 4;
		singlepixelloop:
			cmp		RCX, 0;
			jz		end;
			mov		AL, [RSI];
			cmp		AL, 0;
			jz		step;
			mov		AL, [EDI];
		step:
			mov		[RDI], AL;
			cmp		RCX, 0;
			inc		RSI;
			inc		RDI;
			dec		RCX;
			jmp		singlepixelloop;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, size_t length){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movq	MM0, [ESI];
				movq	[EDI], MM0;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	MM0, [ESI];
				movd	[EDI], MM0;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AL, [ESI];
				mov		[EDI], AL;
				cmp		ECX, 0;
				inc		ESI;
				inc		EDI;
				dec		ECX;
				jnz		singlepixelloop;
			end:
				;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 16;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [ESI];
				movups	[EDI], XMM0;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 16;
				cmp		ECX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		ECX, 8;
				jl		fourpixel;
				movq	XMM0, [ESI];
				movq	[EDI], XMM0;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 8;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AL, [ESI];
				mov		[EDI], AL;
				cmp		ECX, 0;
				inc		ESI;
				inc		EDI;
				dec		ECX;
				jnz		singlepixelloop;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RCX, length;
			cmp		RCX, 16;
			jl		eightpixel;
		sixteenpixelloop:
			movups	XMM0, [RSI];
			movups	[RDI], XMM0;
			add		RSI, 16;
			add		RDI, 16;
			sub		RCX, 16;
			cmp		RCX, 16;
			jge		sixteenpixelloop;
		eightpixel:
			cmp		RCX, 8;
			jl		fourpixel;
			movq	XMM0, [RSI];
			movq	[RDI], XMM0;
			add		RSI, 8;
			add		RDI, 8;
			sub		RCX, 8;
		fourpixel:
			cmp		RCX, 4;
			jl		singlepixelloop;
			movd	XMM1, [RSI];
			movd	[RDI], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			sub		RCX, 4;
		singlepixelloop:
			cmp		RCX, 0;
			jz		end;
			mov		AL, [RSI];
			mov		[RDI], AL;
			cmp		RCX, 0;
			inc		RSI;
			inc		RDI;
			dec		RCX;
			jmp		singlepixelloop;
		end:
			;
		}
	}else{
		while(length){
			*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Two plus one operand blitter for 8 bit values. Automatic mask-generation is used from the source's color index with the following formula:
 * mask = src == 0x0000 ? 0xFFFF : 0x0000
 */
public @nogc void blitter16bit(ushort* src, ushort* dest, size_t length){
	version(X86){
		version(MMX){
			asm @nogc{
				pxor	MM7, MM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 4;
				jl		twopixel;
			fourpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, MM0;
				pcmpeqw	MM2, MM7;
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDI], MM1;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 4;
				jl		singlepixel;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movq	MM2, MM7;
				pcmpeqw	MM2, MM0;
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDI], MM1;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [ESI];
				cmp		AX, 0;
				cmovz	AX, [EDI];
				mov		[EDI], AL;
			end:
				emms;
			}
		}else{
			asm @nogc{
				pxor	XMM7, XMM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqw	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDI], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 8;
				cmp		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		twopixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqw	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDI], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 4;
			twopixel:
				cmp		ECX, 2;
				jl		singlepixel;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqw	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [ESI];
				cmp		AX, 0;
				cmovz	AX, [EDI];
				mov		[EDI], AX;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			pxor	XMM7, XMM7;
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RCX, length;
			cmp		RCX, 8;
			jl		fourpixel;
		eigthpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqw	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDI], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			sub		RCX, 8;
			cmp		RCX, 8;
			jge		eigthpixelloop;
		fourpixel:
			cmp		RCX, 4;
			jl		twopixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqw	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDI], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			sub		RCX, 4;
		twopixel:
			cmp		RCX, 2;
			jl		singlepixel;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqw	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
			add		RSI, 2;
			add		RDI, 2;
			sub		RCX, 2;
		singlepixel:
			cmp		RCX, 0;
			jz		end;
			mov		AX, [RSI];
			cmp		AX, 0;
			cmovz	AX, [RDI];
			mov		[RDI], AX;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, size_t length){
	version(X86){
		version(MMX){
				asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 4;
				//pxor	MM7, MM7;
				jl		twopixel;
			fourpixelloop:
				movq	MM0, [ESI];
				movq	[EDI], MM0;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 4;
				jl		singlepixel;
				movd	MM0, [ESI];
				movd	[EDI], MM0;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 2;
			singlepixel:
				cmp		ECX, 0;
				jz		end;
				mov		AX, [ESI];
				mov		[EDI], AL;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				//pxor	XMM7, XMM7;
				jl		fourpixel;
			eigthpixelloop:
				movups	XMM0, [ESI];
				movups	[EDI], XMM0;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 8;
				cmp		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		twopixel;
				movq	XMM0, [ESI];
				movq	[EDI], XMM0;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 4;
			twopixel:
				cmp		ECX, 2;
				jl		singlepixel;
				movd	XMM0, [ESI];
				movd	[EDI], XMM0;
				add		ESI, 4;
				add		EDI, 4;
				sub		ECX, 2;
			singlepixel:
				cmp		ECX, 0;
				jz		end;
				mov		AL, [ESI];
				mov		[EDI], AL;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RCX, length;
			cmp		RCX, 8;
			//pxor	XMM7, XMM7;
			jl		fourpixel;
		eigthpixelloop:
			movups	XMM0, [RSI];
			movups	[RDI], XMM0;
			add		RSI, 8;
			add		RDI, 8;
			sub		RCX, 8;
			cmp		RCX, 8;
			jge		eigthpixelloop;
		fourpixel:
			cmp		RCX, 4;
			jl		twopixel;
			movq	XMM0, [RSI];
			movq	[RDI], XMM0;
			add		RSI, 4;
			add		RDI, 4;
			sub		RCX, 4;
		twopixel:
			cmp		RCX, 2;
			jl		singlepixel;
			movd	XMM0, [RSI];
			movd	[RDI], XMM0;
			add		RSI, 2;
			add		RDI, 2;
			sub		RCX, 2;
		singlepixel:
			cmp		RCX, 0;
			jz		end;
			mov		AL, [RSI];;
			mov		[RDI], AL;
		end:
			;
		}
	}else{
		while(length){
			*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Two plus one operand blitter for 32 bit values. Automatic mask-generation is used from the source's alpha channel with the following formula:
 * mask = src.alpha == 0x00 ? 0xFFFFFFFF : 0x00000000
 */
public @nogc void blitter32bit(uint* src, uint* dest, size_t length){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				movq	MM6, ALPHABLEND_MMX_MASK;
				pxor	MM7, MM7;
				cmp		ECX, 2;
				jl		twopixel;
			twopixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, MM0;
				pand	MM2, MM6;
				pcmpeqd	MM2, MM7;
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDI], MM1;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 2;
				jge		fourpixelloop;
			onepixel:
				cmp		ECX, 1;
				jl		end;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movq	MM2, MM0;
				pand	MM2, MM6;
				pcmpeqd	MM2, MM7;
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDI], MM1;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				movups	XMM6, ALPHABLEND_SSE2_MASK;
				pxor	XMM7, XMM7;
				cmp		ECX, 8;
				jl		twopixel;
			fourpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, XMM0;
				pand	XMM2, XMM6;
				pcmpeqd	XMM2, XMM7;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDI], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 4;
				cmp		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 2;
				jl		onepixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, XMM0;
				pand	XMM2, XMM6;
				pcmpeqd	XMM2, XMM7;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDI], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 2;
			onepixel:
				cmp		ECX, 1;
				jl		end;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movq	XMM2, XMM0;
				pand	XMM2, XMM6;
				pcmpeqd	XMM2, XMM7;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RCX, length;
			movups	XMM6, ALPHABLEND_SSE2_MASK;
			pxor	XMM7, XMM7;
			cmp		ECX, 8;
			jl		twopixel;
		fourpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, XMM0;
			pand	XMM2, XMM6;
			pcmpeqd	XMM2, XMM7;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDI], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			sub		RCX, 4;
			cmp		RCX, 4;
			jge		fourpixelloop;
		twopixel:
			cmp		RCX, 2;
			jl		onepixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, XMM0;
			pand	XMM2, XMM6;
			pcmpeqd	XMM2, XMM7;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDI], XMM1;
			add		RSI, 2;
			add		RDI, 2;
			sub		RCX, 2;
		onepixel:
			cmp		RCX, 1;
			jl		end;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movq	XMM2, XMM0;
			pand	XMM2, XMM6;
			pcmpeqd	XMM2, XMM7;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
		end:
			;
		}
	}else{
		while(length){
			if(*cast(Pixel32Bit)src.ColorSpaceARGB.alpha)
				*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Implements a two plus one operand alpha-blending algorithm for 32bit bitmaps. Automatic alpha-mask generation follows this formula:
 * src[B,G,R,A] --> mask [A,A,A,A]
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, size_t length){
	version(X86){
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
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				movq	MM6, ALPHABLEND_MMX_MASK;
				pxor	MM7, MM7;
				cmp		ECX, 2;
				jl		twopixel;
			twopixelloop:
				movq	MM0, [ESI];
				movq	[EDI], MM0;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 2;
				jge		fourpixelloop;
			onepixel:
				cmp		ECX, 1;
				jl		end;
				movd	MM0, [ESI];;
				movd	[EDI], MM0;
				add		ESI, 2;
				add		EDI, 2;
				sub		ECX, 2;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		ECX, length;
				movups	XMM6, ALPHABLEND_SSE2_MASK;
				pxor	XMM7, XMM7;
				cmp		ECX, 8;
				jl		twopixel;
			eigthpixelloop:
				movups	XMM0, [ESI];
				movups	[EDI], XMM0;
				add		ESI, 16;
				add		EDI, 16;
				sub		ECX, 4;
				cmp		ECX, 4;
				jge		eigthpixelloop;
			twopixel:
				cmp		ECX, 2;
				jl		onepixel;
				movq	XMM0, [ESI];
				movq	[EDI], XMM0;
				add		ESI, 8;
				add		EDI, 8;
				sub		ECX, 2;
			onepixel:
				cmp		ECX, 1;
				jl		end;
				movd	XMM0, [ESI];
				movd	[EDI], XMM0;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RCX, length;
			movups	XMM6, ALPHABLEND_SSE2_MASK;
			pxor	XMM7, XMM7;
			cmp		ECX, 8;
			jl		twopixel;
		eigthpixelloop:
			movups	XMM0, [RSI];
			movups	[RDI], XMM0;
			add		RSI, 16;
			add		RDI, 16;
			sub		RCX, 4;
			cmp		RCX, 4;
			jge		eigthpixelloop;
		twopixel:
			cmp		RCX, 2;
			jl		onepixel;
			movq	XMM0, [RSI];
			movq	[RDI], XMM0;
			add		RSI, 8;
			add		RDI, 8;
			sub		RCX, 2;
		onepixel:
			cmp		RCX, 1;
			jl		end;
			movd	XMM0, [RSI];
			movd	[RDI], XMM0;
		end:
			;
		}
	}else{
		while(length){
			if(*src.ColorSpaceARGB.alpha)
				*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Three plus one operand blitter for 8 bit values. Uses an external mask.
 */
public @nogc void blitter8bit(ubyte* src, ubyte* dest, size_t length, ubyte* mask){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDI], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				sub		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movd	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDI], MM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				mov		AH, [EDI];
				and		AH, [EBX];
				or		AH, AL;
				mov		[EDI], AH;
				inc		ESI;
				inc		EDI;
				inc		EBX;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, length;
				cmp		ECX, 16;
				pxor	XMM7, XMM7;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDI], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				add		EBX, 16;
				sub		ECX, 16;
				cmp		ECX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		ECX, 8;
				jl		fourpixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDI], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				sub		ECX, 8;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movd	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				mov		AH, [EDI];
				and		AH, [EBX];
				or		AH, AL;
				mov		[EDI], AH;
				inc		ESI;
				inc		EDI;
				inc		EBX;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RBX, mask[RBP];
			mov		RCX, length;
			cmp		RCX, 16;
			//pxor	XMM7, XMM7;
			jl		eightpixel;
		sixteenpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDI], XMM1;
			add		RSI, 16;
			add		RDI, 16;
			add		RBX, 16;
			sub		RCX, 16;
			cmp		RCX, 16;
			jge		sixteenpixelloop;
		eightpixel:
			cmp		RCX, 8;
			jl		fourpixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDI], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RBX, 8;
			sub		RCX, 8;
		fourpixel:
			cmp		RCX, 4;
			jl		singlepixelloop;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			add		RBX, 4;
			sub		RCX, 4;
		singlepixelloop:
			cmp		RCX, 0;
			jz		end;
			mov		AL, [RSI];
			mov		AH, [RDI];
			and		AH, [RBX];
			or		AH, AL;
			mov		[RDI], AH;
			inc		RSI;
			inc		RDI;
			inc		RBX;
			dec		RCX;
			jmp		singlepixelloop;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest = (*dest & *mask) | *src;
			src++;
			dest++;
			mask++;
			length--;
		}
	}
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Mask is placeholder.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, size_t length, ubyte* mask){
	copy8bit(src,dest,length);
}
/**
 * Three plus one operand blitter for 8 bit values. An external mask is used for this operation.
 */
public @nogc void blitter16bit(ushort* src, ushort* dest, size_t length, ushort* mask){
	version(X86){
		version(MMX){
			asm @nogc{
				pxor	MM7, MM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, length;
				cmp		ECX, 4;
				jl		twopixel;
			fourpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDI], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				sub		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 4;
				jl		singlepixel;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movd	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDI], MM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [EBX];
				and		AX, [EDI];
				or		AX, [ESI];
				mov		[EDI], AX;
			end:
				emms;
			}
		}else{
			asm @nogc{
				pxor	XMM7, XMM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDI], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				add		EBX, 16;
				sub		ECX, 8;
				cmp		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		twopixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDI], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				sub		ECX, 4;
			twopixel:
				cmp		ECX, 2;
				jl		singlepixel;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movd	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [EBX];
				and		AX, [EDI];
				or		AX, [ESI];
				mov		[EDI], AX;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			pxor	XMM7, XMM7;
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RBX, mask[RBP];
			mov		RCX, length;
			cmp		RCX, 8;
			jl		fourpixel;
		eigthpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDI], XMM1;
			add		RSI, 16;
			add		RDI, 16;
			add		RBX, 16;
			sub		RCX, 8;
			cmp		RCX, 8;
			jge		eigthpixelloop;
		fourpixel:
			cmp		RCX, 4;
			jl		twopixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDI], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RBX, 8;
			sub		RCX, 4;
		twopixel:
			cmp		RCX, 2;
			jl		singlepixel;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movd	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			add		RBX, 4;
			sub		RCX, 2;
		singlepixel:
			cmp		RCX, 0;
			jz		end;
			mov		AX, [RBX];
			and		AX, [RDI];
			or		AX, [RSI];
			mov		[RDI], AX;
		end:
			;
		}
	}else{
		while(length){
			*dest = (*dest & *mask) | *src;
			src++;
			dest++;
			mask++;
			length--;
		}
	}
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Mask is a placeholder for easy exchangeability with other functions.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, size_t length, ushort* mask){
	copy16bit(src,dest,length);
}
/**
 * Two plus one operand blitter for 32 bit values. A separate mask is used for the operation.
 */
public @nogc void blitter32bit(uint* src, uint* dest, size_t length, uint* mask){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, length;
				movq	MM6, ALPHABLEND_MMX_MASK;
				pxor	MM7, MM7;
				cmp		ECX, 2;
				jl		twopixel;
			twopixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDI], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				sub		ECX, 2;
				jge		fourpixelloop;
			onepixel:
				jecxz	end;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movd	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDI], MM1;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		ECX, length;
				movups	XMM6, ALPHABLEND_SSE2_MASK;
				pxor	XMM7, XMM7;
				cmp		ECX, 4;
				jl		twopixel;
			fourpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDI], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				add		EBX, 16;
				sub		ECX, 4;
				cmp		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 2;
				jl		onepixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDI], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				sub		ECX, 2;
			onepixel:
				jecxz	end;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movd	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDI], XMM1;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RBX, mask[RBP];
			mov		RCX, length;
			movups	XMM6, ALPHABLEND_SSE2_MASK;
			pxor	XMM7, XMM7;
			cmp		ECX, 4;
			jl		twopixel;
		fourpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDI], XMM1;
			add		RSI, 16;
			add		RDI, 16;
			add		RBX, 16;
			sub		RCX, 4;
			cmp		RCX, 4;
			jge		fourpixelloop;
		twopixel:
			cmp		RCX, 2;
			jl		onepixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDI], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RBX, 8;
			sub		RCX, 2;
		onepixel:
			cmp		RCX, 1;
			jl		end;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movd	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
		end:
			;
		}
	}else{
		while(length){
			dest.base = (dest.base & mask.base) | src.base;
			mask++;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Implements a three plus one operand alpha-blending algorithm for 32bit bitmaps. For masking, use Pixel32Bit.AlphaMask from CPUblit.colorspaces.
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, size_t length, uint* mask){
	version(X86){
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
 * Two plus one operand blitter for 8 bit values. Automatic mask-generation is used from the source's color index with the following formula:
 * mask = src == 0x00 ? 0xFF : 0x00
 * Final values are copied into memory location specified by dest1.
 */
public @nogc void blitter8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length){
	version(X86){
		version(MMX){
			asm @nogc{
				pxor	MM7, MM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, MM7;
				pcmpeqb	MM2, MM0;
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDX], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				sub		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movq	MM2, MM7;
				pcmpeqb	MM2, MM0;
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDX], MM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EDX, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				cmp		AL, 0;
				jz		step;
				mov		AL, [EDI];
			step:
				mov		[EDX], AL;
				cmp		ECX, 0;
				inc		ESI;
				inc		EDI;
				inc		EDX;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				emms;
			}
		}else{
			asm @nogc{
				pxor	XMM7, XMM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				cmp		ECX, 16;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDX], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				add		EDX, 16;
				sub		ECX, 16;
				cmp		ECX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		ECX, 8;
				jl		fourpixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDX], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				sub		ECX, 8;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqb	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDX], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EDX, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				cmp		AL, 0;
				jz		step;
				mov		AL, [EDI];
			step:
				mov		[EDX], AL;
				cmp		ECX, 0;
				inc		ESI;
				inc		EDI;
				inc		EDX;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			pxor	XMM7, XMM7;
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RDX, dest1[RBP];
			mov		RCX, length;
			cmp		RCX, 16;
			jl		eightpixel;
		sixteenpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqb	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDX], XMM1;
			add		RSI, 16;
			add		RDI, 16;
			add		RDX, 16;
			sub		RCX, 16;
			cmp		RCX, 16;
			jge		sixteenpixelloop;
		eightpixel:
			cmp		RCX, 8;
			jl		fourpixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqb	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDX], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RDI, 8;
			sub		RCX, 8;
		fourpixel:
			cmp		RCX, 4;
			jl		singlepixelloop;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqb	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDX], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			add		RDI, 4;
			sub		RCX, 4;
		singlepixelloop:
			cmp		RCX, 0;
			jz		end;
			mov		AL, [RSI];
			cmp		AL, 0;
			jz		step;
			mov		AL, [EDI];
		step:
			mov		[RDI], AL;
			cmp		RCX, 0;
			inc		RSI;
			inc		RDI;
			inc		RDX;
			dec		RCX;
			jmp		singlepixelloop;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest = *src;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length){
	copy8bit(src,dest1,length);
}
/**
 * Three plus one operand blitter for 8 bit values. Automatic mask-generation is used from the source's color index with the following formula:
 * mask = src == 0x0000 ? 0xFFFF : 0x0000
 * Result is copied into memory location specified by dest1.
 */
public @nogc void blitter16bit(ushort* src, ushort* dest, ushort* dest1, size_t length){
		version(X86){
		version(MMX){
			asm @nogc{
				pxor	MM7, MM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 4;
				jl		twopixel;
			fourpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, MM0;
				pcmpeqw	MM2, MM7;
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDX], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				sub		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 4;
				jl		singlepixel;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movq	MM2, MM7;
				pcmpeqw	MM2, MM0;
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDX], MM1;
				add		ESI, 2;
				add		EDI, 2;
				add		EDX, 2;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [ESI];
				cmp		AX, 0;
				cmovz	AX, [EDI];
				mov		[EDX], AL;
			end:
				emms;
			}
		}else{
			asm @nogc{
				pxor	XMM7, XMM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqw	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDX], XMM1;
				add		ESI,16;
				add		EDI,16;
				add		EDX,16;
				sub		ECX, 8;
				cmp		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		twopixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqw	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDX], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				sub		ECX, 4;
			twopixel:
				cmp		ECX, 2;
				jl		singlepixel;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movups	XMM2, XMM7;
				pcmpeqw	XMM2, XMM0;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDX], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EDX, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [ESI];
				cmp		AX, 0;
				cmovz	AX, [EDI];
				mov		[EDX], AX;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			pxor	XMM7, XMM7;
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RDX, dest1[RBP];
			mov		RCX, length;
			cmp		RCX, 8;
			jl		fourpixel;
		eigthpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqw	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDX], XMM1;
			add		RSI,16;
			add		RDI,16;
			add		RDX,16;
			sub		RCX, 8;
			cmp		RCX, 8;
			jge		eigthpixelloop;
		fourpixel:
			cmp		RCX, 4;
			jl		twopixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqw	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDX], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RDX, 8;
			sub		RCX, 4;
		twopixel:
			cmp		RCX, 2;
			jl		singlepixel;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movups	XMM2, XMM7;
			pcmpeqw	XMM2, XMM0;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDX], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			add		RDX, 4;
			sub		RCX, 2;
		singlepixel:
			cmp		RCX, 0;
			jz		end;
			mov		AX, [RSI];
			cmp		AX, 0;
			cmovz	AX, [RDI];
			mov		[RDX], AX;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest1 = *src;
			else
				*dest1 = *dest;
			src++;
			dest++;
			length--;
		}
	}
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Dest is placeholder.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, ushort* dest1, size_t length){
	copy16bit(src,dest1,length);
}
/**
 * Three plus one operand blitter for 32 bit values. Automatic mask-generation is used from the source's alpha channel with the following formula:
 * mask = src.alpha ? 0xFFFFFFFF : 0x00000000
 * The result is copied into the memory location specified by dest1
 */
public @nogc void blitter32bit(uint* src, uint* dest, uint* dest1, size_t length){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				movq	MM6, ALPHABLEND_MMX_MASK;
				pxor	MM7, MM7;
				cmp		ECX, 2;
				jl		twopixel;
			twopixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, MM0;
				pand	MM2, MM6;
				pcmpeqd	MM2, MM7;
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDX], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				sub		ECX, 2;
				jge		fourpixelloop;
			onepixel:
				cmp		ECX, 1;
				jl		end;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movq	MM2, MM0;
				pand	MM2, MM6;
				pcmpeqd	MM2, MM7;
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDX], MM1;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				movups	XMM6, ALPHABLEND_SSE2_MASK;
				pxor	XMM7, XMM7;
				cmp		ECX, 8;
				jl		twopixel;
			fourpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, XMM0;
				pand	XMM2, XMM6;
				pcmpeqd	XMM2, XMM7;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDX], XMM1;
				add		ESI,16;
				add		EDI,16;
				add		EDX,16;
				sub		ECX, 4;
				cmp		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 2;
				jl		onepixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, XMM0;
				pand	XMM2, XMM6;
				pcmpeqd	XMM2, XMM7;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDX], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EDX, 8;
				sub		ECX, 2;
			onepixel:
				cmp		ECX, 1;
				jl		end;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movq	XMM2, XMM0;
				pand	XMM2, XMM6;
				pcmpeqd	XMM2, XMM7;
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDX], XMM1;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RDX, dest1[RBP];
			mov		RCX, length;
			movups	XMM6, ALPHABLEND_SSE2_MASK;
			pxor	XMM7, XMM7;
			cmp		ECX, 8;
			jl		twopixel;
		fourpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, XMM0;
			pand	XMM2, XMM6;
			pcmpeqd	XMM2, XMM7;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDX], XMM1;
			add		RSI,16;
			add		RDI,16;
			add		RDX,16;
			sub		RCX, 4;
			cmp		RCX, 4;
			jge		fourpixelloop;
		twopixel:
			cmp		RCX, 2;
			jl		onepixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, XMM0;
			pand	XMM2, XMM6;
			pcmpeqd	XMM2, XMM7;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDX], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RDX, 8;
			sub		RCX, 2;
		onepixel:
			cmp		RCX, 1;
			jl		end;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movq	XMM2, XMM0;
			pand	XMM2, XMM6;
			pcmpeqd	XMM2, XMM7;
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDI], XMM1;
		end:
			;
		}
	}else{
		while(length){
			if(*src.ColorSpaceARGB.alpha)
				*dest1 = *src;
			else
				*dest1 = *dest;
			src++;
			dest++;
			dest1++;
			length--;
		}
	}
}
/**
 * Implements a three plus one operand alpha-blending algorithm for 32bit bitmaps. Automatic alpha-mask generation follows this formula:
 * src[B,G,R,A] --> mask [A,A,A,A]
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, uint* dest1, size_t length){
	version(X86){
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
 * Four plus one operand blitter for 8 bit values. Uses an external mask. Final values are copied into memory location specified by dest1;
 */
public @nogc void blitter8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length, ubyte* mask){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDX], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				sub		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movd	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDX], MM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				add		EDX, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				mov		AH, [EDI];
				and		AH, [EBX];
				or		AH, AL;
				mov		[EDX], AH;
				inc		ESI;
				inc		EDI;
				inc		EBX;
				inc		EDX;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				cmp		ECX, 16;
				pxor	XMM7, XMM7;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDX], XMM1;
				add		ESI, 16;
				add		EDI, 16;
				add		EBX, 16;
				add		EDX, 16;
				sub		ECX, 16;
				cmp		ECX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		ECX, 8;
				jl		fourpixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDX], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				sub		ECX, 8;
			fourpixel:
				cmp		ECX, 4;
				jl		singlepixelloop;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movd	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDX], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				add		EDX, 4;
				sub		ECX, 4;
			singlepixelloop:
				//cmp		ECX, 0;
				jecxz	end;
				mov		AL, [ESI];
				mov		AH, [EDI];
				and		AH, [EBX];
				or		AH, AL;
				mov		[EDX], AH;
				inc		ESI;
				inc		EDI;
				inc		EBX;
				inc		EDX;
				dec		ECX;
				jmp		singlepixelloop;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RBX, mask[RBP];
			mov		RDX, dest1[RBP];
			mov		RCX, length;
			cmp		RCX, 16;
			//pxor	XMM7, XMM7;
			jl		eightpixel;
		sixteenpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDX], XMM1;
			add		RSI, 16;
			add		RDI, 16;
			add		RBX, 16;
			add		RDX, 16;
			sub		RCX, 16;
			cmp		RCX, 16;
			jge		sixteenpixelloop;
		eightpixel:
			cmp		RCX, 8;
			jl		fourpixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDX], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RBX, 8;
			add		RDX, 8;
			sub		RCX, 8;
		fourpixel:
			cmp		RCX, 4;
			jl		singlepixelloop;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDX], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			add		RBX, 4;
			add		RDX, 4;
			sub		RCX, 4;
		singlepixelloop:
			cmp		RCX, 0;
			jz		end;
			mov		AL, [RSI];
			mov		AH, [RDI];
			and		AH, [RBX];
			or		AH, AL;
			mov		[RDX], AH;
			inc		RSI;
			inc		RDI;
			inc		RBX;
			inc		RDX;
			dec		RCX;
			jmp		singlepixelloop;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest1 = (*dest & *mask) | *src;
			src++;
			dest++;
			dest1++;
			mask++;
			length--;
		}
	}
}
/**
 * Copies an 8bit image onto another without blitter. No transparency is used. Dest and mask are placeholders.
 */
public @nogc void copy8bit(ubyte* src, ubyte* dest, ubyte* dest1, size_t length, ubyte* mask){
	copy8bit(src,dest1,length);
}
/**
 * Four plus one operand blitter for 8 bit values. Uses external mask. Copies the result to the memory location specified by dest1.
 */
public @nogc void blitter16bit(ushort* src, ushort* dest, ushort* dest1, size_t length, ushort* mask){
	version(X86){
		version(MMX){
			asm @nogc{
				pxor	MM7, MM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest[EBP];
				mov		ECX, length;
				cmp		ECX, 4;
				jl		twopixel;
			fourpixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDX], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				sub		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 4;
				jl		singlepixel;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movd	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDX], MM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				add		EDX, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [EBX];
				and		AX, [EDI];
				or		AX, [ESI];
				mov		[EDX], AX;
			end:
				emms;
			}
		}else{
			asm @nogc{
				pxor	XMM7, XMM7;
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				cmp		ECX, 8;
				jl		fourpixel;
			eigthpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDX], XMM1;
				add		ESI,16;
				add		EDI,16;
				add		EBX,16;
				add		EDX,16;
				sub		ECX, 8;
				cmp		ECX, 8;
				jge		eigthpixelloop;
			fourpixel:
				cmp		ECX, 4;
				jl		twopixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDX], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				sub		ECX, 4;
			twopixel:
				cmp		ECX, 2;
				jl		singlepixel;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movd	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDX], XMM1;
				add		ESI, 4;
				add		EDI, 4;
				add		EBX, 4;
				add		EDX, 4;
				sub		ECX, 2;
			singlepixel:
				//cmp		ECX, 0;
				jecxz		end;
				mov		AX, [EBX];
				and		AX, [EDI];
				or		AX, [ESI];
				mov		[EDX], AX;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			pxor	XMM7, XMM7;
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RBX, mask[RBP];
			mov		RDX, dest1[RBP];
			mov		RCX, length;
			cmp		RCX, 8;
			jl		fourpixel;
		eigthpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDX], XMM1;
			add		RSI,16;
			add		RDI,16;
			add		RBX,16;
			add		RDX,16;
			sub		RCX, 8;
			cmp		RCX, 8;
			jge		eigthpixelloop;
		fourpixel:
			cmp		RCX, 4;
			jl		twopixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDX], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RBX, 8;
			add		RDX, 8;
			sub		RCX, 4;
		twopixel:
			cmp		RCX, 2;
			jl		singlepixel;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movd	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDX], XMM1;
			add		RSI, 4;
			add		RDI, 4;
			add		RBX, 4;
			add		RDX, 4;
			sub		RCX, 2;
		singlepixel:
			cmp		RCX, 0;
			jz		end;
			mov		AX, [RBX];
			and		AX, [RDI];
			or		AX, [RSI];
			mov		[RDX], AX;
		end:
			;
		}
	}else{
		while(length){
			if(*src)
				*dest1 = *src;
			else
				*dest1 = *dest;
			src++;
			dest++;
			dest1++;
			length--;
		}
	}
}
/**
 * Copies a 16bit image onto another without blitter. No transparency is used. Dest and mask is placeholder.
 */
public @nogc void copy16bit(ushort* src, ushort* dest, ushort* dest1, size_t length, ushort* mask){
	copy16bit(src,dest1,length);
}
/**
 * Two plus one operand blitter for 32 bit values. Uses a separate mask. Copies the result into location specified by dest1.
 */
public @nogc void blitter32bit(uint* src, uint* dest, uint* dest1, size_t length, uint* mask){
	version(X86){
		version(MMX){
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				movq	MM6, ALPHABLEND_MMX_MASK;
				pxor	MM7, MM7;
				cmp		ECX, 2;
				jl		twopixel;
			twopixelloop:
				movq	MM0, [ESI];
				movq	MM1, [EDI];
				movq	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movq	[EDX], MM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				sub		ECX, 2;
				jge		fourpixelloop;
			onepixel:
				jecxz	end;
				movd	MM0, [ESI];
				movd	MM1, [EDI];
				movd	MM2, [EBX];
				pand	MM1, MM2;
				por		MM1, MM0;
				movd	[EDX], MM1;
			end:
				emms;
			}
		}else{
			asm @nogc{
				mov		ESI, src[EBP];
				mov		EDI, dest[EBP];
				mov		EBX, mask[EBP];
				mov		EDX, dest1[EBP];
				mov		ECX, length;
				movups	XMM6, ALPHABLEND_SSE2_MASK;
				pxor	XMM7, XMM7;
				cmp		ECX, 4;
				jl		twopixel;
			fourpixelloop:
				movups	XMM0, [ESI];
				movups	XMM1, [EDI];
				movups	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movups	[EDX], XMM1;
				add		ESI,16;
				add		EDI,16;
				add		EBX,16;
				add		EDX,16;
				sub		ECX, 4;
				cmp		ECX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		ECX, 2;
				jl		onepixel;
				movq	XMM0, [ESI];
				movq	XMM1, [EDI];
				movq	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movq	[EDX], XMM1;
				add		ESI, 8;
				add		EDI, 8;
				add		EBX, 8;
				add		EDX, 8;
				sub		ECX, 2;
			onepixel:
				jecxz	end;
				movd	XMM0, [ESI];
				movd	XMM1, [EDI];
				movd	XMM2, [EBX];
				pand	XMM1, XMM2;
				por		XMM1, XMM0;
				movd	[EDX], XMM1;
			end:
				;
			}
		}
	}else version(X86_64){
		asm @nogc{
			mov		RSI, src[RBP];
			mov		RDI, dest[RBP];
			mov		RBX, mask[RBP];
			mov		RDX, dest1[RBP];
			mov		RCX, length;
			movups	XMM6, ALPHABLEND_SSE2_MASK;
			pxor	XMM7, XMM7;
			cmp		ECX, 4;
			jl		twopixel;
		fourpixelloop:
			movups	XMM0, [RSI];
			movups	XMM1, [RDI];
			movups	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movups	[RDX], XMM1;
			add		RSI,16;
			add		RDI,16;
			add		RBX,16;
			add		RDX,16;
			sub		RCX, 4;
			cmp		RCX, 4;
			jge		fourpixelloop;
		twopixel:
			cmp		RCX, 2;
			jl		onepixel;
			movq	XMM0, [RSI];
			movq	XMM1, [RDI];
			movq	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movq	[RDX], XMM1;
			add		RSI, 8;
			add		RDI, 8;
			add		RBX, 8;
			add		RDX, 8;
			sub		RCX, 2;
		onepixel:
			cmp		RCX, 1;
			jl		end;
			movd	XMM0, [RSI];
			movd	XMM1, [RDI];
			movd	XMM2, [RBX];
			pand	XMM1, XMM2;
			por		XMM1, XMM0;
			movd	[RDX], XMM1;
		end:
			;
		}
	}else{
		while(length){
			dest1.base = (dest.base & mask.base) | src.base;
			mask++;
			src++;
			dest++;
			dest1++;
			length--;
		}
	}
}
/**
 * Implements a four plus one operand alpha-blending algorithm for 32bit bitmaps. For masking, use Pixel32Bit.AlphaMask from CPUblit.colorspaces.
 * Output is copied into a memory location specified by dest1.
 */
public @nogc void alphaBlend32bit(uint* src, uint* dest, uint* dest1, size_t length, uint* mask){
	version(X86){
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
 * 3 + 1 operand XOR blitter. 
 */
public @nogc void xorBlitter(T)(T* src, T* dest, T* dest1, size_t length){
	static if(T == "ubyte"){
		version(X86){
			version(MMX){
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 8;
					jl		fourpixel;
				eightpixelloop:
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					add		EDX, 8;
					sub		ECX, 8;
					cmp		ECX, 8;
					jge		eightpixelloop;
				fourpixel:
					cmp		ECX, 4;
					jl		singlepixelloop;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					add		EDX, 4;
					sub		ECX, 4;
					cmp		ECX, 0;
					jle		end;
				singlepixelloop:
					mov		AL, [ESI];
					xor		AL, [EDI];
					mov		[EDX], AL;
					inc		ESI;
					inc		EDI;
					loop	singlepixelloop;
				end:
					emms;
				}
			}else{
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 16;
					jl		eightpixel;
				sixteenpixelloop:
					movups	XMM0, [ESI];
					movups	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movups	[EDX], XMM0;
					add		ESI, 16;
					add		EDI, 16;
					add		EDX, 16;
					sub		ECX, 16;
					cmp		ECX, 16;
					jge		sixteenpixelloop;
				eightpixel:
					cmp		ECX, 8;
					jl		fourpixel;
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					add		EDX, 8;
					sub		ECX, 8;
				fourpixel:
					cmp		ECX, 4;
					jl		singlepixelloop;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					add		EDX, 4;
					sub		ECX, 4;
					cmp		ECX, 0;
					jle		end;
				singlepixelloop:
					mov		AL, [ESI];
					xor		AL, [EDI];
					mov		[EDX], AL;
					inc		ESI;
					inc		EDI;
					loop	singlepixelloop;
				end:
					;
				}
			}
		}else version(X86_64){
			asm @nogc{
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RDX, dest1[RBP];
				mov		RCX, length;
				cmp		RCX, 16;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [RSI];
				movups	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movups	[RDX], XMM0;
				add		RSI, 16;
				add		RDI, 16;
				add		RDX, 16;
				sub		RCX, 16;
				cmp		RCX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		RCX, 8;
				jl		fourpixel;
				movq	XMM0, [RSI];
				movq	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movq	[RDX], XMM0;
				add		RSI, 8;
				add		RDI, 8;
				add		RDX, 8;
				sub		RCX, 8;
			fourpixel:
				cmp		RCX, 4;
				jl		singlepixelloop;
				movd	XMM0, [RSI];
				movd	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movd	[RDX], XMM0;
				add		RSI, 4;
				add		RDI, 4;
				add		RDX, 4;
				sub		RCX, 4;
				cmp		RCX, 0;
				jle		end;
			singlepixelloop:
				mov		AL, [RSI];
				xor		AL, [RDI];
				mov		[RDX], AL;
				inc		RSI;
				inc		RDI;
				loop	singlepixelloop;
			end:
				;
			}
		}else{
			while(lenght){
				*dest1 = *src ^ *dest;
				src++;
				dest++;
				dest1++;
				length--;
			}
		}
	}else static if(T == "ushort"){
		version(X86){
			version(MMX){
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 4;
					jl		twopixel;
				fourpixelloop:
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					add		EDX, 8;
					sub		ECX, 4;
					cmp		ECX, 4;
					jge		fourpixelloop;
				twopixel:
					cmp		ECX, 4;
					jl		onepixel;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					add		EDX, 4;
					sub		ECX, 2;
					cmp		ECX, 0;
					jle		end;
				onepixel:
					mov		AX, [ESI];
					xor		AX, [EDI];
					mov		[EDX], AX;
				end:
					emms;
				}
			}else{
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 8;
					jl		fourpixel;
				eightpixelloop:
					movups	XMM0, [ESI];
					movups	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movups	[EDX], XMM0;
					add		ESI,16;
					add		EDI,16;
					add		EDX,16;
					sub		ECX, 8;
					cmp		ECX, 8;
					jge		eightpixelloop;
				fourpixel:
					cmp		ECX, 4;
					jl		twopixel;
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					add		EDX, 8;
					sub		ECX, 4;
				twopixel:
					cmp		ECX, 2;
					jl		onepixel;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					add		EDX, 4;
					sub		ECX, 2;
					cmp		ECX, 0;
					jle		end;
				onepixel:
					mov		AX, [ESI];
					xor		AX, [EDI];
					mov		[EDX], AX;
				end:
					;
				}
			}
		}else version(X86_64){
			asm @nogc{
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RDX, dest1[RBP];
				mov		RCX, length;
				cmp		RCX, 8;
				jl		fourpixel;
			eightpixelloop:
				movups	XMM0, [RSI];
				movups	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movups	[RDX], XMM0;
				add		RSI,16;
				add		RDI,16;
				add		RDX,16;
				sub		RCX, 8;
				cmp		RCX, 8;
				jge		eightpixelloop;
			fourpixel:
				cmp		RCX, 4;
				jl		twopixel;
				movq	XMM0, [RSI];
				movq	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movq	[RDX], XMM0;
				add		RSI, 8;
				add		RDI, 8;
				add		RDX, 8;
				sub		RCX, 4;
			twopixel:
				cmp		RCX, 2;
				jl		singlepixelloop;
				movd	XMM0, [RSI];
				movd	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movd	[RDX], XMM0;
				add		RSI, 4;
				add		RDI, 4;
				add		RDX, 4;
				sub		RCX, 2;
				cmp		RCX, 0;
				jle		end;
			onepixel:
				mov		AX, [RSI];
				xor		AX, [RDI];
				mov		[RDX], AX;
			end:
				;
			}
		}else{
			while(lenght){
				*dest1 = *src ^ *dest;
				src++;
				dest++;
				dest1++;
				length--;
			}
		}
	}
	static if(T == "uint"){
		version(X86){
			version(MMX){
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 2;
					jl		onepixel;
				twopixelloop:
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					add		EDX, 8;
					sub		ECX, 2;
					cmp		ECX, 2;
					jge		twopixelloop;
				onepixel:
					cmp		ECX, 1;
					jl		end;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
				end:
					emms;
				}
			}else{
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 4;
					jl		twopixel;
				fourpixelloop:
					movups	XMM0, [ESI];
					movups	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movups	[EDX], XMM0;
					add		ESI,16;
					add		EDI,16;
					add		EDX,16;
					sub		ECX, 4;
					cmp		ECX, 4;
					jge		fourpixelloop;
				twopixel:
					cmp		ECX, 2;
					jl		onepixel;
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					add		EDX, 8;
					sub		ECX, 2;
				onepixel:
					cmp		ECX, 1;
					jl		end;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
					
				end:
					;
				}
			}
		}else version(X86_64){
			asm @nogc{
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RDX, dest1[RBP];
				mov		RCX, length;
				cmp		RCX, 4;
				jl		twopixel;
			fourpixelloop:
				movups	XMM0, [RSI];
				movups	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movups	[RDX], XMM0;
				add		RSI,16;
				add		RDI,16;
				add		RDX,16;
				sub		RCX, 4;
				cmp		RCX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		RCX, 2;
				jl		onepixel;
				movq	XMM0, [RSI];
				movq	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movq	[RDX], XMM0;
				add		RSI, 2;
				add		RDI, 2;
				add		RDX, 2;
				sub		RCX, 2;
			onepixel:
				cmp		RCX, 1;
				jl		end;
				movd	XMM0, [RSI];
				movd	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movd	[RDX], XMM0;
			end:
				;
			}
		}else{
			while(lenght){
				*dest1 = *src ^ *dest;
				src++;
				dest++;
				dest1++;
				length--;
			}
		}
	}
}
/**
 * 2 + 1 operand XOR blitter. 
 */
public @nogc void xorBlitter(T)(T* src, T* dest, size_t length){
	static if(T == "ubyte"){
		version(X86){
			version(MMX){
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		ECX, length;
					cmp		ECX, 8;
					jl		fourpixel;
				eightpixelloop:
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDI], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					sub		ECX, 8;
					cmp		ECX, 8;
					jge		eightpixelloop;
				fourpixel:
					cmp		ECX, 4;
					jl		singlepixelloop;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDI], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					sub		ECX, 4;
					cmp		ECX, 0;
					jle		end;
				singlepixelloop:
					mov		AL, [ESI];
					xor		AL, [EDI];
					mov		[EDI], AL;
					inc		ESI;
					inc		EDI;
					loop	singlepixelloop;
				end:
					emms;
				}
			}else{
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		ECX, length;
					cmp		ECX, 16;
					jl		eightpixel;
				sixteenpixelloop:
					movups	XMM0, [ESI];
					movups	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movups	[EDI], XMM0;
					add		ESI, 16;
					add		EDI, 16;
					sub		ECX, 16;
					cmp		ECX, 16;
					jge		sixteenpixelloop;
				eightpixel:
					cmp		ECX, 8;
					jl		fourpixel;
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDI], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					sub		ECX, 8;
				fourpixel:
					cmp		ECX, 4;
					jl		singlepixelloop;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDI], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					sub		ECX, 4;
					cmp		ECX, 0;
					jle		end;
				singlepixelloop:
					mov		AL, [ESI];
					xor		AL, [EDI];
					mov		[EDI], AL;
					inc		ESI;
					inc		EDI;
					loop	singlepixelloop;
				end:
					;
				}
			}
		}else version(X86_64){
			asm @nogc{
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RCX, length;
				cmp		RCX, 16;
				jl		eightpixel;
			sixteenpixelloop:
				movups	XMM0, [RSI];
				movups	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movups	[RDI], XMM0;
				add		RSI, 16;
				add		RDI, 16;
				sub		RCX, 16;
				cmp		RCX, 16;
				jge		sixteenpixelloop;
			eightpixel:
				cmp		RCX, 8;
				jl		fourpixel;
				movq	XMM0, [RSI];
				movq	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movq	[RDI], XMM0;
				add		RSI, 8;
				add		RDI, 8;
				sub		RCX, 8;
			fourpixel:
				cmp		RCX, 4;
				jl		singlepixelloop;
				movd	XMM0, [RSI];
				movd	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movd	[RDI], XMM0;
				add		RSI, 4;
				add		RDI, 4;
				sub		RCX, 4;
				cmp		RCX, 0;
				jle		end;
			singlepixelloop:
				mov		AL, [RSI];
				xor		AL, [RDI];
				mov		[RDI], AL;
				inc		RSI;
				inc		RDI;
				loop	singlepixelloop;
			end:
				;
			}
		}else{
			while(lenght){
				*dest1 = *src ^ *dest;
				src++;
				dest++;
				dest1++;
				length--;
			}
		}
	}else static if(T == "ushort"){
		version(X86){
			version(MMX){
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		ECX, length;
					cmp		ECX, 4;
					jl		twopixel;
				fourpixelloop:
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDI], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					sub		ECX, 4;
					cmp		ECX, 4;
					jge		fourpixelloop;
				twopixel:
					cmp		ECX, 4;
					jl		onepixel;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDX], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					sub		ECX, 2;
					cmp		ECX, 0;
					jle		end;
				onepixel:
					mov		AX, [ESI];
					xor		AX, [EDI];
					mov		[EDI], AX;
				end:
					emms;
				}
			}else{
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		EDX, dest1[EBP];
					mov		ECX, length;
					cmp		ECX, 8;
					jl		fourpixel;
				eightpixelloop:
					movups	XMM0, [ESI];
					movups	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movups	[EDX], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					sub		ECX, 8;
					cmp		ECX, 8;
					jge		eightpixelloop;
				fourpixel:
					cmp		ECX, 4;
					jl		twopixel;
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDI], XMM0;
					add		ESI, 4;
					add		EDI, 4;
					sub		ECX, 4;
				twopixel:
					cmp		ECX, 2;
					jl		onepixel;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDI], XMM0;
					add		ESI, 2;
					add		EDI, 2;
					sub		ECX, 2;
					cmp		ECX, 0;
					jle		end;
				onepixel:
					mov		AX, [ESI];
					xor		AX, [EDI];
					mov		[EDI], AX;
				end:
					;
				}
			}
		}else version(X86_64){
			asm @nogc{
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RCX, length;
				cmp		RCX, 8;
				jl		fourpixel;
			eightpixelloop:
				movups	XMM0, [RSI];
				movups	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movups	[RDI], XMM0;
				add		RSI, 8;
				add		RDI, 8;
				sub		RCX, 8;
				cmp		RCX, 8;
				jge		eightpixelloop;
			fourpixel:
				cmp		RCX, 4;
				jl		twopixel;
				movq	XMM0, [RSI];
				movq	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movq	[RDI], XMM0;
				add		RSI, 4;
				add		RDI, 4;
				sub		RCX, 4;
			twopixel:
				cmp		RCX, 2;
				jl		singlepixelloop;
				movd	XMM0, [RSI];
				movd	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movd	[RDI], XMM0;
				add		RSI, 2;
				add		RDI, 2;
				sub		RCX, 2;
				cmp		RCX, 0;
				jle		end;
			onepixel:
				mov		AX, [RSI];
				xor		AX, [RDI];
				mov		[RDI], AX;
			end:
				;
			}
		}else{
			while(lenght){
				*dest1 = *src ^ *dest;
				src++;
				dest++;
				dest1++;
				length--;
			}
		}
	}
	static if(T == "uint"){
		version(X86){
			version(MMX){
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		ECX, length;
					cmp		ECX, 2;
					jl		onepixel;
				twopixelloop:
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDI], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					sub		ECX, 2;
					cmp		ECX, 2;
					jge		twopixelloop;
				onepixel:
					cmp		ECX, 1;
					jl		end;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDI], XMM0;
				end:
					emms;
				}
			}else{
				asm @nogc{
					mov		ESI, src[EBP];
					mov		EDI, dest[EBP];
					mov		ECX, length;
					cmp		ECX, 4;
					jl		twopixel;
				fourpixelloop:
					movups	XMM0, [ESI];
					movups	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movups	[EDI], XMM0;
					add		ESI,16;
					add		EDI,16;
					sub		ECX, 4;
					cmp		ECX, 4;
					jge		fourpixelloop;
				twopixel:
					cmp		ECX, 2;
					jl		onepixel;
					movq	XMM0, [ESI];
					movq	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movq	[EDI], XMM0;
					add		ESI, 8;
					add		EDI, 8;
					sub		ECX, 2;
				onepixel:
					cmp		ECX, 1;
					jl		end;
					movd	XMM0, [ESI];
					movd	XMM1, [EDI];
					pxor	XMM0, XMM1;
					movd	[EDI], XMM0;
					
				end:
					;
				}
			}
		}else version(X86_64){
			asm @nogc{
				mov		RSI, src[RBP];
				mov		RDI, dest[RBP];
				mov		RCX, length;
				cmp		RCX, 4;
				jl		twopixel;
			fourpixelloop:
				movups	XMM0, [RSI];
				movups	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movups	[RDI], XMM0;
				add		RSI,16;
				add		RDI,16;
				sub		RCX, 4;
				cmp		RCX, 4;
				jge		fourpixelloop;
			twopixel:
				cmp		RCX, 2;
				jl		onepixel;
				movq	XMM0, [RSI];
				movq	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movq	[RDI], XMM0;
				add		RSI, 8;
				add		RDI, 8;
				sub		RCX, 2;
			onepixel:
				cmp		RCX, 1;
				jl		end;
				movd	XMM0, [RSI];
				movd	XMM1, [RDI];
				pxor	XMM0, XMM1;
				movd	[RDI], XMM0;
			end:
				;
			}
		}else{
			while(lenght){
				*dest1 = *src ^ *dest;
				src++;
				dest++;
				dest1++;
				length--;
			}
		}
	}else static assert("Template parameter '"~ T.stringof ~"' not supported!");
}