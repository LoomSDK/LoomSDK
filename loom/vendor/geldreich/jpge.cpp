/**
 * © 2013 Kornel Lesiński. All rights reserved.
 * Based on Public Domain code by Rich Geldreich.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * • Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * • Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation and/or
 *   other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "jpge.h"

#include <stdlib.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef _MSC_VER
#include <math.h>
#endif

#define JPGE_MAX(a,b) (((a)>(b))?(a):(b))
#define JPGE_MIN(a,b) (((a)<(b))?(a):(b))

 #include "loom/common/core/allocator.h"

namespace jpge {

loom_allocator_t *gJPEGEAllocator = NULL;

static inline void *jpge_malloc(size_t nSize) { return lmAlloc(gJPEGEAllocator, nSize); }
static inline void jpge_free(void *p) { lmFree(gJPEGEAllocator, p); }

// Various JPEG enums and tables.
enum { M_SOF0 = 0xC0, M_DHT = 0xC4, M_SOI = 0xD8, M_EOI = 0xD9, M_SOS = 0xDA, M_DQT = 0xDB, M_APP0 = 0xE0 };
enum { DC_LUM_CODES = 12, AC_LUM_CODES = 256, DC_CHROMA_CODES = 12, AC_CHROMA_CODES = 256, MAX_HUFF_SYMBOLS = 257, MAX_HUFF_CODESIZE = 32 };

static uint8 s_zag[64] = { 0,1,8,16,9,2,3,10,17,24,32,25,18,11,4,5,12,19,26,33,40,48,41,34,27,20,13,6,7,14,21,28,35,42,49,56,57,50,43,36,29,22,15,23,30,37,44,51,58,59,52,45,38,31,39,46,53,60,61,54,47,55,62,63 };
static int16 s_std_lum_quant[64] = { 16,11,12,14,12,10,16,14,13,14,18,17,16,19,24,40,26,24,22,22,24,49,35,37,29,40,58,51,61,60,57,51,56,55,64,72,92,78,64,68,87,69,55,56,80,109,81,87,95,98,103,104,103,62,77,113,121,112,100,120,92,101,103,99 };
static int16 s_std_croma_quant[64] = { 17,18,18,24,21,24,47,26,26,47,99,66,56,66,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 };

// Low-level helper functions.
template <class T> inline void clear_obj(T &obj)
{
    memset(&obj, 0, sizeof(obj));
}

template<class T> static void RGB_to_YCC(image *img, const T *src, int width, int y)
{
    for (int x = 0; x < width; x++) {
        const int r = src[x].r, g = src[x].g, b = src[x].b;
        img[0].set_px( (0.299f     * r) + (0.587f     * g) + (0.114f     * b)-128.0f, x, y);
        img[1].set_px(-(0.168736f  * r) - (0.331264f  * g) + (0.5f       * b), x, y);
        img[2].set_px( (0.5f       * r) - (0.418688f  * g) - (0.081312f  * b), x, y);
    }
}

template<class T> static void RGB_to_Y(image &img, const T *pSrc, int width, int y)
{
    for (int x=0; x < width; x++) {
        img.set_px((pSrc[x].r*0.299f) + (pSrc[x].g*0.587f) + (pSrc[x].b*0.114f)-128.0f, x, y);
    }
}

static void Y_to_YCC(image *img, const uint8 *pSrc, int width, int y)
{
    for(int x=0; x < width; x++) {
        img[0].set_px(pSrc[x]-128.0f, x, y);
        img[1].set_px(0, x, y);
        img[2].set_px(0, x, y);
    }
}

inline float image::get_px(int x, int y) {
    return m_pixels[y*m_x + x];
}

inline void image::set_px(float px, int x, int y) {
    m_pixels[y*m_x + x] = px;
}

dctq_t *image::get_dctq(int x, int y) {
    return &m_dctqs[64*(y/8 * m_x/8 + x/8)];
}

void image::subsample(image &luma, int v_samp) {
    if (v_samp == 2) {
        for(int y=0; y < m_y; y+=2) {
            for(int x=0; x < m_x; x+=2) {
                m_pixels[m_x/4*y + x/2] = (float) blend_quad(x, y, luma);
            }
        }
        m_x /= 2;
        m_y /= 2;
    } else {
        for(int y=0; y < m_y; y++) {
            for(int x=0; x < m_x; x+=2) {
                m_pixels[m_x/2*y + x/2] = (float) blend_dual(x, y, luma);
            }
        }
        m_x /= 2;
    }
}


// Forward DCT
static void dct(dct_t *data)
{
    dct_t z1, z2, z3, z4, z5, tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp10, tmp11, tmp12, tmp13, *data_ptr;

    data_ptr = data;

    for (int c=0; c < 8; c++) {
        tmp0 = data_ptr[0] + data_ptr[7];
        tmp7 = data_ptr[0] - data_ptr[7];
        tmp1 = data_ptr[1] + data_ptr[6];
        tmp6 = data_ptr[1] - data_ptr[6];
        tmp2 = data_ptr[2] + data_ptr[5];
        tmp5 = data_ptr[2] - data_ptr[5];
        tmp3 = data_ptr[3] + data_ptr[4];
        tmp4 = data_ptr[3] - data_ptr[4];
        tmp10 = tmp0 + tmp3;
        tmp13 = tmp0 - tmp3;
        tmp11 = tmp1 + tmp2;
        tmp12 = tmp1 - tmp2;
        data_ptr[0] = tmp10 + tmp11;
        data_ptr[4] = tmp10 - tmp11;
        z1 = (tmp12 + tmp13) * 0.541196100;
        data_ptr[2] = z1 + tmp13 * 0.765366865;
        data_ptr[6] = z1 + tmp12 * - 1.847759065;
        z1 = tmp4 + tmp7;
        z2 = tmp5 + tmp6;
        z3 = tmp4 + tmp6;
        z4 = tmp5 + tmp7;
        z5 = (z3 + z4) * 1.175875602;
        tmp4 *= 0.298631336;
        tmp5 *= 2.053119869;
        tmp6 *= 3.072711026;
        tmp7 *= 1.501321110;
        z1 *= -0.899976223;
        z2 *= -2.562915447;
        z3 *= -1.961570560;
        z4 *= -0.390180644;
        z3 += z5;
        z4 += z5;
        data_ptr[7] = tmp4 + z1 + z3;
        data_ptr[5] = tmp5 + z2 + z4;
        data_ptr[3] = tmp6 + z2 + z3;
        data_ptr[1] = tmp7 + z1 + z4;
        data_ptr += 8;
    }

    data_ptr = data;

    for (int c=0; c < 8; c++) {
        tmp0 = data_ptr[8*0] + data_ptr[8*7];
        tmp7 = data_ptr[8*0] - data_ptr[8*7];
        tmp1 = data_ptr[8*1] + data_ptr[8*6];
        tmp6 = data_ptr[8*1] - data_ptr[8*6];
        tmp2 = data_ptr[8*2] + data_ptr[8*5];
        tmp5 = data_ptr[8*2] - data_ptr[8*5];
        tmp3 = data_ptr[8*3] + data_ptr[8*4];
        tmp4 = data_ptr[8*3] - data_ptr[8*4];
        tmp10 = tmp0 + tmp3;
        tmp13 = tmp0 - tmp3;
        tmp11 = tmp1 + tmp2;
        tmp12 = tmp1 - tmp2;
        data_ptr[8*0] = (tmp10 + tmp11) / 8.0;
        data_ptr[8*4] = (tmp10 - tmp11) / 8.0;
        z1 = (tmp12 + tmp13) * 0.541196100;
        data_ptr[8*2] = (z1 + tmp13 * 0.765366865) / 8.0;
        data_ptr[8*6] = (z1 + tmp12 * -1.847759065) / 8.0;
        z1 = tmp4 + tmp7;
        z2 = tmp5 + tmp6;
        z3 = tmp4 + tmp6;
        z4 = tmp5 + tmp7;
        z5 = (z3 + z4) * 1.175875602;
        tmp4 *= 0.298631336;
        tmp5 *= 2.053119869;
        tmp6 *= 3.072711026;
        tmp7 *= 1.501321110;
        z1 *= -0.899976223;
        z2 *= -2.562915447;
        z3 *= -1.961570560;
        z4 *= -0.390180644;
        z3 += z5;
        z4 += z5;
        data_ptr[8*7] = (tmp4 + z1 + z3) / 8.0;
        data_ptr[8*5] = (tmp5 + z2 + z4) / 8.0;
        data_ptr[8*3] = (tmp6 + z2 + z3) / 8.0;
        data_ptr[8*1] = (tmp7 + z1 + z4) / 8.0;
        data_ptr++;
    }
}

struct sym_freq {
    uint m_key, m_sym_index;
};

// Radix sorts sym_freq[] array by 32-bit key m_key. Returns ptr to sorted values.
static inline sym_freq *radix_sort_syms(uint num_syms, sym_freq *pSyms0, sym_freq *pSyms1)
{
    const uint cMaxPasses = 4;
    uint32 hist[256 * cMaxPasses]; clear_obj(hist);
    for (uint i = 0; i < num_syms; i++) {
        uint freq = pSyms0[i].m_key;
        hist[freq & 0xFF]++;
        hist[256 + ((freq >> 8) & 0xFF)]++;
        hist[256*2 + ((freq >> 16) & 0xFF)]++;
        hist[256*3 + ((freq >> 24) & 0xFF)]++;
    }
    sym_freq *pCur_syms = pSyms0, *pNew_syms = pSyms1;
    uint total_passes = cMaxPasses; while ((total_passes > 1) && (num_syms == hist[(total_passes - 1) * 256])) total_passes--;
    for (uint pass_shift = 0, pass = 0; pass < total_passes; pass++, pass_shift += 8) {
        const uint32 *pHist = &hist[pass << 8];
        uint offsets[256], cur_ofs = 0;
        for (uint i = 0; i < 256; i++) {
            offsets[i] = cur_ofs;
            cur_ofs += pHist[i];
        }
        for (uint i = 0; i < num_syms; i++)
            pNew_syms[offsets[(pCur_syms[i].m_key >> pass_shift) & 0xFF]++] = pCur_syms[i];
        sym_freq *t = pCur_syms; pCur_syms = pNew_syms; pNew_syms = t;
    }
    return pCur_syms;
}

// calculate_minimum_redundancy() originally written by: Alistair Moffat, alistair@cs.mu.oz.au, Jyrki Katajainen, jyrki@diku.dk, November 1996.
static void calculate_minimum_redundancy(sym_freq *A, int n)
{
    int root, leaf, next, avbl, used, dpth;
    if (n==0) return; else if (n==1) {
        A[0].m_key = 1;
        return;
    }
    A[0].m_key += A[1].m_key; root = 0; leaf = 2;
    for (next=1; next < n-1; next++) {
        if (leaf>=n || A[root].m_key<A[leaf].m_key) {
            A[next].m_key = A[root].m_key;
            A[root++].m_key = next;
        } else A[next].m_key = A[leaf++].m_key;
        if (leaf>=n || (root<next && A[root].m_key<A[leaf].m_key)) {
            A[next].m_key += A[root].m_key;
            A[root++].m_key = next;
        } else A[next].m_key += A[leaf++].m_key;
    }
    A[n-2].m_key = 0;
    for (next=n-3; next>=0; next--) A[next].m_key = A[A[next].m_key].m_key+1;
    avbl = 1; used = dpth = 0; root = n-2; next = n-1;
    while (avbl>0) {
        while (root>=0 && (int)A[root].m_key==dpth) {
            used++;
            root--;
        }
        while (avbl>used) {
            A[next--].m_key = dpth;
            avbl--;
        }
        avbl = 2*used; dpth++; used = 0;
    }
}

// Limits canonical Huffman code table's max code size to max_code_size.
static void huffman_enforce_max_code_size(int *pNum_codes, int code_list_len, int max_code_size)
{
    if (code_list_len <= 1) return;

    for (int i = max_code_size + 1; i <= MAX_HUFF_CODESIZE; i++) pNum_codes[max_code_size] += pNum_codes[i];

    uint32 total = 0;
    for (int i = max_code_size; i > 0; i--)
        total += (((uint32)pNum_codes[i]) << (max_code_size - i));

    while (total != (1UL << max_code_size)) {
        pNum_codes[max_code_size]--;
        for (int i = max_code_size - 1; i > 0; i--) {
            if (pNum_codes[i]) {
                pNum_codes[i]--;
                pNum_codes[i + 1] += 2;
                break;
            }
        }
        total--;
    }
}

// Generates an optimized offman table.
void huffman_table::optimize(int table_len)
{
    sym_freq syms0[MAX_HUFF_SYMBOLS], syms1[MAX_HUFF_SYMBOLS];
    syms0[0].m_key = 1; syms0[0].m_sym_index = 0;  // dummy symbol, assures that no valid code contains all 1's
    int num_used_syms = 1;
    for (int i = 0; i < table_len; i++)
        if (m_count[i]) {
            syms0[num_used_syms].m_key = m_count[i];
            syms0[num_used_syms++].m_sym_index = i + 1;
        }
    sym_freq *pSyms = radix_sort_syms(num_used_syms, syms0, syms1);
    calculate_minimum_redundancy(pSyms, num_used_syms);

    // Count the # of symbols of each code size.
    int num_codes[1 + MAX_HUFF_CODESIZE]; clear_obj(num_codes);
    for (int i = 0; i < num_used_syms; i++)
        num_codes[pSyms[i].m_key]++;

    const uint JPGE_CODE_SIZE_LIMIT = 16; // the maximum possible size of a JPEG Huffman code (valid range is [9,16] - 9 vs. 8 because of the dummy symbol)
    huffman_enforce_max_code_size(num_codes, num_used_syms, JPGE_CODE_SIZE_LIMIT);

    // Compute m_huff_bits array, which contains the # of symbols per code size.
    clear_obj(m_bits);
    for (int i = 1; i <= (int)JPGE_CODE_SIZE_LIMIT; i++)
        m_bits[i] = static_cast<uint8>(num_codes[i]);

    // Remove the dummy symbol added above, which must be in largest bucket.
    for (int i = JPGE_CODE_SIZE_LIMIT; i >= 1; i--) {
        if (m_bits[i]) {
            m_bits[i]--;
            break;
        }
    }

    // Compute the m_huff_val array, which contains the symbol indices sorted by code size (smallest to largest).
    for (int i = num_used_syms - 1; i >= 1; i--)
        m_val[num_used_syms - 1 - i] = static_cast<uint8>(pSyms[i].m_sym_index - 1);
}

// JPEG marker generation.
void jpeg_encoder::emit_byte(uint8 i)
{
    m_all_stream_writes_succeeded = m_all_stream_writes_succeeded && m_pStream->put_obj(i);
}

void jpeg_encoder::emit_word(uint i)
{
    emit_byte(uint8(i >> 8)); emit_byte(uint8(i & 0xFF));
}

void jpeg_encoder::emit_marker(int marker)
{
    emit_byte(uint8(0xFF)); emit_byte(uint8(marker));
}

// Emit JFIF marker
void jpeg_encoder::emit_jfif_app0()
{
    emit_marker(M_APP0);
    emit_word(2 + 4 + 1 + 2 + 1 + 2 + 2 + 1 + 1);
    emit_byte(0x4A); emit_byte(0x46); emit_byte(0x49); emit_byte(0x46); /* Identifier: ASCII "JFIF" */
    emit_byte(0);
    emit_byte(1);      /* Major version */
    emit_byte(1);      /* Minor version */
    emit_byte(0);      /* Density unit */
    emit_word(1);
    emit_word(1);
    emit_byte(0);      /* No thumbnail image */
    emit_byte(0);
}

