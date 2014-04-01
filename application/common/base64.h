#include <string>

typedef struct {
    std::string str;
    size_t size;
} base64_result;

std::string base64_encode(unsigned char const* , unsigned int len);
base64_result base64_decode(std::string const& s);