module CPUblit.composing.mult;

import CPUblit.composing.common;

/*
 * CPUblit
 * Multiply-blend compose functions.
 * Author: Laszlo Szeremi
 *
 * Multiply-blend functions compose two images together using the following formula:
 * dest0[rgba] = src[rgba] * dest[rgba]
 * This is translated to the following formula:
 * dest0[rgba] = ((1 + src[rgba]) * dest[rgba])>>>8
 * If alpha channel is enabled, it'control the blend between the multiplied value and the original one.
 * dest0[rgba] = ((1.0 - mask[aaaa]) * dest) + (mask[aaaa] * src[rgba] * dest[rgba])
 * In integer, this is:
 * dest0[rgba] = (((256 - mask[aaaa]) * dest) + ((1 + mask[aaaa]) * ((1 + src[rgba]) * dest[rgba])>>>8))>>>8
 */
@nogc pure nothrow {
	/**
	 * 2 operator multiply function without blending.
	 */
	void mult32Bit(uint* src, uint* dest, size_t length) {
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator multiply function without blending.
	 * Has separate destination
	 */
	void mult32Bit(uint* src, uint* dest, uint* dest0, size_t length) {
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			//__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			//src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			//__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			//src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 2 operator multiply function with blending.
	 */
	void mult32BitBl(uint* src, uint* dest, size_t length) {
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator multiply function without blending.
	 * Has separate destination
	 */
	void mult32BitBl(uint* src, uint* dest, uint* dest0, size_t length) {
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 2 operator multiply function without blending and with master value.
	 */
	void mult32BitMV(V)(uint* src, uint* dest, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			src_lo = _mm_mullo_epi16(src_lo, master_1);
			src_hi = _mm_mullo_epi16(src_hi, master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_lo = _mm_mullo_epi16(src_lo, master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_lo = _mm_mullo_epi16(src_lo, master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator multiply function without blending and with master value.
	 * Has separate destination.
	 */
	void mult32BitMV(V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			src_lo = _mm_mullo_epi16(src_lo, master_1);
			src_hi = _mm_mullo_epi16(src_hi, master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_lo = _mm_mullo_epi16(src_lo, master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_lo = _mm_mullo_epi16(src_lo, master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator multiply function with masking.
	 */
	void mult32Bit(M)(uint* src, uint* dest, size_t length, M* mask) {
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV[2] = mask[2];
				maskV[3] = mask[3];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			mask += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			mask += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si32(mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 4 operator multiply function with masking.
	 * Has separate destination.
	 */
	void mult32Bit(M)(uint* src, uint* dest, uint* dest0, size_t length, M* mask) {
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV[2] = mask[2];
				maskV[3] = mask[3];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest0 += 4;
			mask += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			mask += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si32(mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 2 operator multiply function with blending and master value.
	 */
	void mult32BitMVBl(V)(uint* src, uint* dest, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator multiply function with blending and master value.
	 * Has separate destination.
	 */
	void mult32BitMVBl(V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator multiply function with masking and master value.
	 */
	void mult32BitMV(M,V)(uint* src, uint* dest, size_t length, M* mask, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV[2] = mask[2];
				maskV[3] = mask[3];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			mask += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			mask += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si32(mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 4 operator multiply function with masking and master value.
	 * Has separate destination.
	 */
	void mult32BitMV(M,V)(uint* src, uint* dest, uint* dest0, size_t length, M* mask, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		while (length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV[2] = mask[2];
				maskV[3] = mask[3];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			__m128i src_hi = _mm_adds_epu16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, _mm_unpackhi_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			src_hi = _mm_mullo_epi16(src_hi, mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			mask += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			mask += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadu_si32(mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			__m128i src_lo = _mm_adds_epu16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, _mm_unpacklo_epi8(destV, SSE2_NULLVECT)), 8);
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			src_lo = _mm_mullo_epi16(src_lo, mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
}
unittest {
	uint[] src, src0, dest, dest0, maskA, maskB;
	ubyte[] mask0A, mask0B;
	src.length = 255;
	src0.length = 255;
	dest.length = 255;
	dest0.length = 255;
	maskA.length = 255;
	fillWithSingleValue(maskA, uint.max);
	maskB.length = 255;
	mask0A.length = 255;
	fillWithSingleValue(mask0A, ubyte.max);
	mask0B.length = 255;
	fillWithSingleValue(src, 0x306090FF);
	fillWithSingleValue(src0, 0x30609000);
	fillWithSingleValue(dest, 0xEE2ADDFF);//result should be `0x2D0F7DFF` if A is FF

	//Tast basic functions
	mult32Bit(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32Bit(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	//Test blend functions
	mult32BitBl(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitBl(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitBl(src0.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitBl(src0.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	//Test master value functions
	mult32BitMV(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, uint.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, uint.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	//Test mask functions
	mult32Bit(src.ptr, dest.ptr, 255, mask0A.ptr);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32Bit(src.ptr, dest.ptr, dest0.ptr, 255, mask0A.ptr);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32Bit(src.ptr, dest.ptr, 255, maskA.ptr);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32Bit(src.ptr, dest.ptr, dest0.ptr, 255, maskA.ptr);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32Bit(src.ptr, dest.ptr, 255, mask0B.ptr);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32Bit(src.ptr, dest.ptr, dest0.ptr, 255, mask0B.ptr);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32Bit(src.ptr, dest.ptr, 255, maskB.ptr);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32Bit(src.ptr, dest.ptr, dest0.ptr, 255, maskB.ptr);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	//Test blend master value functions
	mult32BitMVBl(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src.ptr, dest.ptr, 255, uint.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src.ptr, dest.ptr, dest0.ptr, 255, uint.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src0.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src0.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src0.ptr, dest.ptr, 255, uint.max);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src0.ptr, dest.ptr, dest0.ptr, 255, uint.max);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src0.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src0.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMVBl(src0.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMVBl(src0.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	//Test masking with master value functions
	mult32BitMV(src.ptr, dest.ptr, 255, mask0A.ptr, ubyte.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, mask0A.ptr, ubyte.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, mask0A.ptr, uint.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, mask0A.ptr, uint.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, mask0A.ptr, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, mask0A.ptr, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, mask0A.ptr, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, mask0A.ptr, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, mask0B.ptr, ubyte.max);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, mask0B.ptr, ubyte.max);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, mask0B.ptr, uint.max);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, mask0B.ptr, uint.max);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, mask0B.ptr, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, mask0B.ptr, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, mask0B.ptr, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, mask0B.ptr, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);
	//
	mult32BitMV(src.ptr, dest.ptr, 255, maskA.ptr, ubyte.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, maskA.ptr, ubyte.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, maskA.ptr, uint.max);
	testArrayForValue(dest, 0x2D0F7DFF);
	fillWithSingleValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, maskA.ptr, uint.max);
	testArrayForValue(dest0, 0x2D0F7DFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, maskA.ptr, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, maskA.ptr, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src.ptr, dest.ptr, 255, maskA.ptr, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src.ptr, dest.ptr, dest0.ptr, 255, maskA.ptr, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, maskB.ptr, ubyte.max);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, maskB.ptr, ubyte.max);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, maskB.ptr, uint.max);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, maskB.ptr, uint.max);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, maskB.ptr, ubyte.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, maskB.ptr, ubyte.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	fillWithSingleValue(dest0, 0);

	mult32BitMV(src0.ptr, dest.ptr, 255, maskB.ptr, uint.min);
	testArrayForValue(dest, 0xEE2ADDFF);
	mult32BitMV(src0.ptr, dest.ptr, dest0.ptr, 255, maskB.ptr, uint.min);
	testArrayForValue(dest0, 0xEE2ADDFF);
	//fillWithSingleValue(dest0, 0);
}