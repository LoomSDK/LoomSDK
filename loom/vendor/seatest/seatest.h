#ifndef SEATEST_H
#define SEATEST_H

#include "loom/common/core/performance.h"

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

/*
Defines
*/

#define SEATEST_VERSION "0.5"
#define SEATEST_PROJECT_HOME "http://code.google.com/p/seatest/"
#define SEATEST_PRINT_BUFFER_SIZE 100000

/*
Typedefs
*/

typedef void (*seatest_void_void)(void);
typedef void (*seatest_void_string)(char*);
typedef int  (*seatest_int_string_varargs) (const char *str, ...);

/*
Declarations
*/
extern void (*seatest_simple_test_result)(int passed, const char* reason, const char* function, unsigned int line);
void seatest_test_fixture_start(const char* filepath);
void seatest_test_fixture_end( void );
void seatest_simple_test_result_log(int passed, const char* reason, const char* function, unsigned int line);
void seatest_assert_true(int test, const char* function, unsigned int line);
void seatest_assert_false(int test, const char* function, unsigned int line);
void seatest_assert_int_equal(int expected, int actual, const char* function, unsigned int line);
void seatest_assert_ulong_equal(unsigned long expected, unsigned long actual, const char* function, unsigned int line);
void seatest_assert_float_equal(float expected, float actual, float delta, const char* function, unsigned int line);
void seatest_assert_double_equal(double expected, double actual, double delta, const char* function, unsigned int line);
void seatest_assert_string_equal(const char* expected, const char* actual, const char* function, unsigned int line);
void seatest_assert_string_ends_with(const char* expected, const char* actual, const char* function, unsigned int line);
void seatest_assert_string_starts_with(const char* expected, const char* actual, const char* function, unsigned int line);
void seatest_assert_string_contains(const char* expected, const char* actual, const char* function, unsigned int line);
void seatest_assert_string_doesnt_contain(const char* expected, const char* actual, const char* function, unsigned int line);
int  seatest_should_run( const char* fixture, const char* test);
void seatest_before_run( const char* fixture, const char* test);
void seatest_run_test(const char* fixture, const char* test);
void seatest_setup( void );
void seatest_teardown( void );
void seatest_suite_teardown( void );
void seatest_suite_setup( void );
void seatest_set_print_callback(seatest_int_string_varargs printer);
   
/*
Assert Macros
*/

#define assert_true(test) do { seatest_assert_true(test, __FUNCTION__, __LINE__); } while (0)
#define assert_false(test) do {  seatest_assert_false(test, __FUNCTION__, __LINE__); } while (0)
#define assert_int_equal(expected, actual) do {  seatest_assert_int_equal(expected, actual, __FUNCTION__, __LINE__); } while (0)
#define assert_ulong_equal(expected, actual) do {  seatest_assert_ulong_equal(expected, actual, __FUNCTION__, __LINE__); } while (0)
#define assert_string_equal(expected, actual) do {  seatest_assert_string_equal(expected, actual, __FUNCTION__, __LINE__); } while (0)
#define assert_n_array_equal(expected, actual, n) do { int seatest_count; for(seatest_count=0; seatest_count<n; seatest_count++) { char s_seatest[SEATEST_PRINT_BUFFER_SIZE]; sprintf(s_seatest,"Expected %d to be %d at position %d", actual[seatest_count], expected[seatest_count], seatest_count); seatest_simple_test_result((expected[seatest_count] == actual[seatest_count]), s_seatest, __FUNCTION__, __LINE__);} } while (0)
#define assert_bit_set(bit_number, value) { seatest_simple_test_result(((1 << bit_number) & value), " Expected bit to be set" ,  __FUNCTION__, __LINE__); } while (0)
#define assert_bit_not_set(bit_number, value) { seatest_simple_test_result(!((1 << bit_number) & value), " Expected bit not to to be set" ,  __FUNCTION__, __LINE__); } while (0)
#define assert_bit_mask_matches(value, mask) { seatest_simple_test_result(((value & mask) == mask), " Expected all bits of mask to be set" ,  __FUNCTION__, __LINE__); } while (0)
#define assert_fail(message) { seatest_simple_test_result(0, message,  __FUNCTION__, __LINE__); } while (0)
#define assert_float_equal(expected, actual, delta) do {  seatest_assert_float_equal(expected, actual, delta, __FUNCTION__, __LINE__); } while (0)
#define assert_double_equal(expected, actual, delta) do {  seatest_assert_double_equal(expected, actual, delta, __FUNCTION__, __LINE__); } while (0)
#define assert_string_contains(expected, actual) do {  seatest_assert_string_contains(expected, actual, __FUNCTION__, __LINE__); } while (0)
#define assert_string_doesnt_contain(expected, actual) do {  seatest_assert_string_doesnt_contain(expected, actual, __FUNCTION__, __LINE__); } while (0)
#define assert_string_starts_with(expected, actual) do {  seatest_assert_string_starts_with(expected, actual, __FUNCTION__, __LINE__); } while (0)
#define assert_string_ends_with(expected, actual) do {  seatest_assert_string_ends_with(expected, actual, __FUNCTION__, __LINE__); } while (0)

/*
Fixture / Test Management
*/

void fixture_setup(void (*setup)( void ));
void fixture_teardown(void (*teardown)( void ));
#define run_test(test) do { if(seatest_should_run(__FILE__,  #test)) {seatest_suite_setup(); seatest_setup(); test(); seatest_teardown(); seatest_suite_teardown(); seatest_run_test(__FILE__, #test);  }} while (0)
#define test_fixture_start() do { seatest_test_fixture_start(__FILE__); } while (0)
#define test_fixture_end() do { seatest_test_fixture_end();} while (0)
void fixture_filter(char* filter);
void test_filter(char* filter);
void suite_teardown(seatest_void_void teardown);
void suite_setup(seatest_void_void setup);
int run_tests(seatest_void_void tests);
int seatest_testrunner(int argc, char** argv, seatest_void_void tests, seatest_void_void setup, seatest_void_void teardown);
#endif

#ifdef SEATEST_INTERNAL_TESTS 
void seatest_simple_test_result_nolog(int passed, char* reason, const char* function, unsigned int line);
void seatest_assert_last_passed();
void seatest_assert_last_failed();
void seatest_enable_logging();
void seatest_disable_logging();
#endif

/** Totally sweet macros, added by BJG **/
#define SEATEST_TEST(testName) \
   void __cdecl test_impl_##testName(void)

#define SEATEST_FIXTURE(fixtureName) \
   static void __cdecl test_fixture_inner_##fixtureName(); \
   void __cdecl test_fixture_##fixtureName(void) { \
      test_fixture_start(); tmEnter(gTelemetryContext, TMZF_NONE, (const char *)#fixtureName); \
      test_fixture_inner_##fixtureName(); \
      tmLeave(gTelemetryContext); test_fixture_end(); }; \
   static void __cdecl test_fixture_inner_##fixtureName()

#define SEATEST_FIXTURE_ENTRY(testName) \
   tmEnter(gTelemetryContext, TMZF_NONE, (const char *)#testName); \
   void __cdecl test_impl_##testName(void); \
   run_test(test_impl_##testName); \
   tmLeave(gTelemetryContext); \
   performance_tick();

#define SEATEST_SUITE(suiteName) void __cdecl test_suite_##suiteName()
#define SEATEST_SUITE_ENTRY(fixtureName) extern void __cdecl test_fixture_##fixtureName(); test_fixture_##fixtureName()
    
#ifdef __cplusplus
};
#endif