#include "utBase64.h"

// snippets from http://base64.sourceforge.net/b64.c

// base64 encode/decode

/*
** Translation Table as described in RFC1113
*/
static const char cb64[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*
** Translation Table to decode (created by author)
*/
static const char cd64[] =
    "|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

/*
** encodeblock
**
** encode 3 8-bit binary bytes as 4 '6-bit' characters
*/
static void encodeblock(unsigned char in[3], unsigned char out[4], int len)
{
    out[0] = cb64[in[0] >> 2];
    out[1] = cb64[((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4)];
    out[2] =
        (unsigned char)(
            len > 1 ?
            cb64[((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6)] :
            '=');
    out[3] = (unsigned char)(len > 2 ? cb64[in[2] & 0x3f] : '=');
}


/*
** decodeblock
**
** decode 4 '6-bit' characters into 3 8-bit binary bytes
*/
static void decodeblock(unsigned char in[4], unsigned char out[3])
{
    out[0] = (unsigned char)(in[0] << 2 | in[1] >> 4);
    out[1] = (unsigned char)(in[1] << 4 | in[2] >> 2);
    out[2] = (unsigned char)(((in[2] << 6) & 0xc0) | in[3]);
}


utBase64 utBase64::decode64(const utString& code64)
{
    utBase64 base64;

    base64.bc64 = code64;

    unsigned char in[4], out[3], v;
    int           i, len;

    UTsize c       = 0;
    size_t counter = code64.size() + 1;

    while (counter)
    {
        for (len = 0, i = 0; i < 4 && counter; i++)
        {
            v = 0;
            while (counter && v == 0)
            {
                v = (unsigned char)code64[c++];
                counter--;
                v = (unsigned char)((v < 43 || v > 122) ? 0 : cd64[v - 43]);
                if (v)
                {
                    v = (unsigned char)((v == '$') ? 0 : v - 61);
                }
            }
            if (counter)
            {
                len++;
                if (v)
                {
                    in[i] = (unsigned char)(v - 1);
                }
            }
            else
            {
                in[i] = 0;
            }
        }
        if (len)
        {
            decodeblock(in, out);
            for (i = 0; i < len - 1; i++)
            {
                base64.bc.push_back(out[i]);
            }
        }
    }

    return base64;
}


utBase64 utBase64::encode64(const utArray<unsigned char>& bc)
{
    utBase64 base64;

    base64.bc = bc;

    unsigned char in[3], out[4];
    int           i, len;

    UTsize        counter = bc.size();
    int           c       = 0;
    utArray<char> buffer;

    while (counter)
    {
        len = 0;
        for (i = 0; i < 3; i++)
        {
            if (counter)
            {
                in[i] = (unsigned char)bc[c++];
                len++;
                counter--;
            }
            else
            {
                in[i] = 0;
            }
        }
        if (len)
        {
            encodeblock(in, out, len);
            for (i = 0; i < 4; i++)
            {
                assert(out[i]);
                buffer.push_back(out[i]);
            }
        }
    }

    buffer.push_back('\0');

    base64.bc64 = buffer.ptr();

    return base64;
}
