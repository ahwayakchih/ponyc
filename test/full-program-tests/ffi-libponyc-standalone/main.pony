use "lib:ponyc-standalone"
use "lib:z" if not windows
use "lib:c++" if osx
use "lib:LLVM" if osllvm
use "lib:clang" if osllvm
use "lib:clang-cpp" if osllvm
use "lib:lldCommon" if osllvm
use "lib:lldWasm" if osllvm
use "lib:lldMachO" if osllvm
use "lib:lldMinGW" if osllvm
use "lib:lldELF" if osllvm
use "lib:lldCOFF" if osllvm

use @token_new[NullablePointer[TokenStub]](token_id: TokenId)
use @ast_new[NullablePointer[AstStub]](token: TokenStub, token_id: TokenId)
use @token_free[None](token: TokenStub)
use @ast_free[None](ast: AstStub)
use @ast_id[TokenId](ast: AstStub)

struct AstStub
struct TokenStub

type TokenId is I32

actor Main
  new create(env: Env) =>
    try
      let token = @token_new(2)()?
      let ast = @ast_new(token, 2)()?
      if @ast_id(ast) != 2 then
        env.exitcode(1)
      end
      @ast_free(ast)
      @token_free(token)
    else
      env.exitcode(1)
    end
