# clangInstrumentation

参考：http://clang.llvm.org/docs/SanitizerCoverage.html

clang插桩代码，为了减少page fault，所以需要在app启动时，将symbol尽量放在前几个page