// Emit quantization tables
void jpeg_encoder::emit_dqt()
{
    for (int i = 0; i < ((m_num_components == 3) ? 2 : 1); i++) {
        emit_marker(M_DQT);
        emit_word(64 + 1 + 2);
        emit_byte(static_cast<uint8>(i));
        for (int j = 0; j < 64; j++)
            emit_byte(static_cast<uint8>(m_huff[i].m_quantization_table[j]));
    }
}

// Emit start of frame marker
void jpeg_encoder::emit_sof()
{
    emit_marker(M_SOF0);                           /* baseline */
    emit_word(3 * m_num_components + 2 + 5 + 1);
    emit_byte(8);                                  /* precision */
    emit_word(m_y);
    emit_word(m_x);
    emit_byte(m_num_components);
    for (int i = 0; i < m_num_components; i++) {
        emit_byte(static_cast<uint8>(i + 1));                                   /* component ID     */
        emit_byte((m_comp[i].m_h_samp << 4) + m_comp[i].m_v_samp);  /* h and v sampling */
        emit_byte(i > 0);                                   /* quant. table num */
    }
}

// Emit Huffman table.
void jpeg_encoder::emit_dht(uint8 *bits, uint8 *val, int index, bool ac_flag)
{
    emit_marker(M_DHT);

    int length = 0;
    for (int i = 1; i <= 16; i++)
        length += bits[i];

    emit_word(length + 2 + 1 + 16);
    emit_byte(static_cast<uint8>(index + (ac_flag << 4)));

    for (int i = 1; i <= 16; i++)
        emit_byte(bits[i]);

    for (int i = 0; i < length; i++)
        emit_byte(val[i]);
}

