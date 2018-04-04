module CPUblit.colorspaces;

/**
 * CPUblit
 * Color space descriptions by Laszlo Szeremi
 */

import std.bitmanip;

union Pixel16Bit{
	ushort base;
	@nogc struct ColorSpaceRGB565{
		mixin(bitfields!(
			ubyte, "red", 5,
			ubyte, "green", 6,
			ubyte, "blue", 5));
	}
	@nogc struct ColorSpaceRGBA5551{
		mixin(bitfields!(
			ubyte, "red", 5,
			ubyte, "green", 5,
			ubyte, "blue", 5,
			ubyte, "alpha", 1));
	}
	@nogc struct ColorSpaceRGBA4444{
		mixin(bitfields!(
			ubyte, "red", 4,
			ubyte, "green", 4,
			ubyte, "blue", 4,
			ubyte, "alpha", 4));
	}
}

union Pixel32Bit{
	uint base;
	/*@nogc struct ColorSpaceRGBA8888{
		ubyte[4] colors;	///Normal representation, aliases are used for color naming.
		version(LittleEndian){
			public @property @nogc ubyte alpha(){ return colors[3]; }
			public @property @nogc ubyte red(){ return colors[0]; }
			public @property @nogc ubyte green(){ return colors[1]; }
			public @property @nogc ubyte blue(){ return colors[2]; }
			public @property @nogc ubyte alpha(ubyte value){ return colors[3] = value; }
			public @property @nogc ubyte red(ubyte value){ return colors[0] = value; }
			public @property @nogc ubyte green(ubyte value){ return colors[1] = value; }
			public @property @nogc ubyte blue(ubyte value){ return colors[2] = value; }
		}else{
			public @property @nogc ubyte alpha(){ return colors[0]; }
			public @property @nogc ubyte red(){ return colors[3]; }
			public @property @nogc ubyte green(){ return colors[2]; }
			public @property @nogc ubyte blue(){ return colors[1]; }
			public @property @nogc ubyte alpha(ubyte value){ return colors[0] = value; }
			public @property @nogc ubyte red(ubyte value){ return colors[3] = value; }
			public @property @nogc ubyte green(ubyte value){ return colors[2] = value; }
			public @property @nogc ubyte blue(ubyte value){ return colors[1] = value; }
		}
		@nogc this(ubyte red, ubyte green, ubyte blue, ubyte alpha){
			this.red = red;
			this.green = green;
			this.blue = blue;
			this.alpha = alpha;
		}
	}*/
	@nogc struct ColorSpaceARGB{
		ubyte[4] colors;	///Normal representation, aliases are used for color naming.
		version(LittleEndian){
			public @property @nogc ubyte alpha(){ return colors[0]; }
			public @property @nogc ubyte red(){ return colors[1]; }
			public @property @nogc ubyte green(){ return colors[2]; }
			public @property @nogc ubyte blue(){ return colors[3]; }
			public @property @nogc ubyte alpha(ubyte value){ return colors[0] = value; }
			public @property @nogc ubyte red(ubyte value){ return colors[1] = value; }
			public @property @nogc ubyte green(ubyte value){ return colors[2] = value; }
			public @property @nogc ubyte blue(ubyte value){ return colors[3] = value; }
		}else{
			public @property @nogc ubyte alpha(){ return colors[3]; }
			public @property @nogc ubyte red(){ return colors[2]; }
			public @property @nogc ubyte green(){ return colors[1]; }
			public @property @nogc ubyte blue(){ return colors[0]; }
			public @property @nogc ubyte alpha(ubyte value){ return colors[3] = value; }
			public @property @nogc ubyte red(ubyte value){ return colors[2] = value; }
			public @property @nogc ubyte green(ubyte value){ return colors[1] = value; }
			public @property @nogc ubyte blue(ubyte value){ return colors[0] = value; }
		}
		@nogc this(ubyte red, ubyte green, ubyte blue, ubyte alpha){
			this.red = red;
			this.green = green;
			this.blue = blue;
			this.alpha = alpha;
		}
	}
	@nogc struct AlphaMask{
		ubyte[4] mask;	///Normal representation, aliases are used for color naming.
		public @property ubyte value(){
			return mask[0];
		}
		public @property ubyte value(ubyte val){
			mask[0] = value;
			mask[1] = value;
			mask[2] = value;
			mask[3] = value;
			return val;
		}
		@nogc this(ubyte value){
			mask[0] = value;
			mask[1] = value;
			mask[2] = value;
			mask[3] = value;
		}
	}
}

public @nogc Pixel32Bit convCS(string colorspace)(Pixel16Bit input){
	static if(colorspace == "RGB565"){
		return Pixel32Bit.ColorSpaceARGB8888(input.ColorSpaceRGB565.red<<3 | input.ColorSpaceRGB565.red>>2, input.ColorSpaceRGB565.green<<2 | input.ColorSpaceRGB565.green>>6,
						input.ColorSpaceRGB565.blue<<3 | input.ColorSpaceRGB565.blue>>2, 255);
	}else static if(colorspace == "RGBA5551"){
		return Pixel32Bit.ColorSpaceARGB8888(input.ColorSpaceRGBA5551.red<<3 | input.ColorSpaceRGB565.red>>2, input.ColorSpaceRGBA5551.green<<3 | input.ColorSpaceRGB565.green>>2, 
						input.ColorSpaceRGBA5551.blue<<3 | input.ColorSpaceRGB565.blue>>2, input.ColorSpaceRGBA5551.alpha ? 255 : 0);
	}else static if(colorspace == "RGBA4444"){
		return Pixel32Bit.ColorSpaceARGB8888(input.ColorSpaceRGBA4444.red<<4 | input.ColorSpaceRGBA4444.red, input.ColorSpaceRGBA4444.green<<4 | input.ColorSpaceRGBA4444.green,
						input.ColorSpaceRGBA4444.blue<<4 | input.ColorSpaceRGBA4444.blue, input.ColorSpaceRGBA4444.alpha<<4 | input.ColorSpaceRGBA4444.alpha);
	}else static assert("Colorspace " ~ colorspace ~ " is not supported!");
}