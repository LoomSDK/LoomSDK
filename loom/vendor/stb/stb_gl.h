// stbgl - v0.01 - Sean Barrett 2008 - public domain
#ifndef INCLUDE_STB_GL_H
#define INCLUDE_STB_GL_H

#define STBI_HEADER_FILE_ONLY
#include "stb_image.c"

#ifndef WINGDIAPI
#define CALLBACK    __stdcall
#define WINGDIAPI   __declspec(dllimport)
#define APIENTRY    __stdcall
#endif
#include <stddef.h>

#ifndef M_PI
#define M_PI  3.14159265358979323846f
#endif

#ifdef __cplusplus
#define STB_EXTERN extern "C"
#else
#define STB_EXTERN
#endif

// like gluPerspective, but:
//    fov is chosen to satisfy both hfov <= max_hfov & vfov <= max_vfov;
//            set one to 179 or 0 to ignore it
//    zoom is applied separately, so you can do linear zoom without
//            mucking with trig with fov; 1 -> use exact fov
//    'aspect' is inferred from the current viewport, and ignores the
//            possibility of non-square pixels
STB_EXTERN void stbgl_Perspective(float zoom, float max_hfov, float max_vfov, float znear, float zfar);
STB_EXTERN void stbgl_PerspectiveViewport(int x, int y, int w, int h, float zoom, float max_hfov, float max_vfov, float znear, float zfar);
STB_EXTERN void stbgl_initCamera_zup_facing_x(void);
STB_EXTERN void stbgl_initCamera_zup_facing_y(void);
STB_EXTERN void stbgl_positionCameraWithEulerAngles(float *loc, float *ang);

STB_EXTERN int stbgl_hasExtension(char *ext);
STB_EXTERN void stbgl_SimpleLight(int index, float bright, float x, float y, float z);
STB_EXTERN void stbgl_GlobalAmbient(float r, float g, float b);

STB_EXTERN int stbgl_LoadTexture(char *filename, char *props);
STB_EXTERN int stbgl_TexImage2D(int texid, int w, int h, void *data, char *props);
STB_EXTERN int stbgl_TexImage2D_Extra(int texid, int w, int h, void *data, int chan, char *props, int preserve_data);
// "props" is a series of characters (and blocks of characters), a la fopen()'s mode,
// e.g.:
//   GLuint texid = stbgl_LoadTexture("myfile.jpg", "mbc")
//      means: load the image "myfile.jpg", and do the following:
//                generate mipmaps
//                use bilinear filtering (not trilinear)
//                use clamp-to-edge on both channels
//
// input descriptor: AT MOST ONE
//   TEXT     MEANING
//    1         1 channel of input (intensity/alpha)
//    2         2 channels of input (luminance, alpha)
//    3         3 channels of input (RGB)
//    4         4 channels of input (RGBA)
//    l         1 channel of input (luminance)
//    a         1 channel of input (alpha)
//    la        2 channels of input (lum/alpha)
//    rgb       3 channels of input (RGB)
//    ycocg     3 channels of input (YCoCg - forces YCoCg output)
//    ycocgj    4 channels of input (YCoCgJunk - forces YCoCg output)
//    rgba      4 channels of input (RGBA)
//    
// output descriptor: AT MOST ONE
//   TEXT     MEANING
//    A         1 channel of output (alpha)
//    I         1 channel of output (intensity)
//    LA        2 channels of output (lum/alpha)
//    RGB       3 channels of output (RGB)
//    RGBA      4 channels of output (RGBA)
//    DXT1      encode as a DXT1 texture (RGB unless input has RGBA)
//    DXT3      encode as a DXT3 texture
//    DXT5      encode as a DXT5 texture
//    YCoCg     encode as a DXT5 texture with Y in alpha, CoCg in RG
//    NONE      no input/output, don't call TexImage2D at all
//
// when reading from a file or using another interface with an explicit
// channel count, the input descriptor is ignored and instead the channel
// count is used as the input descriptor. if the file read is a DXT DDS,
// then it is passed directly to OpenGL in the file format.
//
// if an input descriptor is supplied but no output descriptor, the output
// is assumed to be the same as the input. if an output descriptor is supplied
// but no input descriptor, the input is assumed to be the same as the
// output. if neither is supplied, the input is assumed to be 4-channel.
// If DXT1 or YCoCG output is requested with no input, the input is assumed
// to be 4-channel but the alpha channel is ignored.
//
// filtering descriptor (default is no mipmaps)
//   TEXT     MEANING
//    m         generate mipmaps
//    M         mipmaps are provided, concatenated at end of data (from largest to smallest)
//    t         use trilinear filtering (default if mipmapped)
//    b         use bilinear filtering (default if not-mipmapped)
//    n         use nearest-neighbor sampling
//
// wrapping descriptor
//   TEXT     MEANING
//    w         wrap (default)
//    c         clamp-to-edge
//    C         GL_CLAMP (uses border color)
//
// If only one wrapping descriptor is supplied, it is applied to both channels.
//
// special:
//   TEXT     MEANING
//    f         input data is floats (default unsigned bytes)
//    F         input&output data is floats (default unsigned bytes)
//    p         explicitly pre-multiply the alpha
//    +         can overwrite the texture data with temp data
//
// the properties string can also include spaces

