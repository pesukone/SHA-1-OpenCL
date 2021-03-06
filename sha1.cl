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
	//return (X + Y) & convert_uint(native_powr(2.0, 32.0) - 1.0);
	return (X + Y) & 0xFFFFFFFF;
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

uint8 sha1func(uint16 in, uint8 H) {
	uint MASK = 0x0000000F;
	uint W[16] = { 	in.s0, in.s1, in.s2, in.s3,
					in.s4, in.s5, in.s6, in.s7,
					in.s8, in.s9, in.sA, in.sB,
					in.sC, in.sD, in.sE, in.sF };
	uint A, B, C, D, E;

	A = H.s0;
	B = H.s1;
	C = H.s2;
	D = H.s3;
	E = H.s4;

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

	return (uint8) (plus(H.s0, A), plus(H.s1, B),
					plus(H.s2, C), plus(H.s3, D),
					plus(H.s4, E), 0, 0, 0);
}

uint8 hash_padding(uint* tail, int tail_length, uint8 H, __constant unsigned long* filesize) {
	tail[tail_length] = 0x80000000;
	tail[15] = *filesize * 32;

	uint16 W = (uint16) (
					tail[0], tail[1], tail[2], tail[3],
					tail[4], tail[5], tail[6], tail[7],
					tail[8], tail[9], tail[10], tail[11],
					tail[12], tail[13], tail[14], tail[15]
				);

	return sha1func(W, H);
}

uint8 hash_file(__constant unsigned int* file, __constant unsigned long* filesize, uint8 H) {
	int i = 0;

	while (i + 16 < *filesize) {
		uint16 W = 	(uint16) (
						file[i], file[i+1], file[i+2], file[i+3],
						file[i+4], file[i+5], file[i+6], file[i+7],
						file[i+8], file[i+9], file[i+10], file[i+11],
						file[i+12], file[i+13], file[i+14], file[i+15]
					);
		H = sha1func(W, H);
		i += 16;
	}

	int tail_len = *filesize - i;
	uint tail[16] = {0};

	for (int j = 0; j < tail_len; j++)
		tail[j] = file[i+j];

	return hash_padding(&tail, tail_len, H, filesize);
}

__kernel void sha1(__constant unsigned int* file, __constant unsigned long* filesize, __global unsigned int* res) {
	uint8 H = (uint8) (0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0, 0, 0, 0);
	H = hash_file(file, filesize, H);

	res[0] = H.s0;
	res[1] = H.s1;
	res[2] = H.s2;
	res[3] = H.s3;
	res[4] = H.s4;

	//for (int i = 0; i < *filesize; i++)
		 //printf("%08X", file[i]);
}
