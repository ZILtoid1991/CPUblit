module CPUblit.composing;

/*
 * CPUblit
 * Low-level image composing functions
 * Author: Laszlo Szeremi
 *
 * This file imports most composing functions available in this library.
 * All low-level composing functions are implemented on a line-by-line basis and are able to be ran in parallel.
 */

public import CPUblit.composing.blitter;
public import CPUblit.composing.copy;
public import CPUblit.composing.alphablend;
public import CPUblit.composing.add;
public import CPUblit.composing.sub;
public import CPUblit.composing.mult;
public import CPUblit.composing.diff;
public import CPUblit.composing.screen;
/+unittest {
    alias FunPtr = void function(uint*, uint*, size_t, ubyte) @nogc nothrow pure;
    FunPtr f = &__traits(getOverloads, CPUblit.composing.add, "addMV(bool UseAlpha = false, V)", true)[0];
}+/