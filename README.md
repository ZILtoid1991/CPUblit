# CPUblit
Drawing and image composing library.

# Description

* Uses SSE2 or MMX where its possible for high performance.
* No external libraries needed.
* Works without a garbage collection.

# Use

Add this library to your project's dependency via dub or your chosen IDE.

Currently most functions are very low-level, so experience with pointers is recommended. Per-line approach for composing is
recommended if the images have size mismatch.

# To do list

* Fix non-x86 and x86-64 targets.
* Add optimization for ARM Neon.
* Make a GPGPU based variant called GPUblit with either D-Compute, CUDA, and/or OpenCL.
* Add functions for RLE compression and decompression.
* Add higher-level functions and types (might introduce external dependencies).
* More testing.

# Known issues

DMD for x86-64 targets treats vector optimization features differently from LDC. This will be fixed in the near future.