#ifdef STB_DEFINE

int stbgl_hasExtension(char *ext)
{
   const char *s = (const char *)glGetString(GL_EXTENSIONS);
   for(;;) {
      char *e = ext;
      for (;;) {
         if (*e == 0) {
            if (*s == 0 || *s == ' ') return 1;
            break;
         }
         if (*s != *e)
            break;
         ++s, ++e;
      }
      while (*s && *s != ' ') ++s;
      if (!*s) return 0;
      ++s; // skip space
   }
}

static int stbgl_m(char *a, char *b)
{
   // skip first character
   do { ++a,++b; } while (*b && *a == *b);
   return *b == 0;
}

int stbgl_LoadTexture(char *filename, char *props)
{
   // @TODO: handle DDS files directly
   int res;
   void *data;
   int w,h,c;
   #ifndef STBI_NO_HDR
   if (stbi_is_hdr(filename)) {
      data = stbi_loadf(filename, &w, &h, &c, 0);
      if (!data) return 0;
      res = stbgl_TexImage2D_Extra(0, w,h,data, -c, props, 0);
      free(data);
      return res;
   }
   #endif

   data = stbi_load(filename, &w, &h, &c, 0);
   if (!data) return 0;
   res = stbgl_TexImage2D_Extra(0, w,h,data, c, props, 0);
   free(data);
   return res;
}

int stbgl_TexImage2D(int texid, int w, int h, void *data, char *props)
{
   return stbgl_TexImage2D_Extra(texid, w, h, data, 0, props,1);
}

// use the reserved temporary-use enumerant range, since no
// OpenGL enumerants should fall in that range
enum
{
   STBGL_UNDEFINED = 0x6000,
   STBGL_YCOCG,
   STBGL_YCOCGJ,
   STBGL_GEN_MIPMAPS,
   STBGL_MIPMAPS,
   STBGL_NO_DOWNLOAD,
};

#define STBGL_COMPRESSED_RGB_S3TC_DXT1    0x83F0
#define STBGL_COMPRESSED_RGBA_S3TC_DXT1   0x83F1
#define STBGL_COMPRESSED_RGBA_S3TC_DXT3   0x83F2
#define STBGL_COMPRESSED_RGBA_S3TC_DXT5   0x83F3

#define STBGL_CLAMP_TO_EDGE               0x812F

