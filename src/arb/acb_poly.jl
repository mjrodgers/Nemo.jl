###############################################################################
#
#   acb_poly.jl : Polynomials over arb
#
###############################################################################

export AcbPolyRing, acb_poly, isreal, derivative, integral, evaluate,
       evaluate2, compose, from_roots, evaluate_iter, evaluate_fast, evaluate,
       interpolate_newton, interpolate_barycentric, interpolate_fast,
       interpolate, roots

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent_type(::Type{acb_poly}) = AcbPolyRing

elem_type(::Type{AcbPolyRing}) = acb_poly

dense_poly_type(::Type{acb}) = acb_poly

length(x::acb_poly) = ccall((:acb_poly_length, libarb), Int,
                                   (Ref{acb_poly},), x)

function set_length!(x::acb_poly, n::Int)
   ccall((:_acb_poly_set_length, libarb), Nothing,
                                   (Ref{acb_poly}, Int), x, n)
   return x
end

degree(x::acb_poly) = length(x) - 1

function coeff(a::acb_poly, n::Int)
  n < 0 && throw(DomainError(n, "Index must be non-negative"))
  t = parent(a).base_ring()
  ccall((:acb_poly_get_coeff_acb, libarb), Nothing,
              (Ref{acb}, Ref{acb_poly}, Int), t, a, n)
  return t
end

zero(a::AcbPolyRing) = a(0)

one(a::AcbPolyRing) = a(1)

function gen(a::AcbPolyRing)
   z = acb_poly()
   ccall((:acb_poly_set_coeff_si, libarb), Nothing,
        (Ref{acb_poly}, Int, Int), z, 1, 1)
   z.parent = a
   return z
end

# todo: write a C function for this
function is_gen(a::acb_poly)
   return isequal(a, gen(parent(a)))
end

#function iszero(a::acb_poly)
#   return length(a) == 0
#end

#function isone(a::acb_poly)
#   return isequal(a, one(parent(a)))
#end

function deepcopy_internal(a::acb_poly, dict::IdDict)
   z = acb_poly(a)
   z.parent = parent(a)
   return z
end

characteristic(::AcbPolyRing) = 0

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

function show(io::IO, x::AcbPolyRing)
  print(io, "Univariate Polynomial Ring in ")
  print(io, var(x))
  print(io, " over ")
  show(io, x.base_ring)
end

function Base.show(io::IO, a::acb_poly)
   print(io, AbstractAlgebra.obj_to_string(a, context = io))
end

###############################################################################
#
#   Similar
#
###############################################################################

function similar(f::PolyRingElem, R::AcbField, var::VarName=var(parent(f)); cached::Bool=true)
   z = acb_poly()
   z.parent = AcbPolyRing(R, Symbol(var), cached)
   return z
end

###############################################################################
#
#   polynomial constructor
#
###############################################################################

function polynomial(R::AcbField, arr::Vector{T}, var::VarName=:x; cached::Bool=true) where T
   coeffs = map(R, arr)
   coeffs = length(coeffs) == 0 ? acb[] : coeffs
   z = acb_poly(coeffs, R.prec)
   z.parent = AcbPolyRing(R, Symbol(var), cached)
   return z
end

###############################################################################
#
#   Comparisons
#
###############################################################################

function isequal(x::acb_poly, y::acb_poly)
   return ccall((:acb_poly_equal, libarb), Bool,
                                      (Ref{acb_poly}, Ref{acb_poly}), x, y)
end

@doc raw"""
    overlaps(x::acb_poly, y::acb_poly)

Return `true` if the coefficient boxes of $x$ overlap the coefficient boxes
of $y$, otherwise return `false`.
"""
function overlaps(x::acb_poly, y::acb_poly)
   return ccall((:acb_poly_overlaps, libarb), Bool,
                                      (Ref{acb_poly}, Ref{acb_poly}), x, y)
end

