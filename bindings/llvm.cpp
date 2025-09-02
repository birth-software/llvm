#include "lld/Common/CommonLinkerContext.h"

#define EXPORT extern "C"
#define fn static

typedef uint8_t u8;
typedef uint64_t u64;
struct String
{
    u8* pointer;
    u64 length;
};

struct LLDResult
{
    String stdout_string;
    String stderr_string;
    bool success;
};

using AllocationFn = u8* (void* context, u64 size, u64 alignment);

#define lld_api_args() char* const* argument_pointer, u64 argument_count, bool exit_early, bool disable_output, AllocationFn* allocate_fn, void* context
#define lld_api_function_decl(link_name) LLDResult lld_ ## link_name ## _link(lld_api_args())

extern "C" lld_api_function_decl(coff);
extern "C" lld_api_function_decl(elf);
extern "C" lld_api_function_decl(mingw);
extern "C" lld_api_function_decl(macho);
extern "C" lld_api_function_decl(wasm);

#define lld_api_function_signature(name) bool name(llvm::ArrayRef<const char *> args, llvm::raw_ostream &stdoutOS, llvm::raw_ostream &stderrOS, bool exitEarly, bool disableOutput)

#define lld_link_decl(link_name) \
namespace link_name \
{\
    lld_api_function_signature(link);\
}

typedef lld_api_function_signature(LinkerFunction);

namespace lld
{
    lld_link_decl(coff);
    lld_link_decl(elf);
    lld_link_decl(mingw);
    lld_link_decl(macho);
    lld_link_decl(wasm);
}

fn LLDResult lld_api_generic(lld_api_args(), LinkerFunction linker_function)
{
    LLDResult result = {};
    auto arguments = llvm::ArrayRef(argument_pointer, argument_count);

    std::string stdout_string;
    llvm::raw_string_ostream stdout_stream(stdout_string);

    std::string stderr_string;
    llvm::raw_string_ostream stderr_stream(stderr_string);

    result.success = linker_function(arguments, stdout_stream, stderr_stream, exit_early, disable_output);

    auto stdout_length = stdout_string.length();
    if (stdout_length)
    {
        auto* stdout_pointer = allocate_fn(context, stdout_length + 1, 1);
        memcpy(stdout_pointer, stdout_string.data(), stdout_length);
        result.stdout_string = { stdout_pointer, stdout_length };
        stdout_pointer[stdout_length] = 0;
    }

    auto stderr_length = stderr_string.length();
    if (stderr_length)
    {
        auto* stderr_pointer = allocate_fn(context, stderr_length + 1, 1);
        memcpy(stderr_pointer, stderr_string.data(), stderr_length);
        result.stderr_string = { stderr_pointer, stderr_length };
        stderr_pointer[stderr_length] = 0;
    }

    // TODO: should we only call it on success?
    lld::CommonLinkerContext::destroy();

    return result;
}

#define lld_api_function_impl(link_name) \
EXPORT lld_api_function_decl(link_name)\
{\
    return lld_api_generic(argument_pointer, argument_count, exit_early, disable_output, allocate_fn, context, lld::link_name::link);\
}

lld_api_function_impl(coff)
lld_api_function_impl(elf)
lld_api_function_impl(mingw)
lld_api_function_impl(macho)
lld_api_function_impl(wasm)