// Emit all Huffman tables.
void jpeg_encoder::emit_dhts()
{
    emit_dht(m_huff[0].dc.m_bits, m_huff[0].dc.m_val, 0, false);
    emit_dht(m_huff[0].ac.m_bits, m_huff[0].ac.m_val, 0, true);
    if (m_num_components == 3) {
        emit_dht(m_huff[1].dc.m_bits, m_huff[1].dc.m_val, 1, false);
        emit_dht(m_huff[1].ac.m_bits, m_huff[1].ac.m_val, 1, true);
    }
}

// emit start of scan
void jpeg_encoder::emit_sos()
{
    emit_marker(M_SOS);
    emit_word(2 * m_num_components + 2 + 1 + 3);
    emit_byte(m_num_components);
    for (int i = 0; i < m_num_components; i++) {
        emit_byte(static_cast<uint8>(i + 1));
        if (i == 0)
            emit_byte((0 << 4) + 0);
        else
            emit_byte((1 << 4) + 1);
    }
    emit_byte(0);     /* spectral selection */
    emit_byte(63);
    emit_byte(0);
}

// Emit all markers at beginning of image file.
void jpeg_encoder::emit_start_markers()
{
    emit_marker(M_SOI);
    emit_jfif_app0();
    emit_dqt();
    emit_sof();
    emit_dhts();
    emit_sos();
}