int stbgl_TexImage2D_Extra(int texid, int w, int h, void *data, int chan, char *props, int preserve_data)
{
   static int has_s3tc = -1; // haven't checked yet
   int free_data = 0;
   int premultiply_alpha = 0; // @TODO
   int float_tex   = 0; // @TODO
   int input_type  = GL_UNSIGNED_BYTE;
   int input_desc  = STBGL_UNDEFINED;
   int output_desc = STBGL_UNDEFINED;
   int mipmaps     = STBGL_UNDEFINED;
   int filter      = STBGL_UNDEFINED, mag_filter;
   int wrap_s = STBGL_UNDEFINED, wrap_t = STBGL_UNDEFINED;

   // parse out the properties
   if (props == NULL) props = "";
   while (*props) {
      switch (*props) {
         case '1' :  input_desc = GL_LUMINANCE; break;
         case '2' :  input_desc = GL_LUMINANCE_ALPHA; break;
         case '3' :  input_desc = GL_RGB; break;
         case '4' :  input_desc = GL_RGBA; break;
         case 'l' :  if (props[1] == 'a') { input_desc = GL_LUMINANCE_ALPHA; ++props; }
                     else input_desc = GL_LUMINANCE;
                     break;
         case 'a' :  input_desc = GL_ALPHA; break;
         case 'r' :  if (stbgl_m(props, "rgba")) { input_desc = GL_RGBA; props += 3; break; }
                     if (stbgl_m(props, "rgb")) { input_desc = GL_RGB; props += 2; break; }
                     input_desc = GL_RED;
                     break;
         case 'y' :  if (stbgl_m(props, "ycocg")) {
                        if (props[5] == 'j') { props += 5; input_desc = STBGL_YCOCGJ; }
                        else { props += 4; input_desc = STBGL_YCOCG; }
                        break;
                     }
                     return 0;
         case 'L' :  if (props[1] == 'A') { output_desc = GL_LUMINANCE_ALPHA; ++props; }
                     else output_desc = GL_LUMINANCE;
                     break;
         case 'I' :  output_desc = GL_INTENSITY; break;
         case 'A' :  output_desc = GL_ALPHA; break;
         case 'R' :  if (stbgl_m(props, "RGBA")) { output_desc = GL_RGBA; props += 3; break; }
                     if (stbgl_m(props, "RGB")) { output_desc = GL_RGB; props += 2; break; }
                     output_desc = GL_RED;
                     break;
         case 'Y' :  if (stbgl_m(props, "YCoCg") || stbgl_m(props, "YCOCG")) {
                        props += 4;
                        output_desc = STBGL_YCOCG;
                        break;
                     }
                     return 0;
         case 'D' :  if (stbgl_m(props, "DXT")) {
                        switch (props[3]) {
                           case '1': output_desc = STBGL_COMPRESSED_RGB_S3TC_DXT1; break;
                           case '3': output_desc = STBGL_COMPRESSED_RGBA_S3TC_DXT3; break;
                           case '5': output_desc = STBGL_COMPRESSED_RGBA_S3TC_DXT5; break;
                           default: return 0;
                        }
                        props += 3;
                        break;
                     }
                     return 0;
         case 'N' :  if (stbgl_m(props, "NONE")) {
                        props += 3;
                        input_desc = STBGL_NO_DOWNLOAD;
                        output_desc = STBGL_NO_DOWNLOAD;
                        break;
                     }
                     return 0;
         case 'm' :  mipmaps = STBGL_GEN_MIPMAPS; break;
         case 'M' :  mipmaps = STBGL_MIPMAPS; break;
         case 't' :  filter = GL_LINEAR_MIPMAP_LINEAR; break;
         case 'b' :  filter = GL_LINEAR; break;
         case 'n' :  filter = GL_NEAREST; break;
         case 'w' :  if (wrap_s == STBGL_UNDEFINED) wrap_s = GL_REPEAT; else wrap_t = GL_REPEAT; break;
         case 'C' :  if (wrap_s == STBGL_UNDEFINED) wrap_s = GL_CLAMP ; else wrap_t = GL_CLAMP ; break;
         case 'c' :  if (wrap_s == STBGL_UNDEFINED) wrap_s = STBGL_CLAMP_TO_EDGE; else wrap_t = STBGL_CLAMP_TO_EDGE; break;
         case 'f' :  input_type = GL_FLOAT; break;
         case 'F' :  input_type = GL_FLOAT; float_tex = 1; break;
         case 'p' :  premultiply_alpha = 1; break;
         case '+' :  preserve_data = 0; break;
         case ' ' :  break;
         case '-' :  break;
         default  :  return 0;
      }
      ++props;
   }
   
   // override input_desc based on channel count
   if (output_desc != STBGL_NO_DOWNLOAD) {
      switch (abs(chan)) {
         case 1: input_desc = GL_LUMINANCE; break;
         case 2: input_desc = GL_LUMINANCE_ALPHA; break;
         case 3: input_desc = GL_RGB; break;
         case 4: input_desc = GL_RGBA; break;
         case 0: break;
         default: return 0;
      }
   }

   // override input_desc based on channel info
   if (chan > 0) { input_type = GL_UNSIGNED_BYTE; }
   if (chan < 0) { input_type = GL_FLOAT; }

   if (output_desc == GL_ALPHA) {
      if (input_desc == GL_LUMINANCE)
         input_desc = GL_ALPHA;
      if (input_desc == GL_RGB) {
         // force a presumably-mono image to alpha
         // @TODO handle 'preserve_data' case?
         if (data && !preserve_data && input_type == GL_UNSIGNED_BYTE) {
            int i;
            unsigned char *p = (unsigned char *) data, *q = p;
            for (i=0; i < w*h; ++i) {
               *q = (p[0] + 2*p[1] + p[2]) >> 2;
               p += 3;
               q += 1;
            }
            input_desc = GL_ALPHA;
         }
      }
   }

   // set undefined input/output based on the other
   if (input_desc == STBGL_UNDEFINED && output_desc == STBGL_UNDEFINED) {
      input_desc = output_desc = GL_RGBA;
   } else if (output_desc == STBGL_UNDEFINED) {
      switch (input_desc) {
         case GL_LUMINANCE:
         case GL_ALPHA:
         case GL_LUMINANCE_ALPHA:
         case GL_RGB:
         case GL_RGBA:
            output_desc = input_desc;
            break;
         case GL_RED:
            output_desc = GL_INTENSITY;
            break;
         case STBGL_YCOCG:
         case STBGL_YCOCGJ:
            output_desc = STBGL_YCOCG;
            break;
         default: assert(0); return 0;
      }
   } else if (input_desc == STBGL_UNDEFINED) {
      switch (output_desc) {
         case GL_LUMINANCE:
         case GL_ALPHA:
         case GL_LUMINANCE_ALPHA:
         case GL_RGB:
         case GL_RGBA:
            input_desc = output_desc;
            break;
         case GL_INTENSITY:
            input_desc = GL_RED;
            break;
         case STBGL_YCOCG:
         case STBGL_COMPRESSED_RGB_S3TC_DXT1:
         case STBGL_COMPRESSED_RGBA_S3TC_DXT3:
         case STBGL_COMPRESSED_RGBA_S3TC_DXT5:
            input_desc = GL_RGBA;
            break;
      }
   } else {
      if (output_desc == STBGL_COMPRESSED_RGB_S3TC_DXT1) {
         // if input has alpha, force output alpha
         switch (input_desc) {
            case GL_ALPHA:
            case GL_LUMINANCE_ALPHA:
            case GL_RGBA:
               output_desc = STBGL_COMPRESSED_RGBA_S3TC_DXT1;
               break;
         }
      }
   }

   switch (output_desc) {
      case STBGL_COMPRESSED_RGB_S3TC_DXT1:
      case STBGL_COMPRESSED_RGBA_S3TC_DXT1:
      case STBGL_COMPRESSED_RGBA_S3TC_DXT3:
      case STBGL_COMPRESSED_RGBA_S3TC_DXT5:
         if (has_s3tc == -1) has_s3tc = stbgl_hasExtension("GL_EXT_texture_compression_s3tc");
         if (!has_s3tc) {
            if (output_desc == STBGL_COMPRESSED_RGB_S3TC_DXT1)
               output_desc = GL_RGB;
            else
               output_desc = GL_RGBA;
         }
   }

   if (output_desc == STBGL_YCOCG) {
      assert(0);
      output_desc = GL_RGB; // @TODO!
   }

   // update filtering
   if (filter == GL_NEAREST)
      mag_filter = GL_NEAREST;
   else
      mag_filter = GL_LINEAR;

   if (mipmaps != STBGL_UNDEFINED) {
      switch (filter) {
         case STBGL_UNDEFINED: filter = GL_LINEAR_MIPMAP_LINEAR; break;
         case GL_NEAREST     : filter = GL_NEAREST_MIPMAP_NEAREST; break;
         case GL_LINEAR      : filter = GL_LINEAR_MIPMAP_NEAREST; break;
      }
   } else {
      if (filter == STBGL_UNDEFINED)
         filter = GL_LINEAR;
   }

   // update wrap/clamp
   if (wrap_s == STBGL_UNDEFINED) wrap_s = GL_REPEAT;
   if (wrap_t == STBGL_UNDEFINED) wrap_t = wrap_s;

   // if no texture id, generate one
   if (texid == 0) {
      GLuint tex;
      glGenTextures(1, &tex);
      if (tex == 0) return 0;
      texid = tex;
   }

   if (data == NULL && mipmaps == STBGL_GEN_MIPMAPS)
      mipmaps = STBGL_MIPMAPS;

   if (output_desc == STBGL_NO_DOWNLOAD)
      mipmaps = STBGL_NO_DOWNLOAD;

   glBindTexture(GL_TEXTURE_2D, texid);

   switch (mipmaps) {
      case STBGL_NO_DOWNLOAD:
         break;

      case STBGL_UNDEFINED:
         // check if actually power-of-two
         if ((w & (w-1)) == 0 && (h & (h-1)) == 0)
            glTexImage2D(GL_TEXTURE_2D, 0, output_desc, w, h, 0, input_desc, input_type, data);
         else
            gluBuild2DMipmaps(GL_TEXTURE_2D, output_desc, w, h, input_desc, input_type, data);
            // not power of two, so use glu to resize (generates mipmaps needlessly)
         break;

      case STBGL_MIPMAPS: {
         int level = 0;
         int size = input_type == GL_FLOAT ? sizeof(float) : 1;
         if (data == NULL) size = 0; // reuse same block of memory for all mipmaps
         assert((w & (w-1)) == 0 && (h & (h-1)) == 0); // verify power-of-two
         while (w > 1 && h > 1) {
            glTexImage2D(GL_TEXTURE_2D, level, output_desc, w, h, 0, input_desc, input_type, data);
            data = (void *) ((char *) data + w * h * size);
            if (w > 1) w >>= 1;
            if (h > 1) h >>= 1;
            ++level;
         }
         break;
      }
      case STBGL_GEN_MIPMAPS:
         gluBuild2DMipmaps(GL_TEXTURE_2D, output_desc, w, h, input_desc, input_type, data);
         break;

      default:
         assert(0);
         if (free_data) free(data);
         return 0;
   }

   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_s);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_t);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag_filter);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);

   if (free_data) free(data);
   return texid;
}

#endif // STB_DEFINE

#endif //INCLUDE_STB_GL_H
