#include "llvm/Config/llvm-config.h"

#include "llvm-c/Core.h"
#include "llvm-c/DebugInfo.h"
#include "llvm-c/TargetMachine.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/LegacyPassManager.h"

#include "llvm/Passes/PassBuilder.h"

#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"

#include "llvm/Frontend/Driver/CodeGenOptions.h"

#include "llvm/TargetParser/Host.h"
#include "llvm/TargetParser/SubtargetFeature.h"

#include "llvm/Target/TargetMachine.h"

#include "llvm/MC/TargetRegistry.h"

#include "llvm/Support/FileSystem.h"

#include "lld/Common/CommonLinkerContext.h"

#define EXPORT extern "C"
#define fn static

EXPORT void llvm_subprogram_replace_type(LLVMMetadataRef subprogram, LLVMMetadataRef subroutine_type)
{
    auto sp = llvm::unwrap<llvm::DISubprogram>(subprogram);
    sp->replaceType(llvm::unwrap<llvm::DISubroutineType>(subroutine_type));
}

// If there are multiple uses of the return-value slot, just check
// for something immediately preceding the IP.  Sometimes this can
// happen with how we generate implicit-returns; it can also happen
// with noreturn cleanups.
fn llvm::StoreInst* get_store_if_valid(llvm::User* user, llvm::Value* return_alloca, llvm::Type* element_type)
{
    auto *SI = dyn_cast<llvm::StoreInst>(user);
    if (!SI || SI->getPointerOperand() != return_alloca ||
        SI->getValueOperand()->getType() != element_type)
      return nullptr;
    // These aren't actually possible for non-coerced returns, and we
    // only care about non-coerced returns on this code path.
    // All memory instructions inside __try block are volatile.
    assert(!SI->isAtomic() &&
           (!SI->isVolatile()
            //|| CGF.currentFunctionUsesSEHTry())
          ));
    return SI;
}

// copy of static llvm::StoreInst *findDominatingStoreToReturnValue(CodeGenFunction &CGF) {
// in clang/lib/CodeGen/CGCall.cpp:3526 in LLVM 19
EXPORT LLVMValueRef llvm_find_return_value_dominating_store(LLVMBuilderRef b, LLVMValueRef ra, LLVMTypeRef et)
{
    auto builder = llvm::unwrap(b);
    auto return_alloca = llvm::unwrap(ra);
    auto element_type = llvm::unwrap(et);
    // Check if a User is a store which pointerOperand is the ReturnValue.
    // We are looking for stores to the ReturnValue, not for stores of the
    // ReturnValue to some other location.
    if (!return_alloca->hasOneUse()) {
        llvm::BasicBlock *IP = builder->GetInsertBlock();
        if (IP->empty()) return nullptr;

        // Look at directly preceding instruction, skipping bitcasts and lifetime
        // markers.
        for (llvm::Instruction &I : make_range(IP->rbegin(), IP->rend())) {
            if (isa<llvm::BitCastInst>(&I))
                continue;
            if (auto *II = dyn_cast<llvm::IntrinsicInst>(&I))
                if (II->getIntrinsicID() == llvm::Intrinsic::lifetime_end)
                    continue;

            return wrap(get_store_if_valid(&I, return_alloca, element_type));
        }
        return nullptr;
    }

    llvm::StoreInst *store = get_store_if_valid(return_alloca->user_back(), return_alloca, element_type);
    if (!store) return nullptr;

    // Now do a first-and-dirty dominance check: just walk up the
    // single-predecessors chain from the current insertion point.
    llvm::BasicBlock *StoreBB = store->getParent();
    llvm::BasicBlock *IP = builder->GetInsertBlock();
    llvm::SmallPtrSet<llvm::BasicBlock *, 4> SeenBBs;
    while (IP != StoreBB) {
        if (!SeenBBs.insert(IP).second || !(IP = IP->getSinglePredecessor()))
            return nullptr;
    }

    // Okay, the store's basic block dominates the insertion point; we
    // can do our thing.
    return wrap(store);
}

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

#define lld_api_args() char* const* argument_pointer, u64 argument_count, bool exit_early, bool disable_output
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
        auto* stdout_pointer = new u8[stdout_length + 1];
        memcpy(stdout_pointer, stdout_string.data(), stdout_length);
        result.stdout_string = { stdout_pointer, stdout_length };
        stdout_pointer[stdout_length] = 0;
    }

    auto stderr_length = stderr_string.length();
    if (stderr_length)
    {
        auto* stderr_pointer = new u8[stderr_length + 1];
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
    return lld_api_generic(argument_pointer, argument_count, exit_early, disable_output, lld::link_name::link);\
}

lld_api_function_impl(coff)
lld_api_function_impl(elf)
lld_api_function_impl(mingw)
lld_api_function_impl(macho)
lld_api_function_impl(wasm)
