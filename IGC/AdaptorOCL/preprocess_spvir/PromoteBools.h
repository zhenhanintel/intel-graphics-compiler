/*========================== begin_copyright_notice ============================

Copyright (C) 2022 Intel Corporation

SPDX-License-Identifier: MIT

============================= end_copyright_notice ===========================*/

#pragma once

#include "common/LLVMWarningsPush.hpp"
#include "llvmWrapper/IR/Module.h"
#include <llvm/Pass.h>
#include <llvm/IR/InstVisitor.h>
#include <llvm/IR/IRBuilder.h>
#include "common/LLVMWarningsPop.hpp"

#include "Compiler/MetaDataUtilsWrapper.h"

#include <string>

namespace IGC
{
    class PromoteBools : public llvm::ModulePass, public llvm::InstVisitor<PromoteBools>
    {
    public:
        static char ID;

        PromoteBools();
        ~PromoteBools() {}

        virtual llvm::StringRef getPassName() const override
        {
            return "PromoteBools";
        }

        virtual bool runOnModule(llvm::Module& module) override;

        void visitAllocaInst(llvm::AllocaInst& alloca);
        void visitCallInst(llvm::CallInst& call);
        void visitLoadInst(llvm::LoadInst& load);
        void visitStoreInst(llvm::StoreInst& store);

    private:
        bool changed;

        llvm::Value* createZextIfNeeded(llvm::Value* argument, llvm::Instruction* insertBefore);
        void cleanUp(llvm::Module& module);

        // Checking if type needs promotion
        bool typeNeedsPromotion(llvm::Type* type, llvm::DenseSet<llvm::Type*> visitedTypes = {});

        // Promoting types
        llvm::DenseMap<llvm::Type*, llvm::Type*> promotedTypesCache;
        llvm::Type* getOrCreatePromotedType(llvm::Type* type);

        // Promoting values
        llvm::DenseMap<llvm::Value*, llvm::Value*> promotedValuesCache;
        llvm::Value* getOrCreatePromotedValue(llvm::Value* value);
        llvm::Function* promoteFunction(llvm::Function* function);
        llvm::GlobalVariable* promoteGlobalVariable(llvm::GlobalVariable* globalVariable);
        llvm::Constant* promoteConstant(llvm::Constant* constant);
        llvm::Value* promoteAlloca(llvm::AllocaInst* alloca);
        llvm::Value* promoteAddrSpaceCast(llvm::AddrSpaceCastInst* addrSpaceCast);
        llvm::Value* promoteBitCast(llvm::BitCastInst* bitcast);
    };
}