@doc raw"""
    contains(x::acb_poly, y::acb_poly)

Return `true` if the coefficient boxes of $x$ contain the corresponding
coefficient boxes of $y$, otherwise return `false`.
"""
function contains(x::acb_poly, y::acb_poly)
   return ccall((:acb_poly_contains, libarb), Bool,
                                      (Ref{acb_poly}, Ref{acb_poly}), x, y)
end

@doc raw"""
    contains(x::acb_poly, y::ZZPolyRingElem)

Return `true` if the coefficient boxes of $x$ contain the corresponding
exact coefficients of $y$, otherwise return `false`.
"""
function contains(x::acb_poly, y::ZZPolyRingElem)
   return ccall((:acb_poly_contains_fmpz_poly, libarb), Bool,
                                      (Ref{acb_poly}, Ref{ZZPolyRingElem}), x, y)
end

@doc raw"""
    contains(x::acb_poly, y::QQPolyRingElem)

Return `true` if the coefficient boxes of $x$ contain the corresponding
exact coefficients of $y$, otherwise return `false`.
"""
function contains(x::acb_poly, y::QQPolyRingElem)
   return ccall((:acb_poly_contains_fmpq_poly, libarb), Bool,
                                      (Ref{acb_poly}, Ref{QQPolyRingElem}), x, y)
end

function ==(x::acb_poly, y::acb_poly)
    if length(x) != length(y)
        return false
    end
    for i = 0:degree(x)
        if !(coeff(x, i) == coeff(y, i))
            return false
        end
    end
    return true
end

function !=(x::acb_poly, y::acb_poly)
    for i = 0:max(degree(x), degree(y))
        if coeff(x, i) != coeff(y, i)
            return true
        end
    end
    return false
end

@doc raw"""
    unique_integer(x::acb_poly)

Return a tuple `(t, z)` where $t$ is `true` if there is a unique integer
contained in the (constant) polynomial $x$, along with that integer $z$
in case it is, otherwise sets $t$ to `false`.
"""
function unique_integer(x::acb_poly)
  z = ZZPolyRing(FlintZZ, var(parent(x)))()
  unique = ccall((:acb_poly_get_unique_fmpz_poly, libarb), Int,
    (Ref{ZZPolyRingElem}, Ref{acb_poly}), z, x)
  return (unique != 0, z)
end

function isreal(x::acb_poly)
  return ccall((:acb_poly_is_real, libarb), Cint, (Ref{acb_poly}, ), x) != 0
end

###############################################################################
#
#   Shifting
#
###############################################################################

function shift_left(x::acb_poly, len::Int)
   len < 0 && throw(DomainError(len, "Shift must be non-negative"))
   z = parent(x)()
   ccall((:acb_poly_shift_left, libarb), Nothing,
      (Ref{acb_poly}, Ref{acb_poly}, Int), z, x, len)
   return z
end

function shift_right(x::acb_poly, len::Int)
   len < 0 && throw(DomainError(len, "Shift must be non-negative"))
   z = parent(x)()
   ccall((:acb_poly_shift_right, libarb), Nothing,
       (Ref{acb_poly}, Ref{acb_poly}, Int), z, x, len)
   return z
end

################################################################################
#
#  Unary operations
#
################################################################################

function -(x::acb_poly)
  z = parent(x)()
  ccall((:acb_poly_neg, libarb), Nothing, (Ref{acb_poly}, Ref{acb_poly}), z, x)
  return z
end

################################################################################
#
#  Binary operations
#
################################################################################

