module CPUblit.system;

/*
 * Notes on MMX support (TODO):
 * <ul>
 * <li>This feature is solely intended for legacy purposes on older x86 processors that don't have the SSE2 extension. In any other case, use regular mode.</ li>
 * <li>This feature only works with the LDC compiler, as it relies on intel intrinsics.</ li>
 * </ ul>
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
	
} else {	///TODO: Add ARM NEON support
	static enum bool USE_MMX = false;
	static enum bool USE_INTEL_INTRINSICS = false;
	static enum bool USE_DMD_INTRINSICS = false;
}