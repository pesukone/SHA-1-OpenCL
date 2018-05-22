uint f(uint t, uint B, uint C, uint D) {
	if (t < 20) {
		return (B & C) | (~B & D);
	} else if (t >= 20 && t < 40) {
		return B ^ C ^ D;
	} else if (t >= 40 && t < 60) {
		return (B & C) | (B & D) | (C & D);
	} else if (t >= 60 && t < 80) {
		return B ^ C ^ D;
	}
}

uint plus(uint X, uint Y) {
	//return (X + Y) % convert_uint(pow(2.0, 32.0));
	return (X + Y) & convert_uint(native_powr(2.0, 32.0) - 1.0);
}

uint shift(uint n, uint X) {
	return rotate(X, n);
}

uint K(uint t) {
	if (t < 20) {
		return 0x5A827999;
	} else if (t >= 20 && t < 40) {
		return 0x6ED9EBA1;
	} else if (t >= 40 && t < 60) {
		return 0x8F1BBCDC;
	} else if (t >= 60 && t < 80) {
		return 0xCA62C1D6;
	}
}

__kernel void sha1(__constant unsigned int* file, __constant unsigned long* filesize, __global unsigned int* res) {
	uint MASK = 0x0000000F;
	uint W[16];
	uint H[5] = {0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0};
	uint A, B, C, D, E;

	for (int i = 0; i < (*filesize/ 16); i++) {
		for (int j = 0; j < 16; j++)
			  W[j] = file[16*i+j];

		A = H[0];
		B = H[1];
		C = H[2];
		D = H[3];
		E = H[4];

		for (uint t = 0; t < 80; t++) {
			uint s = t & MASK;
			uint Ws;
			if (t >= 16) {
				W[s] = rotate((W[(s+13) & MASK] ^ W[(s+8) & MASK] ^ W[(s+2) & MASK] ^ W[s]), (uint) 1);
			} 

			uint TEMP = plus(rotate(A, (uint) 5), f(t, B, C, D));
			TEMP = plus(TEMP, E);
			TEMP = plus(TEMP, W[s]);
			TEMP = plus(TEMP, K(t));

			E = D;
			D = C;
			C = rotate(B, (uint) 30);
			B = A;
			A = TEMP;
		}

		H[0] = plus(H[0], A);
		H[1] = plus(H[1], B);
		H[2] = plus(H[2], C);
		H[3] = plus(H[3], D);
		H[4] = plus(H[4], E);
	}

	for (int i = 0; i < 5; i++)
		res[i] = H[i];

	//for (int i = 0; i < 5; i++)
		//printf("%08X", H[i]);

	//for (int i = 0; i < buf_size; i++)
		 //printf("%08X", file[i]);
}
