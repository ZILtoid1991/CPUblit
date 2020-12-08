module CPUblit.composing.blitter;

import CPUblit.composing.common;

/*
 * CPUblit
 * Blitter composing functions.
 * Author: Laszlo Szeremi
 *
 * The functions can be used on 8, 16, and 32 bit datatypes. These cannot deal with alignments related to datatypes less 
 * than 8 bit, or with 24 bit.
 * 8 and 16 bit blitters copy a an image over another with either treating 0 as transparency, or getting transparency
 * information from the mask operator, which must be either U.min (for overwriting) or U.max (for transparency). Mask can
 * be 8 and 16 bit
 * 32 bit blitter copies an image over another by either using the alpha channel from the src operator or from a supplied
 * mask. Mask can be either 32 bit or 8 bit, based on pointer type.
 */

@nogc pure nothrow {
	///2 operator blitter
	void blitter(T)(T* src, T* dest, size_t length) {
		static enum MAINLOOP_LENGTH = 16 / T.sizeof;
		static enum HALFLOAD_LENGTH = 8 / T.sizeof;
		static enum QUTRLOAD_LENGTH = 4 / T.sizeof;
		while (length >= MAINLOOP_LENGTH) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if(is(T == ubyte))
				__m128i maskV = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(is(T == ushort))
				__m128i maskV = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(is(T == uint))
				__m128i maskV = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK, SSE2_NULLVECT);
			destV = srcV | (destV & maskV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if(is(T == ubyte))
				__m128i maskV = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(is(T == ushort))
				__m128i maskV = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(is(T == uint))
				__m128i maskV = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK, SSE2_NULLVECT);
			destV = srcV | (destV & maskV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if(is(T == ubyte))
				__m128i maskV = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(is(T == ushort))
				__m128i maskV = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(is(T == uint))
				__m128i maskV = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK, SSE2_NULLVECT);
			destV = srcV | (destV & maskV);
			_mm_storeu_si32(dest, destV);
			static if(!is(T == uint)){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(is(T == ubyte)){
			while(length){
				const ubyte mask = *src ? ubyte.min : ubyte.max;
				*dest = *src | (*dest & mask);
				src++;
				dest++;
				length--;
			}
		}else static if(is(T == ushort)){
			if(length){
				const ushort mask = *src ? ushort.min : ushort.max;
				*dest = *src | (*dest & mask);
			}
		}
	}
	///3 operator blitter
	void blitter(T)(T* src, T* dest, T* dest0, size_t length) {
		static enum MAINLOOP_LENGTH = 16 / T.sizeof;
		static enum HALFLOAD_LENGTH = 8 / T.sizeof;
		static enum QUTRLOAD_LENGTH = 4 / T.sizeof;
		while (length >= MAINLOOP_LENGTH) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if(is(T == ubyte))
				__m128i maskV = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(is(T == ushort))
				__m128i maskV = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(is(T == uint))
				__m128i maskV = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK, SSE2_NULLVECT);
			destV = srcV | (destV & maskV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			dest0 += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if (length >= HALFLOAD_LENGTH) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if(is(T == ubyte))
				__m128i maskV = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(is(T == ushort))
				__m128i maskV = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(is(T == uint))
				__m128i maskV = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK, SSE2_NULLVECT);
			destV = srcV | (destV & maskV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			dest0 += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if (length >= QUTRLOAD_LENGTH) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if(is(T == ubyte))
				__m128i maskV = _mm_cmpeq_epi8(srcV, SSE2_NULLVECT);
			else static if(is(T == ushort))
				__m128i maskV = _mm_cmpeq_epi16(srcV, SSE2_NULLVECT);
			else static if(is(T == uint))
				__m128i maskV = _mm_cmpeq_epi32(srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK, SSE2_NULLVECT);
			destV = srcV | (destV & maskV);
			_mm_storeu_si32(dest0, destV);
			static if(!is(T == uint)){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				dest0 += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(is(T == ubyte)) {
			while (length) {
				const ubyte mask = *src ? ubyte.min : ubyte.max;
				*dest0 = *src | (*dest & mask);
				src++;
				dest++;
				dest0++;
				length--;
			}
		} else static if(is(T == ushort)) {
			if (length) {
				const ushort mask = *src ? ushort.min : ushort.max;
				*dest0 = *src | (*dest & mask);
			}
		}
	}
	///3 operator blitter
	void blitter(T,M)(T* src, T* dest, size_t length, M* mask) {
		static enum MAINLOOP_LENGTH = 16 / T.sizeof;
		static enum HALFLOAD_LENGTH = 8 / T.sizeof;
		static enum QUTRLOAD_LENGTH = 4 / T.sizeof;
		while(length >= MAINLOOP_LENGTH){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (is(T == ubyte)) {
				static assert(is(T == M), "8 bit mask and image types must match!");
				__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			} else static if (is(T == ushort)) {
				static if (is(M == ushort)) {
					__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
				} else static if (is(M == ubyte)) {
					__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
					maskV = _mm_unpacklo_epi8(maskV, maskV);
				} else static assert (0, "16 bit blitter only works with 8 or 16 bit masks!");
			} else static if(is(T == uint)) {
				static if (is(M == uint)) {
					__m128i maskV = _mm_cmpeq_epi32(_mm_loadu_si128(cast(__m128i*)mask) & cast(__m128i)ALPHABLEND_SSE2_AMASK, 
							SSE2_NULLVECT);
				} else static if (is(M == ubyte)) {
					__m128i maskV;
					maskV[0] = mask[0];
					maskV[1] = mask[1];
					maskV[2] = mask[2];
					maskV[3] = mask[3];
					maskV = _mm_cmpeq_epi32(maskV, SSE2_NULLVECT);
				} else static assert (0, "32 bit blitter only works with 8 or 32 bit masks!");
			}
			destV = srcV | (destV & maskV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			mask += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (is(T == ubyte)) {
				static assert(is(T == M), "8 bit mask and image types must match!");
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(T == ushort)) {
				static if (is(M == ushort)) {
					__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
				} else static if (is(M == ubyte)) {
					__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
					maskV = _mm_unpacklo_epi8(maskV, maskV);
				} else static assert (0, "16 bit blitter only works with ");
			} else static if(is(T == uint)) {
				static if (is(M == uint)) {
					__m128i maskV = _mm_cmpeq_epi32(_mm_loadl_epi64(cast(__m128i*)mask) & cast(__m128i)ALPHABLEND_SSE2_AMASK, 
							SSE2_NULLVECT);
				} else static if (is(M == ubyte)) {
					__m128i maskV;
					maskV[0] = mask[0];
					maskV[1] = mask[1];
					maskV = _mm_cmpeq_epi32(maskV, SSE2_NULLVECT);
				} else static assert (0, "32 bit blitter only works with 8 or 32 bit masks!");
			}
			destV = srcV | (destV & maskV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			mask += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(T == ubyte)) {
				static assert(is(T == M), "8 bit mask and image types must match!");
				__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
			} else static if (is(T == ushort)) {
				static if (is(M == ushort)) {
					__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
				} else static if (is(M == ubyte)) {
					__m128i maskV;// = _mm_loadl_epi64(cast(__m128i*)mask);
					maskV[0] = (mask[0]<<24) | (mask[0]<<16) | (mask[1]<<8) | mask[1];
				} else static assert (0, "16 bit blitter only works with 8 or 16 bit masks!");
			} else static if(is(T == uint)) {
				static if (is(M == uint)) {
					__m128i maskV = _mm_cmpeq_epi32(_mm_loadu_si32(mask) & cast(__m128i)ALPHABLEND_SSE2_AMASK, 
							SSE2_NULLVECT);
				} else static if (is(M == ubyte)) {
					__m128i maskV;
					maskV[0] = mask[0];
					maskV = _mm_cmpeq_epi32(maskV, SSE2_NULLVECT);
				} else static assert (0, "32 bit blitter only works with 8 or 32 bit masks!");
			}
			destV = srcV | (destV & maskV);
			_mm_storeu_si32(dest, destV);
			static if(!is(T == uint)){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				mask += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(is(T == ubyte)){
			while(length){
				*dest = *src | (*dest & *mask);
				src++;
				dest++;
				mask++;
				length--;
			}
		}else static if(is(T == ushort)){
			if(length){
				*dest = *src | (*dest & *mask);
			}
		}
	}
	///4 operator blitter
	void blitter(T,M)(T* src, T* dest, T* dest0, size_t length, M* mask) {
		static enum MAINLOOP_LENGTH = 16 / T.sizeof;
		static enum HALFLOAD_LENGTH = 8 / T.sizeof;
		static enum QUTRLOAD_LENGTH = 4 / T.sizeof;
		while (length >= MAINLOOP_LENGTH) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (is(T == ubyte)) {
				static assert(is(T == M), "8 bit mask and image types must match!");
				__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			} else static if (is(T == ushort)) {
				static if (is(M == ushort)) {
					__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
				} else static if (is(M == ubyte)) {
					__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
					maskV = _mm_unpacklo_epi8(maskV, maskV);
				} else static assert (0, "16 bit blitter only works with 8 or 16 bit masks!");
			} else static if(is(T == uint)) {
				static if (is(M == uint)) {
					__m128i maskV = _mm_cmpeq_epi32(_mm_loadu_si128(cast(__m128i*)mask) & cast(__m128i)ALPHABLEND_SSE2_AMASK, 
							SSE2_NULLVECT);
				} else static if (is(M == ubyte)) {
					__m128i maskV;
					maskV[0] = mask[0];
					maskV[1] = mask[1];
					maskV[2] = mask[2];
					maskV[3] = mask[3];
					maskV = _mm_cmpeq_epi32(maskV, SSE2_NULLVECT);
				} else static assert (0, "32 bit blitter only works with 8 or 32 bit masks!");
			}
			destV = srcV | (destV & maskV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			dest0 += MAINLOOP_LENGTH;
			mask += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if (length >= HALFLOAD_LENGTH) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (is(T == ubyte)) {
				static assert(is(T == M), "8 bit mask and image types must match!");
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(T == ushort)) {
				static if (is(M == ushort)) {
					__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
				} else static if (is(M == ubyte)) {
					__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
					maskV = _mm_unpacklo_epi8(maskV, maskV);
				} else static assert (0, "16 bit blitter only works with ");
			} else static if(is(T == uint)) {
				static if (is(M == uint)) {
					__m128i maskV = _mm_cmpeq_epi32(_mm_loadl_epi64(cast(__m128i*)mask) & cast(__m128i)ALPHABLEND_SSE2_AMASK, 
							SSE2_NULLVECT);
				} else static if (is(M == ubyte)) {
					__m128i maskV;
					maskV[0] = mask[0];
					maskV[1] = mask[1];
					maskV = _mm_cmpeq_epi32(maskV, SSE2_NULLVECT);
				} else static assert (0, "32 bit blitter only works with 8 or 32 bit masks!");
			}
			destV = srcV | (destV & maskV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			dest0 += HALFLOAD_LENGTH;
			mask += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if (length >= QUTRLOAD_LENGTH) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(T == ubyte)) {
				static assert(is(T == M), "8 bit mask and image types must match!");
				__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
			} else static if (is(T == ushort)) {
				static if (is(M == ushort)) {
					__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
				} else static if (is(M == ubyte)) {
					__m128i maskV;// = _mm_loadl_epi64(cast(__m128i*)mask);
					maskV[0] = (mask[0]<<24) | (mask[0]<<16) | (mask[1]<<8) | mask[1];
				} else static assert (0, "16 bit blitter only works with ");
			} else static if(is(T == uint)) {
				static if (is(M == uint)) {
					__m128i maskV = _mm_cmpeq_epi32(_mm_loadu_si32(mask) & cast(__m128i)ALPHABLEND_SSE2_AMASK, 
							SSE2_NULLVECT);
				} else static if (is(M == ubyte)) {
					__m128i maskV;
					maskV[0] = mask[0];
					maskV = _mm_cmpeq_epi32(maskV, SSE2_NULLVECT);
				} else static assert (0, "32 bit blitter only works with 8 or 32 bit masks!");
			}
			destV = srcV | (destV & maskV);
			_mm_storeu_si32(dest0, destV);
			static if(!is(T == uint)){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				dest0 += QUTRLOAD_LENGTH;
				mask += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(is(T == ubyte)) {
			while (length) {
				*dest0 = *src | (*dest & *mask);
				src++;
				dest++;
				dest0++;
				mask++;
				length--;
			}
		} else static if(is(T == ushort)) {
			if (length) {
				*dest0 = *src | (*dest & *mask);
			}
		}
	}
	///Blitter with dummy master value
	void blitter(T)(T* src, T* dest, size_t length, ubyte value) {
		blitter(src, dest, length);
	}
	///Blitter with dummy master value
	void blitter(T)(T* src, T* dest, T* dest0, size_t length, ubyte value) {
		blitter(src, dest, dest0, length);
	}
	///Blitter with dummy master value
	void blitter(T,M)(T* src, T* dest, size_t length, M* mask, ubyte value) {
		blitter(src, dest, length, mask);
	}
	///Blitter with dummy master value
	void blitter(T,M)(T* src, T* dest, T* dest0, size_t length, M* mask, ubyte value) {
		blitter(src, dest, dest0, length, mask);
	}

}

unittest {
	{
		ubyte[255] a, b, c, d;
		blitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		blitter(a.ptr, b.ptr, 255, d.ptr);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255, d.ptr);
		testArrayForValue(c);
	}
	{
		ushort[255] a, b, c, d;
		blitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		blitter(a.ptr, b.ptr, 255, d.ptr);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255, d.ptr);
		testArrayForValue(c);
	}
	{
		uint[255] a, b, c, d;
		blitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		blitter(a.ptr, b.ptr, 255, d.ptr);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255, d.ptr);
		testArrayForValue(c);
	}
	{
		ushort[255] a, b, c;
		ubyte[255] d;
		blitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		blitter(a.ptr, b.ptr, 255, d.ptr);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255, d.ptr);
		testArrayForValue(c);
	}
	{
		uint[255] a, b, c;
		ubyte[255] d;
		blitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		blitter(a.ptr, b.ptr, 255, d.ptr);
		testArrayForValue(b);
		blitter(a.ptr, b.ptr, c.ptr, 255, d.ptr);
		testArrayForValue(c);
	}
}