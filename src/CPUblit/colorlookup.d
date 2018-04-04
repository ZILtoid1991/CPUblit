module CPUblit.colorlookup;
/**
 * CPUblit
 * Color look-up and planar to chunky (coming soon) conversion functions.
 */


public import CPUblit.colorspaces;
/**
 * Converts an indexed image of type T (eg. ubyte, ushort) into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 */
public @nogc void colorLookup(T, U)(T* src, U* dest, U* palette, size_t length){
	while(length){
		*dest = palette[*src];
		src++;
		dest++;
		length--;
	}
}
/**
 * Converts a 4 Bit indexed image into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 * Word order is: 0xF0 even, 0x0F odd.
 */
public @nogc void colorLookup4Bit(U)(ubyte* src, U* dest, U* palette, size_t length, int offset = 0){
	for(; offset < length; offset++){
		if(offset & 1){
			*dest = palette[(*src) & 0x0F];
			offset = 0;
			src++;
		}else{
			*dest = palette[(*src) & 0xF0];
			offset++;
		}
		dest++;
	}
}

/**
 * Converts a 2 Bit indexed image into an unindexed type of U (eg. Pixel16Bit, Pixel32Bit).
 * Word order is: 0: 0b11_00_00_00 1: 0b00_11_00_00 2: 0b00_00_11_00 3: 0b00_00_00_11
 */
public @nogc void colorLookup2Bit(U)(ubyte* src, U* dest, U* palette, size_t length, int offset = 0){
	for(; offset < length; offset++){
		switch(offset & 3){
			case 3:
				*dest = palette[(*src) & 0b00_00_00_11];
				offset = 0;
				src++;
				break;
			case 2:
				*dest = palette[(*src) & 0b00_00_11_00];
				offset++;
				break;
			case 1:
				*dest = palette[(*src) & 0b00_11_00_00];
				offset++;
				break;
			default:
				*dest = palette[(*src) & 0b11_00_00_00];
				offset++;
				break;
		}
		dest++;
	}
}

/*public @nogc void convPlanarToChunky(int planes, U)(ubyte* src, U* dest, size_t length){

}*/