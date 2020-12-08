module CPUblit.composing.common;

public import CPUblit.system;
public import CPUblit.colorspaces;


public import inteli.emmintrin;
///All zeroes vector
package immutable __m128i SSE2_NULLVECT;
///All ones vector for alpha-blending offset correction when doing it with integers
package immutable short8 ALPHABLEND_SSE2_CONST1 = [1,1,1,1,1,1,1,1];
///All 256 vector for negative alpha blending
package immutable short8 ALPHABLEND_SSE2_CONST256 = [256,256,256,256,256,256,256,256];
///All 255 vector for negative alpha blending
package immutable short8 ALPHABLEND_SSE2_CONST255 = [255,255,255,255,255,255,255,255];
	version (cpublit_revalpha) {
		///Alpha mask for extracting alpha values from BGRA and RGBA colorspaces
		//package immutable ubyte16 ALPHABLEND_SSE2_MASK = [0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255];
		package immutable __m128i ALPHABLEND_SSE2_AMASK = [0xFF000000,0xFF000000,0xFF000000,0xFF000000];
		version (cpublit_revrgb) {
			package immutable __m128i ALPHABLEND_SSE2_BMASK = [0x000000FF,0x000000FF,0x000000FF,0x000000FF];
			package immutable __m128i ALPHABLEND_SSE2_GMASK = [0x0000FF00,0x0000FF00,0x0000FF00,0x0000FF00];
			package immutable __m128i ALPHABLEND_SSE2_RMASK = [0x00FF0000,0x00FF0000,0x00FF0000,0x00FF0000];
		} else {
			package immutable __m128i ALPHABLEND_SSE2_RMASK = [0x000000FF,0x000000FF,0x000000FF,0x000000FF];
			package immutable __m128i ALPHABLEND_SSE2_GMASK = [0x0000FF00,0x0000FF00,0x0000FF00,0x0000FF00];
			package immutable __m128i ALPHABLEND_SSE2_BMASK = [0x00FF0000,0x00FF0000,0x00FF0000,0x00FF0000];
		}
	} else {
		///Alpha mask for extracting alpha values from ARGB and ABGR colorspaces
		//package immutable ubyte16 ALPHABLEND_SSE2_MASK = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0];
		package immutable __m128i ALPHABLEND_SSE2_AMASK = [0x000000FF,0x000000FF,0x000000FF,0x000000FF];
		version (cpublit_revrgb) {
			package immutable __m128i ALPHABLEND_SSE2_BMASK = [0x0000FF00,0x0000FF00,0x0000FF00,0x0000FF00];
			package immutable __m128i ALPHABLEND_SSE2_GMASK = [0x00FF0000,0x00FF0000,0x00FF0000,0x00FF0000];
			package immutable __m128i ALPHABLEND_SSE2_RMASK = [0xFF000000,0xFF000000,0xFF000000,0xFF000000];
		} else {
			package immutable __m128i ALPHABLEND_SSE2_RMASK = [0x0000FF00,0x0000FF00,0x0000FF00,0x0000FF00];
			package immutable __m128i ALPHABLEND_SSE2_GMASK = [0x00FF0000,0x00FF0000,0x00FF0000,0x00FF0000];
			package immutable __m128i ALPHABLEND_SSE2_BMASK = [0xFF000000,0xFF000000,0xFF000000,0xFF000000];
		}
	}


version (unittest) {
	void testArrayForValue(T)(T[] input, const T refVal = T.init) @safe {
		import std.conv : to;
		foreach (size_t pos, T val ; input) {
			assert(val == refVal, "Error at position " ~ to!string(pos) ~ " with value " ~ to!string(val));
		}
   }
   void fillWithSingleValue(T)(ref T[] array, const T value) @safe pure nothrow {
	   foreach (ref T i ; array) {
		   i = value;
	   }
   }
}