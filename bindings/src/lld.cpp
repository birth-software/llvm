#include <lld_bindings.h>

#include "lld/Common/CommonLinkerContext.h"

#ifndef BB_EXPORT
#define BB_EXPORT extern "C"
#endif
#define fn static

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

    static_assert(sizeof(char) == sizeof(u8));
    static_assert(alignof(char) == alignof(u8));

    auto stdout_length = stdout_string.length();
    if (stdout_length)
    {
        auto* stdout_pointer = allocate_fn(context, stdout_length + 1, 1);
        memcpy(stdout_pointer, stdout_string.data(), stdout_length);
        result.stdout_string.pointer = (char*)stdout_pointer;
        result.stdout_string.length = stdout_length;
        stdout_pointer[stdout_length] = 0;
    }

    auto stderr_length = stderr_string.length();
    if (stderr_length)
    {
        auto* stderr_pointer = allocate_fn(context, stderr_length + 1, 1);
        memcpy(stderr_pointer, stderr_string.data(), stderr_length);
        result.stderr_string.pointer = (char*)stderr_pointer;
        result.stderr_string.length = stderr_length;
        stderr_pointer[stderr_length] = 0;
    }

    // TODO: should we only call it on success?
    lld::CommonLinkerContext::destroy();

    return result;
}

#define lld_api_function_impl(link_name) \
BB_EXPORT lld_api_function_decl(link_name)\
{\
    return lld_api_generic(argument_pointer, argument_count, exit_early, disable_output, allocate_fn, context, lld::link_name::link);\
}

lld_api_function_impl(coff)
lld_api_function_impl(elf)
lld_api_function_impl(mingw)
lld_api_function_impl(macho)
lld_api_function_impl(wasm)
