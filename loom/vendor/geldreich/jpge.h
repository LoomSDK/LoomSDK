// jpge.h - C++ class for JPEG compression.
// Public domain, Rich Geldreich <richgel99@gmail.com>
// Alex Evans: Added RGBA support, linear memory allocator.
#ifndef JPEG_ENCODER_H
#define JPEG_ENCODER_H

namespace jpge {
typedef unsigned char  uint8;
typedef signed short   int16;
typedef signed int     int32;
typedef unsigned short uint16;
typedef unsigned int   uint32;
typedef unsigned int   uint;

struct rgb {
    uint8 r,g,b;
};

struct rgba {
    uint8 r,g,b,a;
};

typedef double dct_t;
typedef int16 dctq_t; // quantized

// JPEG chroma subsampling factors. Y_ONLY (grayscale images) and H2V2 (color images) are the most common.
enum subsampling_t { Y_ONLY = 0, H1V1 = 1, H2V1 = 2, H2V2 = 3 };

// JPEG compression parameters structure.
struct params {
    inline params() : m_quality(85), m_subsampling(H2V2), m_no_chroma_discrim_flag(false) { }

    inline bool check() const {
        if ((m_quality < 1) || (m_quality > 100)) return false;
        if ((uint)m_subsampling > (uint)H2V2) return false;
        return true;
    }

    // Quality: 1-100, higher is better. Typical values are around 50-95.
    float m_quality;

    // m_subsampling:
    // 0 = Y (grayscale) only
    // 1 = YCbCr, no subsampling (H1V1, YCbCr 1x1x1, 3 blocks per MCU)
    // 2 = YCbCr, H2V1 subsampling (YCbCr 2x1x1, 4 blocks per MCU)
    // 3 = YCbCr, H2V2 subsampling (YCbCr 4x1x1, 6 blocks per MCU-- very common)
    subsampling_t m_subsampling;

    // Disables CbCr discrimination - only intended for testing.
    // If true, the Y quantization table is also used for the CbCr channels.
    bool m_no_chroma_discrim_flag;
};

// Writes JPEG image to a file.
// num_channels must be 1 (Y) or 3 (RGB), image pitch must be width*num_channels.
bool compress_image_to_jpeg_file(const char *pFilename, int width, int height, int num_channels, const uint8 *pImage_data, const params &comp_params = params());

// Writes JPEG image to memory buffer.
// On entry, buf_size is the size of the output buffer pointed at by pBuf, which should be at least ~1024 bytes.
// If return value is true, buf_size will be set to the size of the compressed data.
bool compress_image_to_jpeg_file_in_memory(void *pBuf, int &buf_size, int width, int height, int num_channels, const uint8 *pImage_data, const params &comp_params = params());

// Output stream abstract class - used by the jpeg_encoder class to write to the output stream.
// put_buf() is generally called with len==JPGE_OUT_BUF_SIZE bytes, but for headers it'll be called with smaller amounts.
class output_stream {
public:
    virtual ~output_stream() { };
    virtual bool put_buf(const void *Pbuf, int len) = 0;
    template<class T> inline bool put_obj(const T &obj) {
        return put_buf(&obj, sizeof(T));
    }
};

bool compress_image_to_stream(output_stream &dst_stream, int width, int height, int num_channels, const uint8 *pImage_data, const params &comp_params);

class huffman_table {
public:
    uint m_codes[256];
    uint8 m_code_sizes[256];
    uint8 m_bits[17];
    uint8 m_val[256];
    uint32 m_count[256];

    void optimize(int table_len);
    void compute();
};

class component {
public:
    uint8 m_h_samp, m_v_samp;
    int m_last_dc_val;
};

struct huffman_dcac {
    int32 m_quantization_table[64];
    huffman_table dc,ac;
};

class image {
public:
    void init();
    void deinit();

    int m_x, m_y;

    float get_px(int x, int y);
    void set_px(float px, int x, int y);

    void load_block(dct_t *, int x, int y);
    dctq_t *get_dctq(int x, int y);

    void subsample(image &luma, int v_samp);

private:
    float *m_pixels;
    dctq_t *m_dctqs; // quantized dcts

    dct_t blend_dual(int x, int y, image &);
    dct_t blend_quad(int x, int y, image &);
};

// Lower level jpeg_encoder class - useful if more control is needed than the above helper functions.
class jpeg_encoder {
public:
    jpeg_encoder();
    ~jpeg_encoder();

    // Initializes the compressor.
    // pStream: The stream object to use for writing compressed data.
    // params - Compression parameters structure, defined above.
    // width, height  - Image dimensions.
    // Returns false on out of memory or if a stream write fails.
    bool init(output_stream *pStream, int width, int height, const params &comp_params = params());

    const params &get_params() const {
        return m_params;
    }

    // Deinitializes the compressor, freeing any allocated memory. May be called at any time.
    void deinit();

    // Call this method with each source scanline.
    // width * src_channels bytes per scanline is expected (RGB or Y format).
    // channels - May be 1, or 3. 1 indicates grayscale, 3 indicates RGB source data.
    // Returns false on out of memory or if a stream write fails.
    bool read_image(const uint8 *data, int width, int height, int bpp);
    bool process_scanline2(const uint8 *pScanline, int y);

    // You must call after all scanlines are processed to finish compression.
    bool compress_image();
    void load_mcu_Y(const uint8 *pSrc, int width, int bpp, int y);
    void load_mcu_YCC(const uint8 *pSrc, int width, int bpp, int y);

private:
    jpeg_encoder(const jpeg_encoder &);
    jpeg_encoder &operator =(const jpeg_encoder &);

    output_stream *m_pStream;
    params m_params;
    uint8 m_num_components;
    component m_comp[3];

    struct huffman_dcac m_huff[2];
    enum { JPGE_OUT_BUF_SIZE = 2048 };
    uint8 m_out_buf[JPGE_OUT_BUF_SIZE];
    uint8 *m_pOut_buf;
    uint m_out_buf_left;
    uint32 m_bit_buffer;
    uint m_bits_in;
    bool m_all_stream_writes_succeeded;
    int m_mcu_w, m_mcu_h;
    int m_x, m_y;
    image m_image[3];

    void emit_byte(uint8 i);
    void emit_word(uint i);
    void emit_marker(int marker);
    void emit_jfif_app0();
    void emit_dqt();
    void emit_sof();
    void emit_dht(uint8 *bits, uint8 *val, int index, bool ac_flag);
    void emit_dhts();
    void emit_sos();
    void emit_start_markers();
    bool emit_end_markers();
    void compute_quant_table(int32 *dst, int16 *src);
    void adjust_quant_table(int32 *dst, int32 *src);
    void reset_last_dc();
    void compute_huffman_tables();
    bool jpg_open(int p_x_res, int p_y_res);
    void quantize_pixels(dct_t *pSrc, int16 *pDst, const int32 *q);
    void flush_output_buffer();
    void put_bits(uint bits, uint len);
    void put_signed_int_bits(int num, uint len);
    void code_block(dctq_t *coefficients, huffman_dcac *huff, component *comp, bool putbits);
    void code_mcu_row(int y, bool write);
    void clear();
    void init();
};

} // namespace jpge

#endif // JPEG_ENCODER