// Compute the actual canonical Huffman codes/code sizes given the JPEG huff bits and val arrays.
void huffman_table::compute()
{
    int last_p, si;
    uint8 huff_size[257];
    uint huff_code[257];
    uint code;

    int p = 0;
    for (char l = 1; l <= 16; l++)
        for (int i = 1; i <= m_bits[l]; i++)
            huff_size[p++] = l;

    huff_size[p] = 0; last_p = p; // write sentinel

    code = 0; si = huff_size[0]; p = 0;

    while (huff_size[p]) {
        while (huff_size[p] == si)
            huff_code[p++] = code++;
        code <<= 1;
        si++;
    }

    memset(m_codes, 0, sizeof(m_codes[0])*256);
    memset(m_code_sizes, 0, sizeof(m_code_sizes[0])*256);
    for (p = 0; p < last_p; p++) {
        m_codes[m_val[p]]      = huff_code[p];
        m_code_sizes[m_val[p]] = huff_size[p];
    }
}

// Quantization table generation.
void jpeg_encoder::compute_quant_table(int32 *pDst, int16 *pSrc)
{
    float q;
    if (m_params.m_quality < 50)
        q = 5000.0f / m_params.m_quality;
    else
        q = 200.0f - m_params.m_quality * 2.0f;
    for (int i = 0; i < 64; i++) {
        int32 j = pSrc[i]; j = (int32) (j * q + 50L) / 100L;
        pDst[i] = JPGE_MIN(JPGE_MAX(j, 1), 1024/3);
    }
    // DC quantized worse than 8 makes overall quality fall off the cliff
    if (pDst[0] > 8) pDst[0] = (pDst[0]+8*3)/4;
    if (pDst[1] > 24) pDst[1] = (pDst[1]+24)/2;
    if (pDst[2] > 24) pDst[2] = (pDst[2]+24)/2;
}

