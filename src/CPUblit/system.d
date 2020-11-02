module CPUblit.system;

/*
 * MMX Support is not yet implemented, and likely will be abandoned.
 *
 * ARM targets will use Intel intrinsics emulation as long as there won't be any performance penalties from it.
 */
version(X86) {
	version(LDC) {
		version(MMX_LEGACY) {
			static enum bool USE_MMX = true;
			static enum bool USE_INTEL_INTRINSICS = true;
			static enum bool USE_DMD_INTRINSICS = false;
		} else {
			static enum bool USE_MMX = false;
			static enum bool USE_INTEL_INTRINSICS = true;
			static enum bool USE_DMD_INTRINSICS = false;
		}
	}else{
		static enum bool USE_MMX = false;
		static enum bool USE_INTEL_INTRINSICS = false;
		static enum bool USE_DMD_INTRINSICS = false;
	}
}else version(X86_64) {
	static enum bool USE_MMX = false;
	static enum bool USE_INTEL_INTRINSICS = true;
	version(DMD)
		static enum bool USE_DMD_INTRINSICS = true;
	else
		static enum bool USE_DMD_INTRINSICS = false;
} else version(ARM) {
	//Must be LDC!
	static enum bool USE_MMX = false;
	static enum bool USE_INTEL_INTRINSICS = true;
	static enum bool USE_DMD_INTRINSICS = false;
} else version(AArch64) {
	static enum bool USE_MMX = false;
	static enum bool USE_INTEL_INTRINSICS = true;
	static enum bool USE_DMD_INTRINSICS = false;
} else {
	static enum bool USE_MMX = false;
	static enum bool USE_INTEL_INTRINSICS = false;
	static enum bool USE_DMD_INTRINSICS = false;
}