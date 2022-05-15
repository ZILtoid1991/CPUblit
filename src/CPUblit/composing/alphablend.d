module CPUblit.composing.alphablend;

import CPUblit.composing.common;

/*
 * CPUblit
 * Alpha-blending functions.
 * Author: Laszlo Szeremi
 *
 * Alpha-blending composes two images together using the following formula:
 * dest0[rgba] = ((1.0 - mask[aaaa]) * dest[rgba]) + (mask[aaaa] * src[rgba])
 * where `mask` is either a separate mask (either a master value or a per-pixel one), or the extracted alpha-
 * channel of src.
 * For speed's sake, these functions use integer arithmetics, so this formula will be used instead:
 * dest0[rgba] = (((256 - mask[aaaa]) * dest[rgba]) + ((1 + mask[aaaa]) * src[rgba]))>>>8
 * There should be no downside for this approach, especially as some workarounds have been done to avoid such
 * issues.
 * When a master alpha is used, it's multiplied with either mask.
 *
 * These functions only work with 8 bit channels, and many require 32 bit values.
 * Masks can be either 8 bit per pixel, or 32 bit per pixel with the ability of processing up to 4 channels
 * independently (only when using vectors).
 *
 * Note on differences between vector and non-vector implementation: Vector implementations process all four
 * channels to save on complexity. Non-vector implementations only process the three color channels to save
 * on processing speed.
 */
@nogc pure nothrow {
/**
 * 2 operator alpha-blending function.
 */
public void alphaBlend(uint* src, uint* dest, size_t length) {
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
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
		mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
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
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
		__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
		__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
		src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
		_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
	}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			const int src1 = 1 + lsrc.a;
			const int src256 = 256 - lsrc.a;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest = ldest;
			dest++;
			//dest0++;
			length--;
		}
	} */
}
/**
 * 3 operator alpha-blending function.
 */
public void alphaBlend(uint* src, uint* dest, uint* dest0, size_t length) {
	/* static if (USE_INTEL_INTRINSICS) {  */
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
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
		mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
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
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
		__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
		__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
		src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
		_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
	}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			const int src1 = 1 + lsrc.a;
			const int src256 = 256 - lsrc.a;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest0 = ldest;
			dest++;
			dest0++;
			length--;
		}
	} */
}
/**
 * 3 operator alpha-blending function.
 * Mask is either 8 or 32 bit per pixel.
 */
