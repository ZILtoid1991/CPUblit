module CPUblit.colorspaces;

/**
 * CPUblit
 * Color space descriptions by Laszlo Szeremi
 */

/**
 * 32 bit color space.
 * Used for architectures where vector instructions are not readily available.
 */
struct Color32Bit {
    union{
        uint        base;
        ubyte[4]    bytes;
    }
	version (cpublit_revalpha) {
		///Red
		@safe @nogc @property nothrow pure ref auto r() inout { return bytes[3]; }
		///Green
		@safe @nogc @property nothrow pure ref auto g() inout { return bytes[2]; }
		///Blue
		@safe @nogc @property nothrow pure ref auto b() inout { return bytes[1]; }
		///Alpha
		@safe @nogc @property nothrow pure ref auto a() inout { return bytes[3]; }
	} else {
    	///Red
		@safe @nogc @property nothrow pure ref auto r() inout { return bytes[1]; }
		///Green
		@safe @nogc @property nothrow pure ref auto g() inout { return bytes[2]; }
		///Blue
		@safe @nogc @property nothrow pure ref auto b() inout { return bytes[3]; }
		///Alpha
		@safe @nogc @property nothrow pure ref auto a() inout { return bytes[0]; }
	}
}