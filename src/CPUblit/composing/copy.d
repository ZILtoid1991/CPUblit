module CPUblit.composing.copy;

import core.stdc.string : memcpy;

/*
 * CPUblit
 * Copy composing functions.
 * Author: Laszlo Szeremi
 *
 * The functions can be used on 8, 16, 24, and 32 bit datatypes. These cannot deal with alignments related to datatypes less than 8 bit.
 * Only two operators + length are used, 3 and 4 operator ones currently are there for swapping with other 3 and 4 operator functions.
 * These functions are using memcpy as their backend, so these should use whatever is the most efficient on your target.
 */

@nogc pure nothrow:
	/**
	 * 2 operator copy function.
	 */
	void copy(T)(T* src, T* dest, size_t length) {
		memcpy(dest, src, length * T.sizeof);
	}
	/**
	 * 3 operator copy function.
	 */
	void copy(T,M)(T* src, T* dest, size_t length, M* mask) {
		memcpy(dest, src, length * T.sizeof);
	}
	/**
	 * 3 operator copy function.
	 */
	void copy(T)(T* src, T* dest, T* dest0, size_t length) {
		memcpy(dest1, src, length * T.sizeof);
	}
	/**
	 * 4 operator copy function.
	 */
	void copy(T,M)(T* src, T* dest, T* dest0, size_t length, M* mask) {
		memcpy(dest1, src, length * T.sizeof);
	}

	unittest {
		
	}