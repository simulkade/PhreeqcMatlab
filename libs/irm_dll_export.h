/* irm_dll_export.h — PhreeqcMatlab (loadlibrary-friendly variant)
 *
 * The upstream PhreeqcRM 3.8.6 header defines IRM_DLL_EXPORT as
 *   __attribute__ ((visibility ("default")))
 * on GCC. MATLAB's loadlibrary compiles a thunk with gcc (so __GNUC__ is
 * defined) and its parser cannot handle that attribute in front of every
 * prototype — it aborts thunk generation with "expected declaration
 * specifiers ... before string constant".
 *
 * The visibility attribute only affects symbol export when *building* the
 * shared library; the prebuilt libphreeqcrm.so already exports every symbol,
 * and loadlibrary/calllib never recompile it. So we define IRM_DLL_EXPORT as
 * empty here (matching how the 3.7.x header behaved on Linux). This header is
 * shipped only for loadlibrary's header parse — do not use it to build the
 * native library.
 */
#ifndef IRM_DLL_EXPORT
# if defined(_WIN32) && defined(DLL_EXPORT)
#  define IRM_DLL_EXPORT __declspec(dllexport)
# else
#  define IRM_DLL_EXPORT
# endif
#endif
