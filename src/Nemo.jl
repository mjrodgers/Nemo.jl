@doc raw"""
  Nemo is a computer algebra package for the Julia programming language, maintained by William Hart, Tommy Hofmann, Claus Fieker and Fredrik Johansson with additional code by Oleksandr Motsak and other contributors.

 The Nemo code written in Julia is licensed under the BSD license and it makes use of GPL and LGPL C/C++ libraries such as Flint, Antic, GMP/MPIR, MPFR, Singular and Arb.
"""
module Nemo

import AbstractAlgebra

using Libdl

using Random
using Random: SamplerTrivial
import Random: rand!

using RandomExtensions: RandomExtensions, make, Make2, Make3

using Pkg

import SHA

import AbstractAlgebra: div, divrem

# N.B: do not import div, divrem from Base
import Base: Array, abs, abs2, acos, acosh, asin, asinh, atan, atanh, bin, binomial,
             ceil, checkbounds, conj, convert, cmp, contains, cos, cosh, cospi, cot,
             coth, dec, deepcopy, deepcopy_internal, denominator,
             expm1, exp, factorial, floor, gcd, gcdx, getindex, hash, hcat,
             hex, hypot, in, intersect, inv, invmod, isequal, iseven, isinf, isfinite,
             isinteger, isless, isodd, isone, isqrt, isreal, iszero, lcm,
             ldexp, length, log, log1p, maximum, minimum, mod, ndigits, numerator, oct, one,
             parent, parse, powermod,
             precision, rand, Rational, rem, reverse, round, setindex!,
             show, similar, sign, sin, sincos, sincospi, sinh, sinpi, size, sqrt, string,
             tan, tanh, trailing_zeros, transpose, trunc, truncate, typed_hvcat,
             typed_hcat, vcat, xor, zero, zeros, +, -, *, ==, ^, &, |, <<, >>,
             ~, <=, >=, <, >, //, /, \, !=

if isdefined(Base, :tanpi) # added in julia >= 1.10-DEV
  import Base: tanpi
end

import LinearAlgebra: det, norm, nullspace, rank, transpose!, hessenberg, tr,
                      lu, lu!, eigvals, cholesky

import AbstractAlgebra: nullspace, @show_name, @show_special, find_name,
                        get_attribute, set_attribute!, @attributes,
                        get_cached!,
                        @show_special_elem, force_coerce, force_op, expressify

# We don't want the QQ, ZZ, finite_field, number_field from AbstractAlgebra
# as they are for parents of Julia types or naive implementations
# We only import AbstractAlgebra, not export
# We do not want the AbstractAlgebra version of certain functions as the Base version
# is the only place user friendly versions are defined
# AbstractAlgebra/Nemo has its own promote_rule, distinct from Base
# Set, Module, Ring, Group and Field are too generic to pollute the users namespace with
for i in names(AbstractAlgebra)
   (i in AbstractAlgebra.import_exclude || !isdefined(AbstractAlgebra, i)) && continue
   i == :GF && continue
   i == :NumberField && continue
   @eval import AbstractAlgebra: $i
   @eval export $i
end

export GF

import AbstractAlgebra: Set, Module, Ring, Group, Field, promote_rule

import AbstractAlgebra: pretty, Lowercase, LowercaseOff, Indent, Dedent, ErrorConstrDimMismatch

export flint_cleanup, flint_set_num_threads

export PadicField, QadicField, NGFiniteField

export QQBar

# Things/constants which are also defined in AbstractAlgebra:
export ZZ, QQ, finite_field, number_field


###############################################################################
#
#   Set up environment / load libraries
#
###############################################################################

using Arb_jll
using Antic_jll
using Calcium_jll
using FLINT_jll

const pkgdir = realpath(joinpath(dirname(@__DIR__)))

const libflint = FLINT_jll.libflint

function flint_abort()
  error("Problem in the Flint-Subsystem")
end

# check whether we are using flint version >= 3.0 (or some recent enough dev version),
# which changed the layout of some structs
_ptr = Libdl.dlopen(libflint)
if Libdl.dlsym(_ptr, :_fmpz_mod_vec_set_fmpz_vec_threaded; throw_error = false) !== nothing
  const NEW_FLINT = true
	libantic = libflint
	libarb = libflint
	libcalcium = libflint
else
  const NEW_FLINT = false
end
Libdl.dlclose(_ptr)

################################################################################
#
#  Debugging tools for allocation tracking
#
################################################################################

active_mem = Dict{UInt, Tuple{Symbol, UInt, Any}}()

function trace_malloc(n::UInt)
  u = ccall(:jl_malloc, UInt, (UInt, ), n)
  global active_mem
  active_mem[u] = (:malloc, n, backtrace())
  return u