public void alphaBlend(M)(uint* src, uint* dest, size_t length, M* mask) {
	/* static if(USE_INTEL_INTRINSICS){ */
		while(length >= 4){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		if(length >= 2){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			mask += 2;
			length -= 2;
		}
		if(length){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			static if (is(M == uint)) {
				const int src1 = 1 + (*mask & 0xFF);
				const int src256 = 256 - (*mask & 0xFF);
			} else static if (is(M == ubyte)) {
				const int src1 = 1 + *mask;
				const int src256 = 256 - *mask;
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest = ldest;
			dest++;
			mask++;
			//dest0++;
			length--;
		}
	} */
}
/**
 * 4 operator alpha-blending function.
 * Mask is either 8 or 32 bit per pixel.
 */
public void alphaBlend(M)(uint* src, uint* dest, uint* dest0, size_t length, M* mask) {
	/* static if(USE_INTEL_INTRINSICS){ */
		while(length >= 4){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		if(length >= 2){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
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
		if(length){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			static if (is(M == uint)) {
				const int src1 = 1 + (*mask & 0xFF);
				const int src256 = 256 - (*mask & 0xFF);
			} else static if (is(M == ubyte)) {
				const int src1 = 1 + *mask;
				const int src256 = 256 - *mask;
			} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest0 = ldest;
			dest++;
			mask++;
			dest0++;
			length--;
		}
	} */
}
/**
 * Fix value alpha-blending, 3 operator.
 */
public void alphaBlendFV(V)(uint* src, uint* dest, size_t length, V value) {
	/* static if(USE_INTEL_INTRINSICS){ */
		__m128i maskV;
		static if (is(V == uint)) {
			maskV[0] = value;
			maskV[1] = value;
			//maskV[2] = value;
			//maskV[3] = value;
		} else static if (is(V == ubyte)) {
			maskV[0] = value;
			maskV[1] = value;
			//maskV[2] = value;
			//maskV[3] = value;
			maskV |= _mm_slli_epi32(maskV, 8);
			maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
		} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		//__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		//__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
		//mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
		while(length >= 4){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			//mask += 4;
			length -= 4;
		}
		if(length >= 2){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			//mask += 2;
			length -= 2;
		}
		if(length){
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		static if (is(V == uint)) {
			const int src1 = 1 + value;
			const int src256 = 256 - value;
		} else static if (is(V == ubyte)) {
			const int src1 = 1 + value;
			const int src256 = 256 - value;
		} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest = ldest;
			dest++;
			mask++;
			//dest0++;
			length--;
		}
	} */
}
/**
 * Fix value alpha-blending, 4 operator.
 */
public void alphaBlendFV(V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
	/* static if(USE_INTEL_INTRINSICS){ */
		__m128i maskV;
		static if (is(V == uint)) {
			maskV[0] = value;
			maskV[1] = value;
			//maskV[2] = value;
			//maskV[3] = value;
		} else static if (is(V == ubyte)) {
			maskV[0] = value;
			maskV[1] = value;
			maskV[2] = value;
			maskV[3] = value;
			//maskV |= _mm_slli_epi32(maskV, 8);
			//maskV |= _mm_slli_epi32(maskV, 16);//[A,A,A,A]
		} else static assert (0, "Value must be either 8 or 32 bits!");
		__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
		//__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
		__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		//__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
		mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
		//mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
		while(length >= 4){
			__m128i srcV = _mm_loadu_si128(cast(__m128i*)src);
			__m128i destV = _mm_loadu_si128(cast(__m128i*)dest);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i src_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			__m128i dest_hi = _mm_mullo_epi16(_mm_unpackhi_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			src_hi = _mm_srli_epi16(_mm_adds_epu16(src_hi, dest_hi), 8);
			_mm_storeu_si128(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, src_hi));
			src += 4;
			dest += 4;
			dest0 += 4;
			length -= 4;
		}
		if(length >= 2){
			__m128i srcV = _mm_loadl_epi64(cast(__m128i*)src);
			__m128i destV = _mm_loadl_epi64(cast(__m128i*)dest);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if(length){
			__m128i srcV = _mm_loadu_si32(src);
			__m128i destV = _mm_loadu_si32(dest);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		static if (is(V == uint)) {
			const int src1 = 1 + value;
			const int src256 = 256 - value;
		} else static if (is(V == ubyte)) {
			const int src1 = 1 + value;
			const int src256 = 256 - value;
		} else static assert (0, "Alpha mask must be either 8 or 32 bits!");
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest = ldest;
			dest++;
			mask++;
			//dest0++;
			length--;
		}
	} */
}
/**
 * Alpha-blending with per pixel + fix master value alpha.
 * `value` controls the overall alpha through extra multiplications on the alpha extracted from the pixels.
 * 2 operator.
 */
public void alphaBlendMV(V)(uint* src, uint* dest, size_t length, V value) {
	/* static if(USE_INTEL_INTRINSICS) { */
		__m128i masterV;
		static if (is(V == uint)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV[2] = value;
			masterV[3] = value;
		} else static if (is(V == ubyte)) {
			masterV[0] = value;
			masterV[1] = value;
			masterV[2] = value;
			masterV[3] = value;
			masterV |= _mm_slli_epi32(masterV, 8);
			masterV |= _mm_slli_epi32(masterV, 16);
		} else static assert (0, "Value must be either 8 or 32 bits!");
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		//__m128i masterV = _mm_adds_epu16(_mm_unpackhi_epi8(masterV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		while(length >= 4){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		if(length >= 2){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if(length){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			const int a = (lsrc.a * (value + 1)) >>> 8;
			const int src1 = 1 + a;
			const int src256 = 256 - a;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest = ldest;
			dest++;
			//dest0++;
			length--;
		}
	} */
}
/**
 * Alpha-blending with per pixel + fix master value alpha.
 * `value` controls the overall alpha through extra multiplications on the alpha extracted from the pixels.
 * 3 operator.
 */