void jpeg_encoder::reset_last_dc()
{
    m_bit_buffer = 0; m_bits_in = 0;
    m_comp[0].m_last_dc_val=0; m_comp[1].m_last_dc_val=0; m_comp[2].m_last_dc_val=0;
}

void jpeg_encoder::compute_huffman_tables()
{
    m_huff[0].dc.optimize(DC_LUM_CODES);
    m_huff[0].dc.compute();

    m_huff[0].ac.optimize(AC_LUM_CODES);
    m_huff[0].ac.compute();

    if (m_num_components > 1) {
        m_huff[1].dc.optimize(DC_CHROMA_CODES);
        m_huff[1].dc.compute();

        m_huff[1].ac.optimize(AC_CHROMA_CODES);
        m_huff[1].ac.compute();
    }
}

bool jpeg_encoder::jpg_open(int p_x_res, int p_y_res)
{
    m_num_components = 3;
    switch (m_params.m_subsampling) {
    case Y_ONLY: {
        m_num_components = 1;
        m_comp[0].m_h_samp = 1; m_comp[0].m_v_samp = 1;
        m_mcu_w            = 8; m_mcu_h            = 8;
        break;
    }
    case H1V1: {
        m_comp[0].m_h_samp = 1; m_comp[0].m_v_samp = 1;
        m_comp[1].m_h_samp = 1; m_comp[1].m_v_samp = 1;
        m_comp[2].m_h_samp = 1; m_comp[2].m_v_samp = 1;
        m_mcu_w            = 8; m_mcu_h            = 8;
        break;
    }
    case H2V1: {
        m_comp[0].m_h_samp = 2; m_comp[0].m_v_samp = 1;
        m_comp[1].m_h_samp = 1; m_comp[1].m_v_samp = 1;
        m_comp[2].m_h_samp = 1; m_comp[2].m_v_samp = 1;
        m_mcu_w            = 16; m_mcu_h           = 8;
        break;
    }
    case H2V2: {
        m_comp[0].m_h_samp = 2; m_comp[0].m_v_samp = 2;
        m_comp[1].m_h_samp = 1; m_comp[1].m_v_samp = 1;
        m_comp[2].m_h_samp = 1; m_comp[2].m_v_samp = 1;
        m_mcu_w            = 16; m_mcu_h          = 16;
    }
    }

    m_x = p_x_res; m_y = p_y_res;
    m_image[2].m_x = m_image[1].m_x = m_image[0].m_x = (m_x + m_mcu_w - 1) & (~(m_mcu_w - 1));
    m_image[2].m_y = m_image[1].m_y = m_image[0].m_y = (m_y + m_mcu_h - 1) & (~(m_mcu_h - 1));

    for(int c=0; c < m_num_components; c++) m_image[c].init();

    clear_obj(m_huff);
    compute_quant_table(m_huff[0].m_quantization_table, s_std_lum_quant);
    compute_quant_table(m_huff[1].m_quantization_table, m_params.m_no_chroma_discrim_flag ? s_std_lum_quant : s_std_croma_quant);

    m_out_buf_left = JPGE_OUT_BUF_SIZE;
    m_pOut_buf = m_out_buf;

    reset_last_dc();
    return m_all_stream_writes_succeeded;
}

void image::init() {
    m_pixels = static_cast<float *>(jpge_malloc(m_x * sizeof(float) * m_y));
    m_dctqs = static_cast<dctq_t *>(jpge_malloc(m_x * sizeof(dctq_t) * m_y));
}

void image::deinit() {
    jpge_free(m_pixels); m_pixels = NULL;
    jpge_free(m_dctqs); m_dctqs = NULL;
}

void image::load_block(dct_t *pDst, int x, int y)
{
    for (int i = 0; i < 8; i++, pDst += 8) {
        pDst[0] = get_px(x+0, y+i);
        pDst[1] = get_px(x+1, y+i);
        pDst[2] = get_px(x+2, y+i);
        pDst[3] = get_px(x+3, y+i);
        pDst[4] = get_px(x+4, y+i);
        pDst[5] = get_px(x+5, y+i);
        pDst[6] = get_px(x+6, y+i);
        pDst[7] = get_px(x+7, y+i);
    }
}