end

function trace_calloc(n::UInt, s::UInt)
  u = ccall(:jl_calloc, UInt, (UInt, UInt), n, s)
  global active_mem
  active_mem[u] = (:calloc, n*s, backtrace())
  return u
end

function trace_free(n::UInt)
  global active_mem
#  @assert haskey(active_mem, n)
  delete!(active_mem, n)
  ccall(:jl_free, Nothing, (UInt, ), n)
end

function trace_realloc(n::UInt, s::UInt)
  global active_mem
  p = ccall(:jl_realloc, UInt, (UInt, UInt), n, s)
#  @assert haskey(active_mem, n)
  delete!(active_mem, n)
  active_mem[p] = (:realloc, s, backtrace())
  return p
end

function trace_counted_malloc(n::UInt)
  global active_mem
  p = ccall(:jl_gc_counted_malloc, UInt, (UInt, ), n)
  active_mem[p] = (:counted_malloc, n, backtrace())
  return p
end

function trace_counted_realloc(n::UInt, m::UInt, o::UInt)
  global active_mem
  p = ccall(:jl_gc_counted_realloc_with_old_size, UInt, (UInt, UInt, UInt), n, m, o)
#  @assert n==0 || haskey(active_mem, n)
  delete!(active_mem, n)
  active_mem[p] = (:counted_realloc, o, backtrace())
  return p
end

function trace_counted_free(n::UInt, s::UInt)
  global active_mem
#  @assert haskey(active_mem, n)
  delete!(active_mem, n)
  ccall(:jl_gc_counted_free_with_size, Nothing, (UInt, UInt), n, s)
end

function show_active(l::UInt = UInt(0), frames::Int = 2)
  global active_mem
  for i = keys(active_mem)
    v = active_mem[i]
    if v[2] >= l
      n = min(frames, length(v[3]))
      Base.show_backtrace(stdout, v[3][1:n])
    end
  end
end

