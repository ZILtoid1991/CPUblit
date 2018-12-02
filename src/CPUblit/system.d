module CPUblit.system;

version(X86){
	version(LDC){
		static enum bool USE_INTEL_INTRINSICS = true;
		static enum bool USE_DMD_INTRINSICS = false;
	}else{
		static enum bool USE_INTEL_INTRINSICS = false;
		static enum bool USE_DMD_INTRINSICS = false;
	}
}else version(X86_64){
	version(LDC){
		static enum bool USE_INTEL_INTRINSICS = true;
		static enum bool USE_DMD_INTRINSICS = false;
	}else{
		static enum bool USE_INTEL_INTRINSICS = false;
		version(DMD)
			static enum bool USE_DMD_INTRINSICS = true;
		else
			static enum bool USE_DMD_INTRINSICS = false;
	}
}else{	///TODO: Add ARM NEON support
	static enum bool USE_INTEL_INTRINSICS = false;
	static enum bool USE_DMD_INTRINSICS = false;
}