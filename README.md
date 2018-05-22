# SHA-1-OpenCL

-----

### You really shouldn't use this for anything!

This implementation is made for one very specific use case, and I have no intention of validating it for anything else. It will give incorrect results if the size of the file being hashed is not a multiple of 32 bits. It will give incorrect results if the file is too large. It will probably break in other ways.

*And you shouldn't use SHA-1 anyway, as the algorithm itself is known to be insecure.*

-----

Based on [RFC 3174](https://tools.ietf.org/html/rfc3174)

## Building

```
meson build
cp sha1.cl build/
ninja -C build
```

## Running

```
cd build/
./sha1 FILE_TO_HASH
```