function trace_memory(b::Bool)
  if Sys.iswindows()
    return
  end
  if b
    ccall((:__gmp_set_memory_functions, :libgmp), Nothing,
       (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
       @cfunction(trace_counted_malloc, UInt, (UInt, )),
       @cfunction(trace_counted_realloc, UInt, (UInt, UInt, UInt)),
       @cfunction(trace_counted_free, Nothing, (UInt, UInt)))

    ccall((:__flint_set_memory_functions, libflint), Nothing,
       (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
       @cfunction(trace_malloc, UInt, (UInt, )),
       @cfunction(trace_calloc, UInt, (UInt, UInt)),
       @cfunction(trace_realloc, UInt, (UInt, UInt)),
       @cfunction(trace_free, Nothing, (UInt, )))
  else
    ccall((:__gmp_set_memory_functions, :libgmp), Nothing,
       (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
       cglobal(:jl_gc_counted_malloc),
       cglobal(:jl_gc_counted_realloc_with_old_size),
       cglobal(:jl_gc_counted_free_with_size))

    ccall((:__flint_set_memory_functions, libflint), Nothing,
       (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
       cglobal(:jl_malloc),
       cglobal(:jl_calloc),
       cglobal(:jl_realloc),
       cglobal(:jl_free))
  end
end

################################################################################
#
#  Initialization function
#
################################################################################

const __isthreaded = Ref(false)

function __init__()
   # In case libgmp picks up the wrong libgmp later on, we "unset" the jl_*
   # functions from the julia :libgmp.

   __isthreaded[] = get(ENV, "NEMO_THREADED", "") == "1"

   if __isthreaded[]
      ccall((:__gmp_set_memory_functions, :libgmp), Nothing,
            (Int, Int, Int), 0, 0, 0)
   end

   ccall((:flint_set_abort, libflint), Nothing,
         (Ptr{Nothing},), @cfunction(flint_abort, Nothing, ()))

   # Check if were loaded from another package
   # if VERSION < 1.7.*, only the "other" package will have the
   # _tryrequire_from_serialized in the backtrace.
   # if VERSION >= 1.8, also doing 'using Package' will have
   # _tryrequire_from_serialized the backtrace.
   #
   # To still distinguish both scenarios, notice that
   # 'using OtherPackage' will either have _tryrequire_from_serialized at least twice,
   # or one with four arguments (hence five as the function name is the first argument)
   # 'using Package' serialized will have a version with less arguments
   bt = Base.process_backtrace(Base.backtrace())
   filter!(sf -> sf[1].func === :_tryrequire_from_serialized, bt)
   isinteractive_manual =
      length(bt) == 0 || (length(bt) == 1 && length(only(bt)[1].linfo.specTypes.parameters) < 4)

   # Respect the -q and --banner flag
   allowbanner = Base.JLOptions().banner != 0

   if allowbanner && isinteractive_manual && isinteractive() &&
         !any(x -> x.name in ("Hecke", "Oscar", "Singular"), keys(Base.package_locks)) &&
         get(ENV, "NEMO_PRINT_BANNER", "true") != "false"

      println("")
      println("Welcome to Nemo version $(version())")
      println("")
      println("Nemo comes with absolutely no warranty whatsoever")
   end

  # Initialize the thread local random state
  resize!(_flint_rand_states, Threads.nthreads())
  for i in 1:Threads.nthreads()
     _flint_rand_states[i] = rand_ctx()
  end

  # Initialize the thread local ECM parameters
  Threads.resize_nthreads!(_ecm_B1s)
  Threads.resize_nthreads!(_ecm_nCs)
end

function flint_set_num_threads(a::Int)
   if !__isthreaded[]
     error("To use threaded flint, julia has to be started with NEMO_THREADED=1")
   else
     ccall((:flint_set_num_threads, libflint), Nothing, (Int,), a)
   end
end

function flint_cleanup()
   ccall((:flint_cleanup, libflint), Nothing, ())
end

###############################################################################
#
#  Version information
#
################################################################################

deps = Pkg.dependencies()
if !haskey(deps, Base.UUID("2edaba10-b0f1-5616-af89-8c11ac63239a"))
   version() = "building"
else
   ver = deps[Base.UUID("2edaba10-b0f1-5616-af89-8c11ac63239a")]
   if occursin("/dev/", ver.source)
      version() = VersionNumber("$(ver.version)-dev")
   else
      version() = VersionNumber("$(ver.version)")
   end
end

function versioninfo()
  print("Nemo version $(version())\n")
  nemorepo = dirname(dirname(@__FILE__))

  print("Nemo: ")
  prepo = Base.LibGit2.GitRepo(nemorepo)
  Base.LibGit2.with(LibGit2.head(prepo)) do phead
    print("commit: ")
    print(string(LibGit2.Oid(phead))[1:8])
    print(" date: ")
    commit = Base.LibGit2.get(Base.LibGit2.GitCommit, prepo, LibGit2.Oid(phead))
    print(Base.Dates.unix2datetime(Base.LibGit2.author(commit).time))
    print(")\n")
  end

  finalize(prepo)

  return nothing
end

macro new_struct(T, args...)
   return esc(Expr(:new, T, args...))
end

###############################################################################
#
#   Generic submodule
#
###############################################################################

export power_series_ring, polynomial_ring, SparsePolynomialRing, matrix_space,
       fraction_field, residue_ring, Partition, SymmetricGroup, YoungTableau,
       AllParts, SkewDiagram, AllPerms, Perm, laurent_series_ring,
       laurent_series_field, puiseux_series_ring, residue_field

export Generic

###############################################################################
#
#   Cache type
#
###############################################################################

const CacheDictType = AbstractAlgebra.WeakValueDict

###############################################################################
#
#   Load Nemo Rings/Fields/etc
#
###############################################################################

include("embedding/EmbeddingTypes.jl")

include("flint/FlintTypes.jl")

include("antic/AnticTypes.jl")

include("arb/ArbTypes.jl")

include("calcium/CalciumTypes.jl")

include("gaussiannumbers/GaussianNumberTypes.jl")

#include("ambiguities.jl") # remove ambiguity warnings

include("flint/adhoc.jl")

include("embedding/embedding.jl")

include("Rings.jl")

include("HeckeMiscFiniteField.jl")
include("HeckeMiscInfinity.jl")
include("HeckeMiscInteger.jl")
include("HeckeMiscMatrix.jl")
include("HeckeMiscPoly.jl")
include("HeckeMoreStuff.jl")

###############################################################################
#
#   satellite functionality
#
###############################################################################

include("gaussiannumbers/continued_fraction.jl")

###############################################################################
#
#  Random
#
################################################################################

"""
    randseed!([seed::Integer])

Reseed Nemo's global RNG with `seed`. Note that each thread has its own global RNG,
and that `randseed!` reseeds only the RNG from the current thread.
This is similar to what `Random.seed!(seed)` does for Julia's global RNG.

The given `seed` must be a non-negative integer.
When `seed` is not specified, a random seed is generated from Julia's global RNG.

For a fixed seed, the stream of generated numbers is allowed to change between
different versions of Nemo.
"""
randseed!(seed::Union{Integer,Nothing}=nothing) =
   Random.seed!(_flint_rand_states[Threads.threadid()], seed)

function make_seed(n::Integer)
    n < 0 && throw(DomainError(n, "`n` must be non-negative."))
    seed = UInt32[]
    while true
        push!(seed, n & 0xffffffff)
        n >>= 32
        if n == 0
            return seed
        end
    end
end

function Random.seed!(a::rand_ctx, s::Integer)
   # we hash the seed to obtain better independence of streams for
   # two given seeds which could be "not very different"
   # (cf. the documentation of `gmp_randseed`).
   # Hashing has a negligible cost compared to the call to `gmp_randseed`.
   ctx = SHA.SHA2_512_CTX()
   seed = make_seed(s)::Vector{UInt32}
   SHA.update!(ctx, reinterpret(UInt8, seed))
   digest = reinterpret(UInt, SHA.digest!(ctx))
   @assert Base.GMP.Limb == UInt

   # two last words go for flint_randseed!
   flint_randseed!(a, digest[end], digest[end-1])

   # remaining words (6 or 14) for flint_gmp_randseed!
   seedbits = 512 - 2*sizeof(UInt)*8
   n = Int(seedbits / (sizeof(UInt)*8))
   @assert n == 6 && UInt === UInt64 || n == 14 && UInt === UInt32
   b = BigInt(nbits = seedbits)

   @assert b.alloc >= n
   GC.@preserve digest b unsafe_copyto!(b.d, pointer(digest), n)
   b.size = n
   flint_gmp_randseed!(a, b)
   return a
end

Random.seed!(a::rand_ctx, s::Nothing=nothing) = Random.seed!(a, rand(UInt128))

flint_randseed!(a::rand_ctx, seed1::UInt, seed2::UInt) =
   ccall((:flint_randseed, libflint), Cvoid, (Ptr{Cvoid}, UInt, UInt), a.ptr, seed1, seed2)

function flint_gmp_randseed!(a::rand_ctx, seed::BigInt)
   ccall((:_flint_rand_init_gmp, libflint), Cvoid, (Ptr{Cvoid},), a.ptr)
   ccall((:__gmp_randseed, :libgmp), Cvoid, (Ptr{Cvoid}, Ref{BigInt}),
         a.ptr, # gmp_state is the first field of a.ptr (cf. flint.h)
         seed)
end

################################################################################
#
#  Thread local storages
#
################################################################################

const _flint_rand_states = rand_ctx[]

# Data from http://www.mersennewiki.org/index.php/Elliptic_Curve_Method
const _ecm_B1 = Int[2, 11, 50, 250, 1000, 3000, 11000, 43000, 110000, 260000, 850000, 2900000];
const _ecm_nC = Int[25, 90, 300, 700, 1800, 5100, 10600, 19300, 49000, 124000, 210000, 340000];

const _ecm_B1s = Vector{Int}[_ecm_B1]
const _ecm_nCs = Vector{Int}[_ecm_nC]

###############################################################################
#
#   Set domain for ZZ, QQ, PadicField, finite_field to Flint
#
###############################################################################

const ZZ = FlintZZ
const QQ = FlintQQ
const PadicField = FlintPadicField
const QadicField = FlintQadicField
const finite_field = FlintFiniteField

###############################################################################
#
#   Set domain for RR, CC to Arb
#
###############################################################################

GaussianIntegers() = FlintZZi
GaussianRationals() = FlintQQi

###############################################################################
#
#   Set domain for QQBar to Calcium
#
###############################################################################

const QQBar = CalciumQQBar


###############################################################################
#
#   Test code
#
###############################################################################

include("../benchmarks/runbenchmarks.jl")

function test_module(x, y)
   julia_exe = Base.julia_cmd()
   test_file = joinpath(pkgdir, "test/$x/")
   test_file = test_file * "$y-test.jl";
   test_function_name = "test_"

   if x in ["flint", "arb", "antic"]
     test_function_name *= y
   else x == "generic"
     if y == "RelSeries"
       test_function_name *= "gen_rel_series"
     elseif y == "AbsSeries"
       test_function_name *= "gen_abs_series"
     elseif y == "Matrix"
       test_function_name *= "gen_mat"
     elseif y == "Fraction"
       test_function_name *= "gen_frac"
     elseif y == "Residue"
       test_function_name *= "gen_res"
     else
       test_function_name *= "gen_$(lowercase(y))"
     end
   end

   cmd = "using Test; using Nemo; include(\"$test_file\"); $test_function_name();"
   println("spawning ", `$julia_exe -e \"$cmd\"`)
   run(`$julia_exe -e $cmd`)
end

################################################################################
#
#   Deprecations
#
################################################################################

include("Deprecations.jl")

include("Aliases.jl")

include("Native.jl")

end # module
