module CPUblit.composing.specblt;

import CPUblit.composing.common;

/**
 * Text blitter, mainly intended for single color texts, can work in other applications as long as they're correctly formatted,
 * meaning: transparent pixels = 0, colored pixels = T.max 
 */
public void textBlitter(T)(T* src, T* dest, size_t length, T color) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			byte16 colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			short8 colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			int4 colorV;
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
			_mm_storeu_si32(dest, destV);
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
public void textBlitter(T)(T* src, T* dest, T* dest0, size_t length, T color) @nogc pure nothrow {
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			byte16 colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			short8 colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			int4 colorV;
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
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			src += MAINLOOP_LENGTH;
			dest += MAINLOOP_LENGTH;
			dest0 += MAINLOOP_LENGTH;
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
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			src += HALFLOAD_LENGTH;
			dest += HALFLOAD_LENGTH;
			dest0 += HALFLOAD_LENGTH;
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
			_mm_storeu_si32(dest0, destV);
			static if(T.stringof != "uint"){
				src += QUTRLOAD_LENGTH;
				dest += QUTRLOAD_LENGTH;
				dest0 += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				const T mask = *src ? T.min : T.max;
				*dest0 = (*src & color) | (*dest & mask);
				src++;
				dest++;
				dest0++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				const T mask = *src ? T.min : T.max;
				*dest0 = (*src & color) | (*dest & mask);
			}
		}
	}else{
		while(length){
			const T mask = *src ? T.min : T.max;
			*dest0 = (*src & color) | (*dest & mask);
			src++;
			dest++;
			dest0++;
			length--;
		}
	}
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public @nogc void xorBlitter(T)(T* dest, T* dest0, size_t length, T color){
	static if(USE_INTEL_INTRINSICS){
		static if(T.stringof == "ubyte"){
			byte16 colorV;
			static enum MAINLOOP_LENGTH = 16;
			static enum HALFLOAD_LENGTH = 8;
			static enum QUTRLOAD_LENGTH = 4;
		}else static if(T.stringof == "ushort"){
			short8 colorV;
			static enum MAINLOOP_LENGTH = 8;
			static enum HALFLOAD_LENGTH = 4;
			static enum QUTRLOAD_LENGTH = 2;
		}else static if(T.stringof == "uint"){
			int4 colorV;
			static enum MAINLOOP_LENGTH = 4;
			static enum HALFLOAD_LENGTH = 2;
			static enum QUTRLOAD_LENGTH = 1;
		}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
		for (int i ; i < MAINLOOP_LENGTH ; i++){
			colorV[i] = color;
		}
		while(length >= MAINLOOP_LENGTH){
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_xor_si128(destV, cast(__m128i)colorV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			dest += MAINLOOP_LENGTH;
			dest0 += MAINLOOP_LENGTH;
			length -= MAINLOOP_LENGTH;
		}
		if(length >= HALFLOAD_LENGTH){
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			destV = _mm_xor_si128(destV, cast(__m128i)colorV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			dest += HALFLOAD_LENGTH;
			dest0 += HALFLOAD_LENGTH;
			length -= HALFLOAD_LENGTH;
		}
		if(length >= QUTRLOAD_LENGTH){
			__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
			destV = _mm_xor_si128(destV, cast(__m128i)colorV);
			_mm_storeu_si32(dest0, destV);
			static if(T.stringof != "uint"){
				dest += QUTRLOAD_LENGTH;
				dest0 += QUTRLOAD_LENGTH;
				length -= QUTRLOAD_LENGTH;
			}
		}
		static if(T.stringof == "ubyte"){
			while(length){
				*dest0 = color ^ *dest;
				dest++;
				dest0++;
				length--;
			}
		}else static if(T.stringof == "ushort"){
			if(length){
				*dest0 = color ^ *dest;
			}
		}
	}else{
		while(length){
			*dest0 = color ^ *dest;
			dest++;
			dest0++;
			length--;
		}
	}
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public void xorBlitter(T)(T* dest, size_t length, T color) @nogc pure nothrow {
	static if(T.stringof == "ubyte"){
		byte16 colorV;
		static enum MAINLOOP_LENGTH = 16;
		static enum HALFLOAD_LENGTH = 8;
		static enum QUTRLOAD_LENGTH = 4;
	}else static if(T.stringof == "ushort"){
		short8 colorV;
		static enum MAINLOOP_LENGTH = 8;
		static enum HALFLOAD_LENGTH = 4;
		static enum QUTRLOAD_LENGTH = 2;
	}else static if(T.stringof == "uint"){
		int4 colorV;
		static enum MAINLOOP_LENGTH = 4;
		static enum HALFLOAD_LENGTH = 2;
		static enum QUTRLOAD_LENGTH = 1;
	}else static assert(0, "Template parameter '"~ T.stringof ~"' not supported!");
	for (int i ; i < MAINLOOP_LENGTH ; i++){
		colorV[i] = color;
	}
	while(length >= MAINLOOP_LENGTH){
		__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
		destV = _mm_xor_si128(destV, cast(__m128i)colorV);
		_mm_storeu_si128(cast(__m128i*)dest, destV);
		dest += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_xor_si128(destV, cast(__m128i)colorV);
		_mm_storel_epi64(cast(__m128i*)dest, destV);
		dest += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_xor_si128(destV, cast(__m128i)colorV);
		_mm_storeu_si32(dest, destV);
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
	
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public void xorBlitter(T)(T* src, T* dest, size_t length) @nogc pure nothrow {
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
		destV = _mm_xor_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si128(cast(__m128i*)dest, destV);
		dest += MAINLOOP_LENGTH;
		src += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_xor_si128(destV, srcV);
		_mm_storel_epi64(cast(__m128i*)dest, destV);
		dest += HALFLOAD_LENGTH;
		src += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_xor_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si32(dest, destV);
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
}
/**
 * XOR blitter. Popularly used for selection and pseudo-transparency.
 */
public void xorBlitter(T)(T* src, T* dest, T* dest0, size_t length) @nogc pure nothrow {
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
		destV = _mm_xor_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si128(cast(__m128i*)dest0, destV);
		dest += MAINLOOP_LENGTH;
		dest0 += MAINLOOP_LENGTH;
		src += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_xor_si128(destV, srcV);
		_mm_storel_epi64(cast(__m128i*)dest0, destV);
		dest += HALFLOAD_LENGTH;
		dest0 += HALFLOAD_LENGTH;
		src += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_xor_si128(destV, srcV);
		_mm_storeu_si32(dest0, destV);
		static if(T.stringof != "uint"){
			dest += QUTRLOAD_LENGTH;
			dest0 += QUTRLOAD_LENGTH;
			src += QUTRLOAD_LENGTH;
			length -= QUTRLOAD_LENGTH;
		}
	}
	static if(T.stringof == "ubyte"){
		while(length){
			*dest = *src ^ *dest;
			dest++;
			dest0++;
			src++;
			length--;
		}
	}else static if(T.stringof == "ushort"){
		if(length){
			*dest0 = *src ^ *dest;
		}
	}
}
/**
 * AND blitter for misc. usage.
 */
public void andBlitter(T)(T* src, T* dest, size_t length) {
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
		destV = _mm_and_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si128(cast(__m128i*)dest, destV);
		dest += MAINLOOP_LENGTH;
		src += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_and_si128(destV, srcV);
		_mm_storel_epi64(cast(__m128i*)dest, destV);
		dest += HALFLOAD_LENGTH;
		src += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_and_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si32(dest, destV);
		static if(T.stringof != "uint"){
			dest += QUTRLOAD_LENGTH;
			src += QUTRLOAD_LENGTH;
			length -= QUTRLOAD_LENGTH;
		}
	}
	static if(T.stringof == "ubyte"){
		while(length){
			*dest = *src & *dest;
			dest++;
			src++;
			length--;
		}
	}else static if(T.stringof == "ushort"){
		if(length){
			*dest = *src & *dest;
		}
	}
}
/**
 * AND blitter for misc. usage.
 */
public void andBlitter(T)(T* src, T* dest, T* dest0, size_t length) {
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
		destV = _mm_and_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si128(cast(__m128i*)dest0, destV);
		dest += MAINLOOP_LENGTH;
		dest0 += MAINLOOP_LENGTH;
		src += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_and_si128(destV, srcV);
		_mm_storel_epi64(cast(__m128i*)dest0, destV);
		dest += HALFLOAD_LENGTH;
		dest0 += HALFLOAD_LENGTH;
		src += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_and_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si32(dest0, destV);
		static if(T.stringof != "uint"){
			dest += QUTRLOAD_LENGTH;
			dest0 += QUTRLOAD_LENGTH;
			src += QUTRLOAD_LENGTH;
			length -= QUTRLOAD_LENGTH;
		}
	}
	static if(T.stringof == "ubyte"){
		while(length){
			*dest0 = *src & *dest;
			dest++;
			dest0++;
			src++;
			length--;
		}
	}else static if(T.stringof == "ushort"){
		if(length){
			*dest0 = *src & *dest;
		}
	}
}
/**
 * OR blitter for misc. usage.
 */
public void orBlitter(T)(T* src, T* dest, size_t length) {
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
		destV = _mm_or_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si128(cast(__m128i*)dest, destV);
		dest += MAINLOOP_LENGTH;
		src += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_or_si128(destV, srcV);
		_mm_storel_epi64(cast(__m128i*)dest, destV);
		dest += HALFLOAD_LENGTH;
		src += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_or_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si32(dest, destV);
		static if(T.stringof != "uint"){
			dest += QUTRLOAD_LENGTH;
			src += QUTRLOAD_LENGTH;
			length -= QUTRLOAD_LENGTH;
		}
	}
	static if(T.stringof == "ubyte"){
		while(length){
			*dest = *src | *dest;
			dest++;
			src++;
			length--;
		}
	}else static if(T.stringof == "ushort"){
		if(length){
			*dest = *src | *dest;
		}
	}
}
/**
 * OR blitter for misc. usage.
 */
public void orBlitter(T)(T* src, T* dest, T* dest0, size_t length) {
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
		destV = _mm_or_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si128(cast(__m128i*)dest, destV);
		dest += MAINLOOP_LENGTH;
		src += MAINLOOP_LENGTH;
		length -= MAINLOOP_LENGTH;
	}
	if(length >= HALFLOAD_LENGTH){
		__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
		__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
		destV = _mm_or_si128(destV, srcV);
		_mm_storel_epi64(cast(__m128i*)dest, destV);
		dest += HALFLOAD_LENGTH;
		src += HALFLOAD_LENGTH;
		length -= HALFLOAD_LENGTH;
	}
	if(length >= QUTRLOAD_LENGTH){
		__m128i srcV = _mm_cvtsi32_si128((*cast(int*)src));
		__m128i destV = _mm_cvtsi32_si128((*cast(int*)dest));
		destV = _mm_or_si128(destV, cast(__m128i)srcV);
		_mm_storeu_si32(dest, destV);
		static if(T.stringof != "uint"){
			dest += QUTRLOAD_LENGTH;
			dest0 += QUTRLOAD_LENGTH;
			src += QUTRLOAD_LENGTH;
			length -= QUTRLOAD_LENGTH;
		}
	}
	static if(T.stringof == "ubyte"){
		while(length){
			*dest0 = *src | *dest;
			dest++;
			dest0++;
			src++;
			length--;
		}
	}else static if(T.stringof == "ushort"){
		if(length){
			*dest0 = *src | *dest;
		}
	}
}
unittest {
	//test for zero correctness.
	{
		ubyte[255] a, b, c;
		textBlitter(a.ptr, b.ptr, 255, 0);
		testArrayForValue(b);
		textBlitter(a.ptr, b.ptr, c.ptr, 255, 0);
		testArrayForValue(c);
		xorBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		xorBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		xorBlitter(b.ptr, 255, 0);
		testArrayForValue(b);
		xorBlitter(b.ptr, c.ptr, 255, 0);
		testArrayForValue(c);

		andBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		andBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);

		orBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		orBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
	}
	{
		ushort[255] a, b, c;
		textBlitter(a.ptr, b.ptr, 255, 0);
		testArrayForValue(b);
		textBlitter(a.ptr, b.ptr, c.ptr, 255, 0);
		testArrayForValue(c);
		xorBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		xorBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		xorBlitter(b.ptr, 255, 0);
		testArrayForValue(b);
		xorBlitter(b.ptr, c.ptr, 255, 0);
		testArrayForValue(c);

		andBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		andBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);

		orBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		orBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
	}
	{
		uint[255] a, b, c;
		textBlitter(a.ptr, b.ptr, 255, 0);
		testArrayForValue(b);
		textBlitter(a.ptr, b.ptr, c.ptr, 255, 0);
		testArrayForValue(c);
		xorBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		xorBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
		xorBlitter(b.ptr, 255, 0);
		testArrayForValue(b);
		xorBlitter(b.ptr, c.ptr, 255, 0);
		testArrayForValue(c);

		andBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		andBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);

		orBlitter(a.ptr, b.ptr, 255);
		testArrayForValue(b);
		orBlitter(a.ptr, b.ptr, c.ptr, 255);
		testArrayForValue(c);
	}
}