function +(x::acb_poly, y::acb_poly)
  z = parent(x)()
  ccall((:acb_poly_add, libarb), Nothing,
              (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
              z, x, y, precision(parent(x)))
  return z
end

function *(x::acb_poly, y::acb_poly)
  z = parent(x)()
  ccall((:acb_poly_mul, libarb), Nothing,
              (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
              z, x, y, precision(parent(x)))
  return z
end

function -(x::acb_poly, y::acb_poly)
  z = parent(x)()
  ccall((:acb_poly_sub, libarb), Nothing,
              (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
              z, x, y, precision(parent(x)))
  return z
end

function ^(x::acb_poly, y::Int)
  y < 0 && throw(DomainError(y, "Exponent must be non-negative"))
  z = parent(x)()
  ccall((:acb_poly_pow_ui, libarb), Nothing,
              (Ref{acb_poly}, Ref{acb_poly}, UInt, Int),
              z, x, y, precision(parent(x)))
  return z
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

for T in [Integer, ZZRingElem, QQFieldElem, Float64, BigFloat, arb, acb, ZZPolyRingElem, QQPolyRingElem]
   @eval begin
      +(x::acb_poly, y::$T) = x + parent(x)(y)

      +(x::$T, y::acb_poly) = y + x

      -(x::acb_poly, y::$T) = x - parent(x)(y)

      -(x::$T, y::acb_poly) = parent(y)(x) - y

      *(x::acb_poly, y::$T) = x * parent(x)(y)

      *(x::$T, y::acb_poly) = y * x
   end
end

+(x::acb_poly, y::Rational{T}) where T <: Union{Int, BigInt} = x + parent(x)(y)

+(x::Rational{T}, y::acb_poly) where T <: Union{Int, BigInt} = y + x

-(x::acb_poly, y::Rational{T}) where T <: Union{Int, BigInt} = x - parent(x)(y)

-(x::Rational{T}, y::acb_poly) where T <: Union{Int, BigInt} = parent(y)(x) - y

*(x::acb_poly, y::Rational{T}) where T <: Union{Int, BigInt} = x * parent(x)(y)

*(x::Rational{T}, y::acb_poly) where T <: Union{Int, BigInt} = y * x

###############################################################################
#
#   Scalar division
#
###############################################################################

for T in [Integer, ZZRingElem, QQFieldElem, Float64, BigFloat, arb, acb]
   @eval begin
      divexact(x::acb_poly, y::$T; check::Bool=true) = x * inv(base_ring(parent(x))(y))

      //(x::acb_poly, y::$T) = divexact(x, y)

      /(x::acb_poly, y::$T) = divexact(x, y)
   end
end

divexact(x::acb_poly, y::Rational{T}; check::Bool=true) where {T <: Integer} = x * inv(base_ring(parent(x))(y))

//(x::acb_poly, y::Rational{T}) where {T <: Integer} = divexact(x, y)

/(x::acb_poly, y::Rational{T}) where {T <: Integer} = divexact(x, y)

###############################################################################
#
#   Euclidean division
#
###############################################################################

function Base.divrem(x::acb_poly, y::acb_poly)
   iszero(y) && throw(DivideError())
   q = parent(x)()
   r = parent(x)()
   if (ccall((:acb_poly_divrem, libarb), Int,
         (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
               q, r, x, y, precision(parent(x))) == 1)
      return (q, r)
   else
      throw(DivideError())
   end
end

function mod(x::acb_poly, y::acb_poly)
   return divrem(x, y)[2]
end

function divexact(x::acb_poly, y::acb_poly; check::Bool=true)
   return divrem(x, y)[1]
end

###############################################################################
#
#   Truncation
#
###############################################################################

function truncate(a::acb_poly, n::Int)
   n < 0 && throw(DomainError(n, "Index must be non-negative"))
   if length(a) <= n
      return a
   end
   # todo: implement set_trunc in arb
   z = deepcopy(a)
   ccall((:acb_poly_truncate, libarb), Nothing,
                (Ref{acb_poly}, Int), z, n)
   return z
end

function mullow(x::acb_poly, y::acb_poly, n::Int)
   n < 0 && throw(DomainError(n, "Index must be non-negative"))
   z = parent(x)()
   ccall((:acb_poly_mullow, libarb), Nothing,
         (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int, Int),
            z, x, y, n, precision(parent(x)))
   return z
end

###############################################################################
#
#   Reversal
#
###############################################################################

#function reverse(x::acb_poly, len::Int)
#   len < 0 && throw(DomainError())
#   z = parent(x)()
#   ccall((:acb_poly_reverse, libarb), Nothing,
#                (Ref{acb_poly}, Ref{acb_poly}, Int), z, x, len)
#   return z
#end

###############################################################################
#
#   Evaluation
#
###############################################################################

function evaluate(x::acb_poly, y::acb)
   z = parent(y)()
   ccall((:acb_poly_evaluate, libarb), Nothing,
                (Ref{acb}, Ref{acb_poly}, Ref{acb}, Int),
                z, x, y, precision(parent(y)))
   return z
end

evaluate(x::acb_poly, y::RingElem) = evaluate(x, base_ring(parent(x))(y))
evaluate(x::acb_poly, y::Integer) = evaluate(x, base_ring(parent(x))(y))
evaluate(x::acb_poly, y::Rational) = evaluate(x, base_ring(parent(x))(y))
evaluate(x::acb_poly, y::Float64) = evaluate(x, base_ring(parent(x))(y))
evaluate(x::acb_poly, y::Any) = evaluate(x, base_ring(parent(x))(y))

@doc raw"""
    evaluate2(x::acb_poly, y::RingElement)

Return a tuple $p, q$ consisting of the polynomial $x$ evaluated at $y$ and
its derivative evaluated at $y$.
"""
function evaluate2(x::acb_poly, y::acb)
   z = parent(y)()
   w = parent(y)()
   ccall((:acb_poly_evaluate2, libarb), Nothing,
                (Ref{acb}, Ref{acb}, Ref{acb_poly}, Ref{acb}, Int),
                z, w, x, y, precision(parent(y)))
   return z, w
end

evaluate2(x::acb_poly, y::RingElement) = evaluate2(x, base_ring(parent(x))(y))

###############################################################################
#
#   Composition
#
###############################################################################

function compose(x::acb_poly, y::acb_poly)
   z = parent(x)()
   ccall((:acb_poly_compose, libarb), Nothing,
                (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
                z, x, y, precision(parent(x)))
   return z
end

###############################################################################
#
#   Derivative and integral
#
###############################################################################

function derivative(x::acb_poly)
   z = parent(x)()
   ccall((:acb_poly_derivative, libarb), Nothing,
                (Ref{acb_poly}, Ref{acb_poly}, Int), z, x, precision(parent(x)))
   return z
end

function integral(x::acb_poly)
   z = parent(x)()
   ccall((:acb_poly_integral, libarb), Nothing,
                (Ref{acb_poly}, Ref{acb_poly}, Int), z, x, precision(parent(x)))
   return z
end

###############################################################################
#
#   Multipoint evaluation and interpolation
#
###############################################################################

function acb_vec(b::Vector{acb})
   v = ccall((:_acb_vec_init, libarb), Ptr{acb_struct}, (Int,), length(b))
   for i=1:length(b)
       ccall((:acb_set, libarb), Nothing, (Ptr{acb_struct}, Ref{acb}),
           v + (i-1)*sizeof(acb_struct), b[i])
   end
   return v
end

function array(R::AcbField, v::Ptr{acb_struct}, n::Int)
   r = Vector{acb}(undef, n)
   for i=1:n
       r[i] = R()
       ccall((:acb_set, libarb), Nothing, (Ref{acb}, Ptr{acb_struct}),
           r[i], v + (i-1)*sizeof(acb_struct))
   end
   return r
end

@doc raw"""
    from_roots(R::AcbPolyRing, b::Vector{acb})

Construct a polynomial in the given polynomial ring from a list of its roots.
"""
function from_roots(R::AcbPolyRing, b::Vector{acb})
   z = R()
   tmp = acb_vec(b)
   ccall((:acb_poly_product_roots, libarb), Nothing,
                (Ref{acb_poly}, Ptr{acb_struct}, Int, Int), z, tmp, length(b), precision(R))
   acb_vec_clear(tmp, length(b))
   return z
end

function evaluate_iter(x::acb_poly, b::Vector{acb})
   return acb[evaluate(x, b[i]) for i=1:length(b)]
end

function evaluate_fast(x::acb_poly, b::Vector{acb})
   tmp = acb_vec(b)
   ccall((:acb_poly_evaluate_vec_fast, libarb), Nothing,
                (Ptr{acb_struct}, Ref{acb_poly}, Ptr{acb_struct}, Int, Int),
            tmp, x, tmp, length(b), precision(parent(x)))
   res = array(base_ring(parent(x)), tmp, length(b))
   acb_vec_clear(tmp, length(b))
   return res
end

function interpolate_newton(R::AcbPolyRing, xs::Vector{acb}, ys::Vector{acb})
   length(xs) != length(ys) && error()
   z = R()
   xsv = acb_vec(xs)
   ysv = acb_vec(ys)
   ccall((:acb_poly_interpolate_newton, libarb), Nothing,
                (Ref{acb_poly}, Ptr{acb_struct}, Ptr{acb_struct}, Int, Int),
            z, xsv, ysv, length(xs), precision(R))
   acb_vec_clear(xsv, length(xs))
   acb_vec_clear(ysv, length(ys))
   return z
end

function interpolate_barycentric(R::AcbPolyRing, xs::Vector{acb}, ys::Vector{acb})
   length(xs) != length(ys) && error()
   z = R()
   xsv = acb_vec(xs)
   ysv = acb_vec(ys)
   ccall((:acb_poly_interpolate_barycentric, libarb), Nothing,
                (Ref{acb_poly}, Ptr{acb_struct}, Ptr{acb_struct}, Int, Int),
            z, xsv, ysv, length(xs), precision(R))
   acb_vec_clear(xsv, length(xs))
   acb_vec_clear(ysv, length(ys))
   return z
end

function interpolate_fast(R::AcbPolyRing, xs::Vector{acb}, ys::Vector{acb})
   length(xs) != length(ys) && error()
   z = R()
   xsv = acb_vec(xs)
   ysv = acb_vec(ys)
   ccall((:acb_poly_interpolate_fast, libarb), Nothing,
                (Ref{acb_poly}, Ptr{acb_struct}, Ptr{acb_struct}, Int, Int),
            z, xsv, ysv, length(xs), precision(R))
   acb_vec_clear(xsv, length(xs))
   acb_vec_clear(ysv, length(ys))
   return z
end

# todo: cutoffs for fast algorithm
function interpolate(R::AcbPolyRing, xs::Vector{acb}, ys::Vector{acb})
   return interpolate_newton(R, xs, ys)
end

# todo: cutoffs for fast algorithm
function evaluate(x::acb_poly, b::Vector{acb})
   return evaluate_iter(x, b)
end

###############################################################################
#
#   Root finding
#
###############################################################################

@doc raw"""
    roots(x::acb_poly; target=0, isolate_real=false, initial_prec=0, max_prec=0, max_iter=0)

Attempts to isolate the complex roots of the complex polynomial $x$ by
iteratively refining balls in which they lie.

This is done by increasing the working precision, starting at `initial_prec`.
The maximal number of iterations can be set using `max_iter` and the maximal
precision can be set using `max_prec`.

If `isolate_real` is set and $x$ is strictly real, then the real roots will
be isolated from the non-real roots. Every root will have either zero,
positive or negative real part.

It is assumed that $x$ is squarefree.
"""
function roots(x::acb_poly; target=0, isolate_real=false, initial_prec=0, max_prec=0, max_iter=0)
    deg = degree(x)
    if deg <= 0
        return Array{acb}(undef, 0)
    end

    initial_prec = (initial_prec >= 2) ? initial_prec : 32
    max_prec = (max_prec >= 2) ? max_prec : 3 * precision(parent(x))

    isolated = 0
    wp = initial_prec
    roots = acb_vec(deg)

    while true
        in_roots = (wp == initial_prec) ? C_NULL : roots
        step_max_iter = (max_iter >= 1) ? max_iter : min(max(deg, 32), wp)
        isolated = ccall((:acb_poly_find_roots, libarb), Int,
            (Ptr{acb_struct}, Ref{acb_poly}, Ptr{acb_struct}, Int, Int),
                roots, x, in_roots, step_max_iter, wp)

        wp = wp * 2

        if isolated == deg
            ok = true
            if target > 0
                for i = 0 : deg-1
                    re = ccall((:acb_real_ptr, libarb), Ptr{arb_struct},
                        (Ptr{acb}, ), roots + i * sizeof(acb_struct))
                    im = ccall((:acb_imag_ptr, libarb), Ptr{arb_struct},
                        (Ptr{acb}, ), roots + i * sizeof(acb_struct))
                    t = ccall((:arb_rad_ptr, libarb), Ptr{mag_struct}, (Ptr{arb}, ), re)
                    u = ccall((:arb_rad_ptr, libarb), Ptr{mag_struct}, (Ptr{arb}, ), im)
                    ok = ok && (ccall((:mag_cmp_2exp_si, libarb), Cint,
                        (Ptr{mag_struct}, Int), t, -target) <= 0)
                    ok = ok && (ccall((:mag_cmp_2exp_si, libarb), Cint,
                        (Ptr{mag_struct}, Int), u, -target) <= 0)
                end
            end

            if isreal(x)
                real_ok = ccall((:acb_poly_validate_real_roots, libarb),
                    Bool, (Ptr{acb_struct}, Ref{acb_poly}, Int), roots, x, wp)

                if isolate_real && !real_ok
                    ok = false
                end

                if real_ok
                    for i = 0 : deg - 1
                        im = ccall((:acb_imag_ptr, libarb), Ptr{arb_struct},
                            (Ptr{acb}, ), roots + i * sizeof(acb_struct))
                        if ccall((:arb_contains_zero, libarb), Bool, (Ptr{arb_struct}, ), im)
                            ccall((:arb_zero, libarb), Nothing, (Ptr{arb_struct}, ), im)
                        end
                    end
                end
            end

            if ok
                break
            end
        end

        if wp > max_prec
            break
        end
    end

    if isolated == deg
        ccall((:_acb_vec_sort_pretty, libarb), Nothing,
            (Ptr{acb_struct}, Int), roots, deg)
        res = array(base_ring(parent(x)), roots, deg)
    end

    acb_vec_clear(roots, deg)

    if isolated == deg
        return res
    else
        error("unable to isolate all roots (insufficient precision, or there is a multiple root)")
    end
end

###############################################################################
#
#   Root bounds
#
###############################################################################

@doc raw"""
    roots_upper_bound(x::acb_poly) -> arb

Returns an upper bound for the absolute value of all complex roots of $x$.
"""
function roots_upper_bound(x::acb_poly)
   z = ArbField(precision(base_ring(x)))()
   p = precision(base_ring(x))
   GC.@preserve x z begin
      t = ccall((:arb_rad_ptr, libarb), Ptr{mag_struct}, (Ref{arb}, ), z)
      ccall((:acb_poly_root_bound_fujiwara, libarb), Nothing,
            (Ptr{mag_struct}, Ref{acb_poly}), t, x)
      s = ccall((:arb_mid_ptr, libarb), Ptr{arf_struct}, (Ref{arb}, ), z)
      ccall((:arf_set_mag, libarb), Nothing, (Ptr{arf_struct}, Ptr{mag_struct}), s, t)
      ccall((:arf_set_round, libarb), Nothing,
            (Ptr{arf_struct}, Ptr{arf_struct}, Int, Cint), s, s, p, ARB_RND_CEIL)
      ccall((:mag_zero, libarb), Nothing, (Ptr{mag_struct},), t)
   end
   return z
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(z::acb_poly)
   ccall((:acb_poly_zero, libarb), Nothing, (Ref{acb_poly},), z)
   return z
end

function fit!(z::acb_poly, n::Int)
   ccall((:acb_poly_fit_length, libarb), Nothing,
                    (Ref{acb_poly}, Int), z, n)
   return nothing
end

function setcoeff!(z::acb_poly, n::Int, x::ZZRingElem)
   ccall((:acb_poly_set_coeff_fmpz, libarb), Nothing,
                    (Ref{acb_poly}, Int, Ref{ZZRingElem}), z, n, x)
   return z
end

function setcoeff!(z::acb_poly, n::Int, x::acb)
   ccall((:acb_poly_set_coeff_acb, libarb), Nothing,
                    (Ref{acb_poly}, Int, Ref{acb}), z, n, x)
   return z
end

function mul!(z::acb_poly, x::acb_poly, y::acb_poly)
   ccall((:acb_poly_mul, libarb), Nothing,
                (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
                    z, x, y, precision(parent(z)))
   return z
end

function addeq!(z::acb_poly, x::acb_poly)
   ccall((:acb_poly_add, libarb), Nothing,
                (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
                    z, z, x, precision(parent(z)))
   return z
end

function add!(z::acb_poly, x::acb_poly, y::acb_poly)
   ccall((:acb_poly_add, libarb), Nothing,
                (Ref{acb_poly}, Ref{acb_poly}, Ref{acb_poly}, Int),
                    z, x, y, precision(parent(z)))
   return z
end

###############################################################################
#
#   Promotions
#
###############################################################################

promote_rule(::Type{acb_poly}, ::Type{ZZPolyRingElem}) = acb_poly

promote_rule(::Type{acb_poly}, ::Type{QQPolyRingElem}) = acb_poly

promote_rule(::Type{acb_poly}, ::Type{arb_poly}) = acb_poly

promote_rule(::Type{acb_poly}, ::Type{acb_poly}) = acb_poly

function promote_rule(::Type{acb_poly}, ::Type{T}) where {T}
   return promote_rule(acb, T) === acb ? acb_poly : Union{}
end

################################################################################
#
#  Parent object call overloads
#
################################################################################

function (a::AcbPolyRing)()
   z = acb_poly()
   z.parent = a
   return z
end

for T in [Integer, ZZRingElem, QQFieldElem, Float64, Complex{Float64},
          Complex{Int}, arb, acb]
  @eval begin
    function (a::AcbPolyRing)(b::$T)
      z = acb_poly(base_ring(a)(b), a.base_ring.prec)
      z.parent = a
      return z
    end
  end
end

(a::AcbPolyRing)(b::Rational{T}) where {T <: Integer} = a(QQFieldElem(b))

function (a::AcbPolyRing)(b::Vector{acb})
   z = acb_poly(b, a.base_ring.prec)
   z.parent = a
   return z
end

for T in [ZZRingElem, QQFieldElem, Float64, Complex{Float64}, Complex{Int}, arb]
  @eval begin
    (a::AcbPolyRing)(b::Vector{$T}) = a(map(base_ring(a), b))
  end
end

(a::AcbPolyRing)(b::Vector{T}) where {T <: Integer} = a(map(base_ring(a), b))

(a::AcbPolyRing)(b::Vector{Rational{T}}) where {T <: Integer} = a(map(base_ring(a), b))

function (a::AcbPolyRing)(b::ZZPolyRingElem)
   z = acb_poly(b, a.base_ring.prec)
   z.parent = a
   return z
end

function (a::AcbPolyRing)(b::QQPolyRingElem)
   z = acb_poly(b, a.base_ring.prec)
   z.parent = a
   return z
end

function (a::AcbPolyRing)(b::arb_poly)
   z = acb_poly(b, a.base_ring.prec)
   z.parent = a
   return z
end

function (a::AcbPolyRing)(b::acb_poly)
   z = acb_poly(b, a.base_ring.prec)
   z.parent = a
   return z
end
