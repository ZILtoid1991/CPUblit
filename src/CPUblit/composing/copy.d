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

@nogc pure nothrow {
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
		memcpy(dest0, src, length * T.sizeof);
	}
	/**
	 * 4 operator copy function.
	 */
	void copy(T,M)(T* src, T* dest, T* dest0, size_t length, M* mask) {
		memcpy(dest0, src, length * T.sizeof);
	}
	/**
	 * 2 operator copy function with dummy master value.
	 */
	void copyMV(T)(T* src, T* dest, size_t length, ubyte value) {
		memcpy(dest, src, length * T.sizeof);
	}
	/**
	 * 3 operator copy function with dummy master value.
	 */
	void copyMV(T,M)(T* src, T* dest, size_t length, M* mask, ubyte value) {
		memcpy(dest, src, length * T.sizeof);
	}
	/**
	 * 3 operator copy function with dummy master value.
	 */
	void copyMV(T)(T* src, T* dest, T* dest0, size_t length, ubyte value) {
		memcpy(dest0, src, length * T.sizeof);
	}
	/**
	 * 4 operator copy function with dummy master value.
	 */
	void copyMV(T,M)(T* src, T* dest, T* dest0, size_t length, M* mask, ubyte value) {
		memcpy(dest0, src, length * T.sizeof);
	}
}

unittest {
	void testfunc(T)(){
		{
			T[255] a, b;
			copy(a.ptr, b.ptr, 255);
			foreach (T val ; b) {
				assert(!val);
			}
			foreach (ref T val ; a) {
				val = T.max;
			}
			copy(a.ptr, b.ptr, 255);
			foreach (T val ; b) {
				assert(val == T.max);
			}
		}
		{
			T[255] a, b;
			copy(a.ptr, b.ptr, b.ptr, 255);
			foreach (T val ; b) {
				assert(!val);
			}
			foreach (ref T val ; a) {
				val = T.max;
			}
			copy(a.ptr, b.ptr, b.ptr, 255);
			foreach (T val ; b) {
				assert(val == T.max);
			}
		}
		/+{
			T[255] a, b;
			copy(a.ptr, b.ptr, 255, null);
			foreach (T val ; b) {
				assert(!val);
			}
			foreach (ref T val ; a) {
				val = T.max;
			}
			copy(a.ptr, b.ptr, 255, null);
			foreach (T val ; b) {
				assert(val == T.max);
			}
		}
		{
			T[255] a, b;
			copy(a.ptr, b.ptr, b.ptr, 255, null);
			foreach (T val ; b) {
				assert(!val);
			}
			foreach (ref T val ; a) {
				val = T.max;
			}
			copy(a.ptr, b.ptr, b.ptr, 255, null);
			foreach (T val ; b) {
				assert(val == T.max);
			}
		}+/
	}
	testfunc!ubyte();
	testfunc!ushort();
	testfunc!uint();
}