public void alphaBlendMV(V)(uint* src, uint* dest, uint* dest0, size_t length, V value) {
	/* static if(USE_INTEL_INTRINSICS) { */
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
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		while(length >= 4){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		if(length >= 2){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if(length){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			const int a = (lsrc.a * (value + 1)) >>> 8;
			const int src1 = 1 + a;
			const int src256 = 256 - a;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest0 = ldest;
			dest++;
			dest0++;
			length--;
		}
	} */
}
/**
 * Alpha-blending with per pixel + fix master value alpha.
 * `value` controls the overall alpha through extra multiplications on the alpha extracted from the pixels.
 * 3 operator.
 */
public void alphaBlendMV(V,M)(uint* src, uint* dest, size_t length, M* mask, V value) {
	/* static if(USE_INTEL_INTRINSICS) { */
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
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		while(length >= 4){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		if(length >= 2){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			length -= 2;
		}
		if(length){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			const int a = (lsrc.a * (value + 1)) >>> 8;
			const int src1 = 1 + a;
			const int src256 = 256 - a;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest = ldest;
			dest++;
			//dest0++;
			length--;
		}
	} */
}
/**
 * Alpha-blending with per pixel + fix master value alpha.
 * `value` controls the overall alpha through extra multiplications on the alpha extracted from the pixels.
 * 3 operator.
 */
public void alphaBlendMV(V,M)(uint* src, uint* dest, uint* dest0, size_t length, M* mask, V value) {
	/* static if(USE_INTEL_INTRINSICS) { */
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
		masterV = _mm_adds_epu16(_mm_unpacklo_epi8(masterV, SSE2_NULLVECT), cast(__m128i)ALPHABLEND_SSE2_CONST1);
		while(length >= 4){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			__m128i mask_hi = _mm_unpackhi_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			mask_hi = _mm_srli_epi16(_mm_mullo_epi16(mask_hi, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			__m128i mask0_hi = _mm_adds_epu16(mask_hi, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			mask_hi = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_hi);
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
		if(length >= 2){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storel_epi64(cast(__m128i*)dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
			src += 2;
			dest += 2;
			dest0 += 2;
			length -= 2;
		}
		if(length){
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
			__m128i mask_lo = _mm_unpacklo_epi8(maskV, SSE2_NULLVECT);
			mask_lo = _mm_srli_epi16(_mm_mullo_epi16(mask_lo, masterV), 8);
			__m128i mask0_lo = _mm_adds_epu16(mask_lo, cast(__m128i)ALPHABLEND_SSE2_CONST1);
			mask_lo = _mm_subs_epu16(cast(__m128i)ALPHABLEND_SSE2_CONST256, mask_lo);
			__m128i src_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(srcV, SSE2_NULLVECT), mask0_lo);
			__m128i dest_lo = _mm_mullo_epi16(_mm_unpacklo_epi8(destV, SSE2_NULLVECT), mask_lo);
			src_lo = _mm_srli_epi16(_mm_adds_epu16(src_lo, dest_lo), 8);
			_mm_storeu_si32(dest0, _mm_packus_epi16(src_lo, SSE2_NULLVECT));
		}
	/* } else {
		while (length) {
			Color32Bit lsrc = *cast(Color32Bit*)src, ldest = *cast(Color32Bit*)dest;
			const int a = (lsrc.a * (value + 1)) >>> 8;
			const int src1 = 1 + a;
			const int src256 = 256 - a;
			ldest.r = cast(ubyte)((lsrc.r * src1 + ldest.r * src256)>>>8);
			ldest.g = cast(ubyte)((lsrc.g * src1 + ldest.g * src256)>>>8);
			ldest.b = cast(ubyte)((lsrc.b * src1 + ldest.b * src256)>>>8);
			src++;
			*cast(Color32Bit*)dest0 = ldest;
			dest++;
			dest0++;
			length--;
		}
	} */
}
}
unittest {
	
	
	uint[255] a, b, c, d;
	ubyte[255] e;
	//0 velues should stay 0
	alphaBlend(a.ptr, b.ptr, 255);
	testArrayForValue(b);
	alphaBlend(a.ptr, b.ptr, 255, d.ptr);
	testArrayForValue(b);
	alphaBlend(a.ptr, b.ptr, c.ptr, 255);
	testArrayForValue(c);
	alphaBlend(a.ptr, b.ptr, c.ptr, 255, d.ptr);
	testArrayForValue(c);
	alphaBlend(a.ptr, b.ptr, 255, e.ptr);
	testArrayForValue(b);
	alphaBlend(a.ptr, b.ptr, c.ptr, 255, e.ptr);
	testArrayForValue(c);
	alphaBlendFV!ubyte(a.ptr, b.ptr, 255, 0x0F);
	testArrayForValue(b);
	alphaBlendFV!ubyte(a.ptr, b.ptr, c.ptr, 255, 0x0F);
	testArrayForValue(c);
	alphaBlendFV!uint(a.ptr, b.ptr, 255, 0x0F0F0F0F);
	testArrayForValue(b);
	alphaBlendFV!uint(a.ptr, b.ptr, c.ptr, 255, 0x0F0F0F0F);
	testArrayForValue(c);
	alphaBlendMV!ubyte(a.ptr, b.ptr, 255, ubyte.max);
	testArrayForValue(b);
	alphaBlendMV!ubyte(a.ptr, b.ptr, 255, d.ptr, ubyte.max);
	testArrayForValue(b);
	alphaBlendMV!ubyte(a.ptr, b.ptr, c.ptr, 255, ubyte.max);
	testArrayForValue(c);
	alphaBlendMV!ubyte(a.ptr, b.ptr, c.ptr, 255, d.ptr, ubyte.max);
	testArrayForValue(c);
	alphaBlendMV!uint(a.ptr, b.ptr, 255, uint.max);
	testArrayForValue(b);
	alphaBlendMV!uint(a.ptr, b.ptr, 255, d.ptr, uint.max);
	testArrayForValue(b);
	alphaBlendMV!uint(a.ptr, b.ptr, c.ptr, 255, uint.max);
	testArrayForValue(c);
	alphaBlendMV!uint(a.ptr, b.ptr, c.ptr, 255, d.ptr, uint.max);
	testArrayForValue(c);
}