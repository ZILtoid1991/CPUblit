module CPUblit.composing.diff;

import CPUblit.composing.common;

/*
 * CPUblit
 * Difference functions.
 * Author: Laszlo Szeremi
 *
 * These functions compose two image together using the following function:
 * dest0[rgba] = max(dest[rgba], src[rbga]) - min(dest[rgba], src[rbga])
 * If alpha channel is enabled in the template or mask is used, then the function will be the following:
 * dest0[rgba] = ((1.0 - mask[aaaa]) * dest[rgba]) + (mask[aaaa] * (max(dest[rgba], src[rbga]) - min(dest[rgba], src[rbga])))
 * which translates to the integer implementation:
 * dest0[rgba] = (((256 - mask[aaaa]) * dest[rgba]) + ((1 + mask[aaaa]) * (max(dest[rgba], src[rbga]) - min(dest[rgba], src[rbga])))) >>> 8
 *
 * These functions only work with 8 bit channels, and many require 32 bit values.
 * Masks can be either 8 bit per pixel, or 32 bit per pixel with the ability of processing up to 4 channels
 * independently.
 */
@nogc pure nothrow {
	/**
	 * 2 operator difference function without alpha
	 */
	public void diff(uint* src, uint* dest, size_t length) {
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			destV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			destV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			_mm_storeu_si32(dest, destV);//*cast(int*)dest = destV[0];
		}
		
	}
	/**
	 * 3 operator difference function with separate destination without alpha.
	 */
	public void diff(uint* src, uint* dest, uint* dest0, size_t length) {
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			destV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			destV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			destV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			_mm_storeu_si32(dest0, destV);//*cast(int*)dest0 = destV[0];
		}
	}
	/**
	 * 2 operator difference function with alpha
	 */
	public void diffBl(uint* src, uint* dest, size_t length) {
		while(length >= 4) {
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
		
	}
	/**
	 * 3 operator difference function with separate destination and alpha.
	 */
	public void diffBl(uint* src, uint* dest, uint* dest0, size_t length) {
		while(length >= 4) {
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator difference function with masking
	 */
	public void diff(M)(uint* src, uint* dest, size_t length, M* mask) {
		while(length >= 4) {
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
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
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
				__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 4 operator difference function with separate destination and masking.
	 */
	public void diff(M)(uint* src, uint* dest, uint* dest0, size_t length, M* mask) {
		while(length >= 4) {
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
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
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
				__m128i maskV = _mm_loadu_si32(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 2 operator add function with master alpha value.
	 * `UseAlpha` determines whether the src's alpha channel will be used or not.
	 */
	public void diffMV(V)(uint* src, uint* dest, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), master_1);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
		
	}
	/**
	 * 3 operator difference function with separate destination and master alpha value.
	 */
	public void diffMV(V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), master_256);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 2 operator add function with master alpha value and per pixel alpha.
	 */
	public void diffMVBl(V)(uint* src, uint* dest, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		while(length >= 4) {
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
		
	}
	/**
	 * 3 operator difference function with separate destination and master alpha value.
	 */
	public void diffMVBl(V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		while(length >= 4) {
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 3 operator difference function with masking, per-pixel alpha, and master alpha value.
	 */
	public void diffMV(M,V)(uint* src, uint* dest, size_t length, M* mask, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
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
			__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
			__m128i maskV = _mm_loadu_si32(mask);
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
	/**
	 * 4 operator difference function with masking, separate destination, per-pixel alpha, and master alpha value.
	 */
	public void diffMV(M, V)(uint* src, uint* dest, uint* dest0, size_t length, M* mask, V value) {
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			//masterV[2] = value;
			//masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), ALPHABLEND_SSE2_CONST1);
		//__m128i master_256 = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, _mm_unpacklo_epi8(masterV, SSE2_NULLVECT));
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i maskV = _mm_loadu_si128(cast(__m128i*)mask);
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_hi);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_hi);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_hi);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			dest += 4;
			dest0 += 4;
			mask += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
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
			__m128i maskV = _mm_loadu_si32(mask);
			version (cpublit_revalpha) {
				maskV |= _mm_srli_epi32(maskV, 8);
				maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
			} else {
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			}
			srcV = _mm_subs_epu8(_mm_max_epu8(destV, srcV), _mm_min_epu8(destV, srcV));
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	}
}

unittest {
	uint[] src, dest, dest0, mask;
	ubyte[] mask0;
	src.length = 255;
	dest.length = 255;
	dest0.length = 255;
	mask.length = 255;
	mask0.length = 255;
	fillWithSingleValue(src, 0x0f010fFF);
	fillWithSingleValue(dest, 0x010f01FF);

	//test basic functions
	diff(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diff(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	//test functions with blend
	diffBl(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffBl(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	fillWithSingleValue(src, 0x0f010f00);

	diffBl(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffBl(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	fillWithSingleValue(src, 0x0f010fFF);

	//test functions with masking
	diff(src.ptr, dest.ptr, 255, mask.ptr);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diff(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diff(src.ptr, dest.ptr, 255, mask0.ptr);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diff(src.ptr, dest.ptr, dest0.ptr, 255, mask0.ptr);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	fillWithSingleValue(mask, uint.max);
	fillWithSingleValue(mask0, ubyte.max);

	diff(src.ptr, dest.ptr, 255, mask.ptr);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diff(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diff(src.ptr, dest.ptr, 255, mask0.ptr);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diff(src.ptr, dest.ptr, dest0.ptr, 255, mask0.ptr);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	//test master value functions without blend
	diffMV(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, uint.max);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, uint.max);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	//test master value functions with blend
	//255 alpha values
	diffMVBl(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diffMVBl(src.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMVBl(src.ptr, dest.ptr, 255, uint.max);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, uint.max);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diffMVBl(src.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);
	//0 alpha values
	fillWithSingleValue(src, 0x0f010f00);

	diffMVBl(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMVBl(src.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMVBl(src.ptr, dest.ptr, 255, uint.max);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, uint.max);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMVBl(src.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMVBl(src.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	//test master value functions with masking
	fillWithSingleValue(src, 0x0f010fFF);
	fillWithSingleValue(mask, uint.max);
	diffMV(src.ptr, dest.ptr, 255, mask.ptr, ubyte.max);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, ubyte.max);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, ubyte.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, ubyte.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, uint.max);
	testArrayForValue(dest, 0x0e0e0e00);
	fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, uint.max);
	testArrayForValue(dest0, 0x0e0e0e00);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, uint.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, uint.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);
	//0 alpha values
	fillWithSingleValue(mask, uint.min);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, ubyte.max);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, ubyte.max);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, ubyte.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, ubyte.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, uint.max);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, uint.max);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);

	diffMV(src.ptr, dest.ptr, 255, mask.ptr, uint.min);
	testArrayForValue(dest, 0x010f01FF);
	//fillWithSingleValue(dest, 0x010f01FF);
	diffMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, uint.min);
	testArrayForValue(dest0, 0x010f01FF);
	fillWithSingleValue(dest0, 0);
}