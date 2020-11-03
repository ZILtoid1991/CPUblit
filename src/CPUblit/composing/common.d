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
	version (cpublit_revalpha) {
		///Alpha mask for extracting alpha values from BGRA and RGBA colorspaces
		package immutable ubyte16 ALPHABLEND_SSE2_MASK = [0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255];
	} else {
		///Alpha mask for extracting alpha values from ARGB and ABGR colorspaces
		package immutable ubyte16 ALPHABLEND_SSE2_MASK = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0];
	}


version (unittest) {
	void testArrayForZeros(T)(T[] input) @safe {
		import std.conv : to;
		foreach (size_t pos, T val ; input) {
			assert(!val, "Error at position " ~ to!string(pos));
		}
   }
}