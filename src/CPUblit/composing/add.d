module CPUblit.composing.add;

import CPUblit.composing.common;

/*
 * CPUblit
 * Add with saturation functions.
 * Author: Laszlo Szeremi
 *
 * These functions compose two image together using the following function:
 * dest0[rgba] = dest[rgba] + src[rbga]
 * If alpha channel is enabled in the template or mask is used, then the function will be the following:
 * dest0[rgba] = dest[rgba] + (mask[aaaa] * src[rgba])
 * which translates to the integer implementation:
 * dest0[rgba] = dest[rgba] + ((1 + mask[aaaa]) * src[rgba])>>>8
 *
 * These functions only work with 8 bit channels, and many require 32 bit values.
 * Masks can be either 8 bit per pixel, or 32 bit per pixel with the ability of processing up to 4 channels
 * independently.
 */
@nogc pure nothrow {
	/**
	 * 2 operator add function
	 */
	public void add(bool UseAlpha = false)(uint* src, uint* dest, size_t length) {
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
				srcV = _mm_packus_epi16(src_lo, src_hi);
			}
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			}
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			}
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest, destV);
		}
		
	}
	/**
	 * 3 operator add function with separate destination.
	 */
	public void add(bool UseAlpha = false)(uint* src, uint* dest, uint* dest0, size_t length) {
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
				srcV = _mm_packus_epi16(src_lo, src_hi);
			}
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			}
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			}
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest0, destV);
		}
	}
	/**
	 * 3 operator add function with masking
	 */
	public void add(M)(uint* src, uint* dest, size_t length, M* mask) {
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
			srcV = _mm_packus_epi16(src_lo, src_hi);
			
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest, destV);
		}
	}
	/**
	 * 3 operator add function with separate destination and masking.
	 */
	public void add(M)(uint* src, uint* dest, uint* dest0, size_t length, M* mask) {
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
			srcV = _mm_packus_epi16(src_lo, src_hi);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest0, destV);
		}
	}
	/**
	 * 2 operator add function with master alpha value.
	 * `UseAlpha` determines whether the src's alpha channel will be used or not.
	 */
	public void addMV(bool UseAlpha = false, V)(uint* src, uint* dest, size_t length, V value) {
		__m128i master_1;
		static if (is(V == uint)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
		} else static if (is(V == ubyte)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
			master_1 |= _mm_slli_epi32(master_1, 8);
			master_1 |= _mm_slli_epi32(master_1, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(master_1, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
				src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
				src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, master_1), 8);
			} else {
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1), 8);
				__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), master_1), 8);
			}
			srcV = _mm_packus_epi16(src_lo, src_hi);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
			src += 4;
			dest += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			} else {
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1), 8);
			}
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += 2;
			dest += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			} else {
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1), 8);
			}
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest, destV);
		}
		
	}
	/**
	 * 3 operator add function with separate destination and master alpha value.
	 */
	public void addMV(bool UseAlpha = false, V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
		__m128i master_1;
		static if (is(V == uint)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
		} else static if (is(V == ubyte)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
			master_1 |= _mm_slli_epi32(master_1, 8);
			master_1 |= _mm_slli_epi32(master_1, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(master_1, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		while(length >= 4) {
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
				src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
				src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, master_1), 8);
			} else {
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1), 8);
				__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), master_1), 8);
			}
			srcV = _mm_packus_epi16(src_lo, src_hi);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if (length >= 2) {
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			} else {
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1), 8);
			}
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (UseAlpha) {
				__m128i maskV = srcV & cast(__m128i)ALPHABLEND_SSE2_AMASK;
				version (cpublit_revalpha) {
					maskV |= _mm_srli_epi32(maskV, 8);
					maskV |= _mm_srli_epi32(maskV, 16);//[A,A,A,A]
				} else {
					maskV |= _mm_slli_epi32(maskV, 8);
					maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
				}
				__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
				src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			} else {
				__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), master_1), 8);
			}
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest0, destV);
		}
	}
	/**
	 * 3 operator add function with masking and master alpha value.
	 */
	public void addMV(M,V)(uint* src, uint* dest, size_t length, M* mask, V value) {
		__m128i master_1;
		static if (is(V == uint)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
		} else static if (is(V == ubyte)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
			master_1 |= _mm_slli_epi32(master_1, 8);
			master_1 |= _mm_slli_epi32(master_1, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(master_1, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, master_1), 8);
			srcV = _mm_packus_epi16(src_lo, src_hi);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest, destV);
			src += 2;
			dest += 2;
			mask += 2;
			length -= 2;
		}
		if (length) {
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			static if (is(M == uint)) {
				__m128i maskV = _mm_loadl_epi64(cast(__m128i*)mask);
			} else static if (is(M == ubyte)) {
				__m128i maskV;
				maskV[0] = mask[0];
				maskV[1] = mask[1];
				maskV |= _mm_slli_epi32(maskV, 8);
				maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest, destV);
		}
	}
	/**
	 * 3 operator add function with separate destination, masking, and master value.
	 */
	public void addMV(M, V)(uint* src, uint* dest, uint* dest0, size_t length, M* mask, V value) {
		__m128i master_1;
		static if (is(V == uint)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
		} else static if (is(V == ubyte)) {
			master_1[0] = value;
			master_1[1] = value;
			//master_1[2] = value;
			//master_1[3] = value;
			master_1 |= _mm_slli_epi32(master_1, 8);
			master_1 |= _mm_slli_epi32(master_1, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		master_1 = _mm_adds_epu16(_mm_unpacklo_epi8(master_1, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask_hi = _mm_adds_epu16(_mm_unpackhi_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			__m128i src_hi = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask_hi), 8);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			src_hi = _mm_srli_epi16(_mm_mullo_epi16(src_hi, master_1), 8);
			srcV = _mm_packus_epi16(src_lo, src_hi);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si128(cast(__m128i*)dest0, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storel_epi64(cast(__m128i*)dest0, destV);
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
			__m128i mask_lo = _mm_adds_epu16(_mm_unpacklo_epi8(maskV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i src_lo = _mm_srli_epi16(_mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask_lo), 8);
			src_lo = _mm_srli_epi16(_mm_mullo_epi16(src_lo, master_1), 8);
			srcV = _mm_packus_epi16(src_lo, SSE2_NULLVECT);
			destV = _mm_adds_epu8(srcV, destV);
			_mm_storeu_si32(dest0, destV);
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
	fillWithSingleValue(src, 0x05050505);
	fillWithSingleValue(dest, 0x05050505);
	add!false(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x0a0a0a0a);
	fillWithSingleValue(dest, 0x05050505);
	add!false(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x0a0a0a0a);
	fillWithSingleValue(dest0, 0);

	//mask value of 0 should generate no change in the output
	add(src.ptr, dest.ptr, 255, mask.ptr);
	testArrayForValue(dest, 0x05050505);
	add(src.ptr, dest.ptr, 255, mask0.ptr);
	testArrayForValue(dest, 0x05050505);
	add(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr);
	testArrayForValue(dest0, 0x05050505);
	fillWithSingleValue(dest0, 0);
	add(src.ptr, dest.ptr, dest0.ptr, 255, mask0.ptr);
	testArrayForValue(dest0, 0x05050505);

	//mask value of 255 should generate maximum change in the output
	fillWithSingleValue(mask, uint.max);
	fillWithSingleValue(mask0, ubyte.max);
	add(src.ptr, dest.ptr, 255, mask.ptr);
	testArrayForValue(dest, 0x0a0a0a0a);
	fillWithSingleValue(dest, 0x05050505);
	add(src.ptr, dest.ptr, 255, mask0.ptr);
	testArrayForValue(dest, 0x0a0a0a0a);
	fillWithSingleValue(dest, 0x05050505);
	add(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr);
	testArrayForValue(dest0, 0x0a0a0a0a);
	fillWithSingleValue(dest0, 0);
	add(src.ptr, dest.ptr, dest0.ptr, 255, mask0.ptr);
	testArrayForValue(dest0, 0x0a0a0a0a);
	//test with alpha channel

	//the least significant byte of a 32 bit pixel is the alpha
	fillWithSingleValue(src, 0x050505FF);
	fillWithSingleValue(dest, 0x050505FF);
	add!true(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x0a0a0aFF);
	fillWithSingleValue(dest, 0x050505FF);
	add!true(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x0a0a0aFF);
	fillWithSingleValue(dest0, 0);
	//with alpha value of zero, the destination shouldn't be affected
	fillWithSingleValue(src, 0x05050500);
	fillWithSingleValue(dest, 0x050505FF);
	add!true(src.ptr, dest.ptr, 255);
	testArrayForValue(dest, 0x050505FF);
	add!true(src.ptr, dest.ptr, dest0.ptr, 255);
	testArrayForValue(dest0, 0x050505FF);
	fillWithSingleValue(src, 0x050505FF);
	fillWithSingleValue(dest0, 0);

	//test master value functions

	//master value of zero shouldn't affect anything
	addMV!false(src.ptr, dest.ptr, 255, uint.min);
	testArrayForValue(dest, 0x050505FF);
	addMV!true(src.ptr, dest.ptr, 255, ubyte.min);
	testArrayForValue(dest, 0x050505FF);
	addMV!false(src.ptr, dest.ptr, dest0.ptr, 255, uint.min);
	testArrayForValue(dest0, 0x050505FF);
	fillWithSingleValue(dest0, 0);
	addMV!true(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.min);
	testArrayForValue(dest0, 0x050505FF);
	fillWithSingleValue(dest0, 0);
	//masks should be also "ignored"
	fillWithSingleValue(mask, uint.max);
	fillWithSingleValue(mask0, ubyte.max);
	addMV(src.ptr, dest.ptr, 255, mask.ptr, ubyte.min);
	testArrayForValue(dest, 0x050505FF);
	addMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, uint.min);
	testArrayForValue(dest0, 0x050505FF);
	fillWithSingleValue(dest0, 0);
	addMV(src.ptr, dest.ptr, 255, mask0.ptr, uint.min);
	testArrayForValue(dest, 0x050505FF);
	addMV(src.ptr, dest.ptr, dest0.ptr, 255, mask0.ptr, ubyte.min);
	testArrayForValue(dest0, 0x050505FF);
	fillWithSingleValue(dest0, 0);
	
	//master value of 255 should generate maximum change in the output
	addMV!false(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x0a0a0aFF);
	fillWithSingleValue(dest, 0x050505FF);
	addMV!true(src.ptr, dest.ptr, 255, ubyte.max);
	testArrayForValue(dest, 0x0a0a0aFF);
	fillWithSingleValue(dest, 0x050505FF);
	addMV!false(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x0a0a0aFF);
	fillWithSingleValue(dest0, 0);
	addMV!true(src.ptr, dest.ptr, dest0.ptr, 255, ubyte.max);
	testArrayForValue(dest0, 0x0a0a0aFF);
	fillWithSingleValue(dest0, 0);

	//ditto with masks of maximum value
	addMV(src.ptr, dest.ptr, 255, mask.ptr, ubyte.max);
	testArrayForValue(dest, 0x0a0a0aFF);
	fillWithSingleValue(dest, 0x050505FF);
	addMV(src.ptr, dest.ptr, 255, mask0.ptr, ubyte.max);
	testArrayForValue(dest, 0x0a0a0aFF);
	fillWithSingleValue(dest, 0x050505FF);
	addMV(src.ptr, dest.ptr, dest0.ptr, 255, mask.ptr, ubyte.max);
	testArrayForValue(dest0, 0x0a0a0aFF);
	fillWithSingleValue(dest0, 0);
	addMV(src.ptr, dest.ptr, dest0.ptr, 255, mask0.ptr, ubyte.max);
	testArrayForValue(dest0, 0x0a0a0aFF);
}