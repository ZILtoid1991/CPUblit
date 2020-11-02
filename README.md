# CPUblit
Drawing and image composing library.

# Description

* Uses SSE2 or NEON where its possible for high performance.
* Can work without garbage collection.

# Use

Add this library to your project's dependency via dub or your chosen IDE.

Currently most functions are very low-level, so experience with pointers is recommended. Per-line approach for composing is
recommended if the images have size mismatch.

## Composing function operator legends

* src: The image that we want to compose onto the destination.
* dest: The image we want to compose onto.
* dest0: If present, the result of the image composition will be copied there.
* length: The amount of pixels to be composed.
* mask: If not present, mask will be taken from src's alpha channel or value. It controls how the composing is done, e.g. 
transparency, amount, etc.
* color/value: Sets a fix amount for a given composition.

# To do list

* Fix non-x86 and x86-64 targets.
* Add optimization for ARM Neon. (partly done)
* Make a GPGPU based variant called GPUblit with either D-Compute, CUDA, and/or OpenCL.
* Add functions for RLE compression and decompression.
* Add higher-level functions and types.
* More testing.

# Known issues

DMD for x86-64 targets treats vector optimization features differently from LDC. This will be fixed in the near future.