inline dct_t image::blend_dual(int x, int y, image &luma)
{
    dct_t a = 129-abs((long)luma.get_px(x,  y));
    dct_t b = 129-abs((long)luma.get_px(x+1,y));
    return (get_px(x,  y)*a
          + get_px(x+1,y)*b) / (a+b);
}

inline dct_t image::blend_quad(int x, int y, image &luma)
{
    dct_t a = 129-abs((long)luma.get_px(x,  y  ));
    dct_t b = 129-abs((long)luma.get_px(x+1,y  ));
    dct_t c = 129-abs((long)luma.get_px(x,  y+1));
    dct_t d = 129-abs((long)luma.get_px(x+1,y+1));
    return  (get_px(x,  y  )*a
           + get_px(x+1,y  )*b
           + get_px(x,  y+1)*c
           + get_px(x+1,y+1)*d) / (a+b+c+d);
}

inline static dctq_t round_to_zero(const dct_t j, const int32 quant) {
    if (j < 0) {
        dctq_t jtmp = (dctq_t) (-j + (quant >> 1));
        return (jtmp < quant) ? 0 : static_cast<dctq_t>(-(jtmp / quant));
    } else {
        dctq_t jtmp = (dctq_t) (j + (quant >> 1));
        return (jtmp < quant) ? 0 : static_cast<dctq_t>((jtmp / quant));
    }
}

void jpeg_encoder::quantize_pixels(dct_t *pSrc, dctq_t *pDst, const int32 *quant)
{
    dct(pSrc);
    for (int i = 0; i < 64; i++) {
        pDst[i] = round_to_zero(pSrc[s_zag[i]], quant[i]);
    }
}

void jpeg_encoder::flush_output_buffer()
{
    if (m_out_buf_left != JPGE_OUT_BUF_SIZE)
        m_all_stream_writes_succeeded = m_all_stream_writes_succeeded && m_pStream->put_buf(m_out_buf, JPGE_OUT_BUF_SIZE - m_out_buf_left);
    m_pOut_buf = m_out_buf;
    m_out_buf_left = JPGE_OUT_BUF_SIZE;
}

inline static uint bit_count(int temp1) {
    if (temp1 < 0) temp1 = -temp1;

    uint nbits = 0;
    while (temp1) {
        nbits++; temp1 >>= 1;
    }
    return nbits;
}

void jpeg_encoder::put_signed_int_bits(int num, uint len) {
    if (num < 0) num--;
    put_bits(num & ((1 << len) - 1), len);
}

void jpeg_encoder::put_bits(uint bits, uint len)
{
    m_bit_buffer |= ((uint32)bits << (24 - (m_bits_in += len)));
    while (m_bits_in >= 8) {
        uint8 c;
#define JPGE_PUT_BYTE(c) { *m_pOut_buf++ = (c); if (--m_out_buf_left == 0) flush_output_buffer(); }
        JPGE_PUT_BYTE(c = (uint8)((m_bit_buffer >> 16) & 0xFF));
        if (c == 0xFF) JPGE_PUT_BYTE(0);
        m_bit_buffer <<= 8;
        m_bits_in -= 8;
    }
}

void jpeg_encoder::code_block(dctq_t *src, huffman_dcac *huff, component *comp, bool write)
{
    const int dc_delta = src[0] - comp->m_last_dc_val;
    comp->m_last_dc_val = src[0];

    const uint nbits = bit_count(dc_delta);

    if (write) {
        put_bits(huff->dc.m_codes[nbits], huff->dc.m_code_sizes[nbits]);
        put_signed_int_bits(dc_delta, nbits);
    } else {
        huff->dc.m_count[nbits]++;
    }

    int run_len = 0;
    for (int i = 1; i < 64; i++) {
        const dctq_t ac_val = src[i];
        if (ac_val == 0)
            run_len++;
        else {
            while (run_len >= 16) {
                if (write) {
                    put_bits(huff->ac.m_codes[0xF0], huff->ac.m_code_sizes[0xF0]);
                } else {
                    huff->ac.m_count[0xF0]++;
                }
                run_len -= 16;
            }
            const uint nbits = bit_count(ac_val);
            const int code = (run_len << 4) + nbits;

            if (write) {
                put_bits(huff->ac.m_codes[code], huff->ac.m_code_sizes[code]);
                put_signed_int_bits(ac_val, nbits);
            } else {
                huff->ac.m_count[code]++;
            }
            run_len = 0;
        }
    }
    if (run_len) {
        if (write) {
            put_bits(huff->ac.m_codes[0], huff->ac.m_code_sizes[0]);
        } else {
            huff->ac.m_count[0]++;
        }
    }
}

