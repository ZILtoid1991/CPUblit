# CPUblit

Drawing and image composing library.

# Description

* Uses SSE2 or NEON where its possible for high performance.
* Can work without garbage collection.

# Use

Add this library to your project's dependency via dub or your chosen IDE.

Currently most functions are very low-level, so experience with pointers is recommended. This is to make vector optimizations
easier, and pointers will be hidden in higher-level functions.

## Composing function operator legends

* src: The image that we want to compose onto the destination.
* dest: The image we want to compose onto.
* dest0: If present, the result of the image composition will be copied there.
* length: The amount of pixels to be composed.
* mask: If not present, mask will be taken from src's alpha channel or value. It controls how the composing is done, e.g. 
transparency, amount, etc.
* color/value: Sets a fix amount for a given composition.

## Composing function code example

Many composing functions are semi-interchangeable with virtual function calls.

```d
alias cmpFunc = void function(uint*, uint* size_t) @nogc pure nothrow;
cmpFunc f = &alphaBlend;
```

NOTE: there's currently an issue with how D handles templates with overloads, so it might not really work.

The recommended solution for composing two images with different sizes is a per-line approach:

```d
for (int i ; i < lineNum ; i++) {
    alphaBlend(src + i * srcPitch, dest + i * destPitch, lineLength);
}
```

## General guidelines

* Memory allocation will cause performance drop. To avoid it, use pre-allocated destinations. This is also the reason
why the functions don't return either an array of result, or a pointer to it.
* As of now, GC allocation have very minimal or no performance impact compared to using manual C-style ones. However
GC allocation have the advantage of better memory safety. However it's recommended to use `@nogc` labels on functions
where GC allocation is not needed.
* Use of LDC2 is recommended over DMD due to it's better performance.

# To do list

* Make a GPGPU based variant called GPUblit with either D-Compute, CUDA, and/or OpenCL.
* Add functions for RLE compression and decompression.
* Add higher-level functions and types.
* Add ability of running it in betterC mode with limitations.
* More testing.

# Known issues

* LDC2 on ARM might not automatically create all the vector instructions on lower optimization levels. If you're
experiencing performance issues, then try to build a release version.