void jpeg_encoder::code_mcu_row(int y, bool write)
{
    if (m_num_components == 1) {
        for (int x = 0; x < m_x; x += m_mcu_w) {
            code_block(m_image[0].get_dctq(x, y), &m_huff[0], &m_comp[0], write);
        }
    } else if ((m_comp[0].m_h_samp == 1) && (m_comp[0].m_v_samp == 1)) {
        for (int x = 0; x < m_x; x += m_mcu_w) {
            code_block(m_image[0].get_dctq(x, y), &m_huff[0], &m_comp[0], write);
            code_block(m_image[1].get_dctq(x, y), &m_huff[1], &m_comp[1], write);
            code_block(m_image[2].get_dctq(x, y), &m_huff[1], &m_comp[2], write);
        }
    } else if ((m_comp[0].m_h_samp == 2) && (m_comp[0].m_v_samp == 1)) {
        for (int x = 0; x < m_x; x += m_mcu_w) {
            code_block(m_image[0].get_dctq(x,   y), &m_huff[0], &m_comp[0], write);
            code_block(m_image[0].get_dctq(x+8, y), &m_huff[0], &m_comp[0], write);
            code_block(m_image[1].get_dctq(x/2, y), &m_huff[1], &m_comp[1], write);
            code_block(m_image[2].get_dctq(x/2, y), &m_huff[1], &m_comp[2], write);
        }
    } else if ((m_comp[0].m_h_samp == 2) && (m_comp[0].m_v_samp == 2)) {
        for (int x = 0; x < m_x; x += m_mcu_w) {
            code_block(m_image[0].get_dctq(x,   y),   &m_huff[0], &m_comp[0], write);
            code_block(m_image[0].get_dctq(x+8, y),   &m_huff[0], &m_comp[0], write);
            code_block(m_image[0].get_dctq(x,   y+8), &m_huff[0], &m_comp[0], write);
            code_block(m_image[0].get_dctq(x+8, y+8), &m_huff[0], &m_comp[0], write);
            code_block(m_image[1].get_dctq(x/2, y/2), &m_huff[1], &m_comp[1], write);
            code_block(m_image[2].get_dctq(x/2, y/2), &m_huff[1], &m_comp[2], write);
        }
    }
}

bool jpeg_encoder::emit_end_markers()
{
    put_bits(0x7F, 7);
    flush_output_buffer();
    emit_marker(M_EOI);
    return m_all_stream_writes_succeeded;
}

bool jpeg_encoder::compress_image()
{
    for(int c=0; c < m_num_components; c++) {
        for (int y = 0; y < m_image[c].m_y; y+= 8) {
            for (int x = 0; x < m_image[c].m_x; x += 8) {
                dct_t sample[64];
                m_image[c].load_block(sample, x, y);
                quantize_pixels(sample, m_image[c].get_dctq(x, y), m_huff[c > 0].m_quantization_table);
            }
        }
    }

    for (int y = 0; y < m_y; y+= m_mcu_h) {
        code_mcu_row(y, false);
    }
    compute_huffman_tables();
    reset_last_dc();

    emit_start_markers();
    for (int y = 0; y < m_y; y+= m_mcu_h) {
        if (!m_all_stream_writes_succeeded) return false;
        code_mcu_row(y, true);
    }
    return emit_end_markers();
}

void jpeg_encoder::load_mcu_Y(const uint8 *pSrc, int width, int bpp, int y)
{
    if (bpp == 4)
        RGB_to_Y(m_image[0], reinterpret_cast<const rgba *>(pSrc), width, y);
    else if (bpp == 3)
        RGB_to_Y(m_image[0], reinterpret_cast<const rgb *>(pSrc), width, y);
    else
        for(int x=0; x < width; x++) {
            m_image[0].set_px(pSrc[x]-128.0f, x, y);
        }

    // Possibly duplicate pixels at end of scanline if not a multiple of 8 or 16
    const float lastpx = m_image[0].get_px(width - 1, y);
    for (int x = width; x < m_image[0].m_x; x++) {
        m_image[0].set_px(lastpx, x, y);
    }
}

void jpeg_encoder::load_mcu_YCC(const uint8 *pSrc, int width, int bpp, int y)
{
    if (bpp == 4)
        RGB_to_YCC(m_image, reinterpret_cast<const rgba *>(pSrc), width, y);
    else if (bpp == 3)
        RGB_to_YCC(m_image, reinterpret_cast<const rgb *>(pSrc), width, y);
    else
        Y_to_YCC(m_image, pSrc, width, y);

    // Possibly duplicate pixels at end of scanline if not a multiple of 8 or 16
    for(int c=0; c < m_num_components; c++) {
        const float lastpx = m_image[c].get_px(width - 1, y);
        for (int x = width; x < m_image[0].m_x; x++) {
            m_image[c].set_px(lastpx, x, y);
        }
    }
}

void jpeg_encoder::clear()
{
    m_num_components=0;
    m_all_stream_writes_succeeded = true;
}

jpeg_encoder::jpeg_encoder()
{
    clear();
}

jpeg_encoder::~jpeg_encoder()
{
    deinit();
}

bool jpeg_encoder::init(output_stream *pStream, int width, int height, const params &comp_params)
{
    deinit();
    if (!pStream || width < 1 || height < 1 || !comp_params.check()) return false;
    m_pStream = pStream;
    m_params = comp_params;
    return jpg_open(width, height);
}

void jpeg_encoder::deinit()
{
    for(int c=0; c < m_num_components; c++) m_image[c].deinit();
    clear();
}

bool jpeg_encoder::read_image(const uint8 *image_data, int width, int height, int bpp)
{
    if (bpp != 1 && bpp != 3 && bpp != 4) return false;

    for (int y = 0; y < height; y++) {
        if (m_num_components == 1) {
            load_mcu_Y(image_data + width * y * bpp, width, bpp, y);
        } else {
            load_mcu_YCC(image_data + width * y * bpp, width, bpp, y);
        }
    }

    for(int c=0; c < m_num_components; c++) {
        for (int y = height; y < m_image[c].m_y; y++) {
            for(int x=0; x < m_image[c].m_x; x++) {
                m_image[c].set_px(m_image[c].get_px(x, y-1), x, y);
            }
        }
    }

    if (m_comp[0].m_h_samp == 2) {
        for(int c=1; c < m_num_components; c++) {
            m_image[c].subsample(m_image[0], m_comp[0].m_v_samp);
        }
    }

    // overflow white and black, making distortions overflow as well,
    // so distortions (ringing) will be clamped by the decoder
    if (m_huff[0].m_quantization_table[0] > 2) {
        for(int c=0; c < m_num_components; c++) {
            for(int y=0; y < m_image[c].m_y; y++) {
                for(int x=0; x < m_image[c].m_x; x++) {
                    float px = m_image[c].get_px(x,y);
                    if (px <= -128.f) px -= m_huff[0].m_quantization_table[0];
                    else if (px >= 128.f) px += m_huff[0].m_quantization_table[0];
                    m_image[c].set_px(px, x, y);
                }
            }
        }
    }

    return true;
}


// Higher level wrappers/examples (optional).
#include <stdio.h>

class cfile_stream : public output_stream {
    cfile_stream(const cfile_stream &);
    cfile_stream &operator= (const cfile_stream &);

    FILE *m_pFile;
    bool m_bStatus;

public:
    cfile_stream() : m_pFile(NULL), m_bStatus(false) { }

    virtual ~cfile_stream() {
        close();
    }

    bool open(const char *pFilename) {
        close();
        m_pFile = fopen(pFilename, "wb");
        m_bStatus = (m_pFile != NULL);
        return m_bStatus;
    }

    bool close() {
        if (m_pFile) {
            if (fclose(m_pFile) == EOF) {
                m_bStatus = false;
            }
            m_pFile = NULL;
        }
        return m_bStatus;
    }

    virtual bool put_buf(const void *pBuf, int len) {
        m_bStatus = m_bStatus && (fwrite(pBuf, len, 1, m_pFile) == 1);
        return m_bStatus;
    }

    long get_size() const {
        return m_pFile ? ftell(m_pFile) : 0;
    }
};

// Writes JPEG image to file.
bool compress_image_to_jpeg_file(const char *pFilename, int width, int height, int num_channels, const uint8 *pImage_data, const params &comp_params)
{
    cfile_stream dst_stream;
    if (!dst_stream.open(pFilename))
        return false;

    compress_image_to_stream(dst_stream, width, height, num_channels, pImage_data, comp_params);

    return dst_stream.close();
}

bool compress_image_to_stream(output_stream &dst_stream, int width, int height, int num_channels, const uint8 *pImage_data, const params &comp_params)
{
    jpge::jpeg_encoder encoder;
    if (!encoder.init(&dst_stream, width, height, comp_params))
        return false;

    if (!encoder.read_image(pImage_data, width, height, num_channels))
        return false;

    if (!encoder.compress_image())
        return false;

    encoder.deinit();
    return true;
}

class memory_stream : public output_stream {
    memory_stream(const memory_stream &);
    memory_stream &operator= (const memory_stream &);

    uint8 *m_pBuf;
    uint m_buf_size, m_buf_ofs;

public:
    memory_stream(void *pBuf, uint buf_size) : m_pBuf(static_cast<uint8 *>(pBuf)), m_buf_size(buf_size), m_buf_ofs(0) { }

    virtual ~memory_stream() { }

    virtual bool put_buf(const void *pBuf, int len) {
        uint buf_remaining = m_buf_size - m_buf_ofs;
        if ((uint)len > buf_remaining)
            return false;
        memcpy(m_pBuf + m_buf_ofs, pBuf, len);
        m_buf_ofs += len;
        return true;
    }

    uint get_size() const {
        return m_buf_ofs;
    }
};

bool compress_image_to_jpeg_file_in_memory(void *pDstBuf, int &buf_size, int width, int height, int num_channels, const uint8 *pImage_data, const params &comp_params)
{
    if ((!pDstBuf) || (!buf_size))
        return false;

    memory_stream dst_stream(pDstBuf, buf_size);

    compress_image_to_stream(dst_stream, width, height, num_channels, pImage_data, comp_params);

    buf_size = dst_stream.get_size();
    return true;
}

} // namespace jpge