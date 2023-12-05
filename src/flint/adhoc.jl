###############################################################################
#
#   Absolute Power Series Ring
#
###############################################################################

function *(a::ZZRingElem, b::AbsPowerSeriesRingElem)
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   z = set_precision!(z, precision(b))
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   z = set_length!(z, normalise(z, len))
   return z
end

*(a::AbsPowerSeriesRingElem, b::ZZRingElem) = b*a

==(x::AbsPowerSeriesRingElem, y::ZZRingElem) = precision(x) == 0 || ((length(x) == 0 && iszero(y))
                                       || (length(x) == 1 && coeff(x, 0) == y))

==(x::ZZRingElem, y::AbsPowerSeriesRingElem) = y == x

function divexact(x::AbsPowerSeriesRingElem, y::ZZRingElem; check::Bool=true)
   iszero(y) && throw(DivideError())
   lenx = length(x)
   z = parent(x)()
   fit!(z, lenx)
   z = set_precision!(z, precision(x))
   for i = 1:lenx
      z = setcoeff!(z, i - 1, divexact(coeff(x, i - 1), y))
   end
   return z
end

function (a::Generic.AbsPowerSeriesRing{T})(b::ZZRingElem) where {T <: RingElement}
   if iszero(b)
      z = Generic.AbsSeries{T}(Array{T}(undef, 0), 0, a.prec_max)
   else
      z = Generic.AbsSeries{T}([base_ring(a)(b)], 1, a.prec_max)
   end
   z.parent = a
   return z
end

###############################################################################
#
#   Relative Power Series Ring
#
###############################################################################

function *(a::ZZRingElem, b::RelPowerSeriesRingElem)
   len = pol_length(b)
   z = parent(b)()
   fit!(z, len)
   z = set_precision!(z, precision(b))
   z = set_valuation!(z, valuation(b))
   for i = 1:len
      z = setcoeff!(z, i - 1, a*polcoeff(b, i - 1))
   end
   z = set_length!(z, normalise(z, len))
   renormalize!(z)
   return z
end

*(a::RelPowerSeriesRingElem, b::ZZRingElem) = b*a

==(x::RelPowerSeriesRingElem, y::ZZRingElem) = precision(x) == 0 ||
                  ((pol_length(x) == 0 && iszero(y)) || (pol_length(x) == 1 &&
                    valuation(x) == 0 && polcoeff(x, 0) == y))

==(x::ZZRingElem, y::RelPowerSeriesRingElem) = y == x

function divexact(x::RelPowerSeriesRingElem, y::ZZRingElem; check::Bool=true)
   iszero(y) && throw(DivideError())
   lenx = pol_length(x)
   z = parent(x)()
   fit!(z, lenx)
   z = set_precision!(z, precision(x))
   z = set_valuation!(z, valuation(x))
   for i = 1:lenx
      z = setcoeff!(z, i - 1, divexact(polcoeff(x, i - 1), y; check=check))
   end
   return z
end

function (a::Generic.RelPowerSeriesRing{T})(b::ZZRingElem) where {T <: RingElement}
   if iszero(b)
      z = Generic.RelSeries{T}(Array{T}(undef, 0), 0, a.prec_max, a.prec_max)
   else
      z = Generic.RelSeries{T}([base_ring(a)(b)], 1, a.prec_max, 0)
   end
   z.parent = a
   return z
end

###############################################################################
#
#   Polynomial Ring
#
###############################################################################

function *(a::ZZRingElem, b::PolyRingElem)
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   z = set_length!(z, normalise(z, len))
   return z
end

*(a::PolyRingElem, b::ZZRingElem) = b*a

==(x::PolyRingElem, y::ZZRingElem) = ((length(x) == 0 && iszero(y))
                        || (length(x) == 1 && coeff(x, 0) == y))

==(x::ZZRingElem, y::PolyRingElem) = y == x

function divexact(a::PolyRingElem, b::ZZRingElem; check::Bool=true)
   iszero(b) && throw(DivideError())
   z = parent(a)()
   fit!(z, length(a))
   for i = 1:length(a)
      z = setcoeff!(z, i - 1, divexact(coeff(a, i - 1), b; check=check))
   end
   z = set_length!(z, length(a))
   return z
end

# ambiguities

function *(a::ZZRingElem, b::PolyRingElem{ZZRingElem})
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   z = set_length!(z, normalise(z, len))
   return z
end

*(a::PolyRingElem{ZZRingElem}, b::ZZRingElem) = b*a

==(x::PolyRingElem{ZZRingElem}, y::ZZRingElem) = ((length(x) == 0 && iszero(y))
                        || (length(x) == 1 && coeff(x, 0) == y))

==(x::ZZRingElem, y::PolyRingElem{ZZRingElem}) = y == x

function divexact(a::PolyRingElem{ZZRingElem}, b::ZZRingElem; check::Bool=true)
   iszero(b) && throw(DivideError())
   z = parent(a)()
   fit!(z, length(a))
   for i = 1:length(a)
      z = setcoeff!(z, i - 1, divexact(coeff(a, i - 1), b; check=check))
   end
   z = set_length!(z, length(a))
   return z
end

###############################################################################
#
#   Residue Ring
#
###############################################################################

*(a::ResElem, b::ZZRingElem) = parent(a)(data(a) * b)

*(a::ZZRingElem, b::ResElem) = parent(b)(a * data(b))

+(a::ResElem, b::ZZRingElem) = parent(a)(data(a) + b)

+(a::ZZRingElem, b::ResElem) = parent(b)(a + data(b))

-(a::ResElem, b::ZZRingElem) = parent(a)(data(a) - b)

-(a::ZZRingElem, b::ResElem) = parent(b)(a - data(b))

function ==(a::ResElem, b::ZZRingElem)
   z = base_ring(a)(b)
   return data(a) == mod(z, modulus(a))
end

function ==(a::ZZRingElem, b::ResElem)
   z = base_ring(b)(a)
   return data(b) == mod(z, modulus(b))
end

# ambiguities

*(a::ResElem{ZZRingElem}, b::ZZRingElem) = parent(a)(data(a) * b)

*(a::ZZRingElem, b::ResElem{ZZRingElem}) = b*a

+(a::ResElem{ZZRingElem}, b::ZZRingElem) = parent(a)(data(a) + b)

+(a::ZZRingElem, b::ResElem{ZZRingElem}) = b + a

-(a::ResElem{ZZRingElem}, b::ZZRingElem) = parent(a)(data(a) - b)

-(a::ZZRingElem, b::ResElem{ZZRingElem}) = parent(b)(a - data(b))

function ==(a::ResElem{ZZRingElem}, b::ZZRingElem)
   z = base_ring(a)(b)
   return data(a) == mod(z, modulus(a))
end

==(a::ZZRingElem, b::ResElem{ZZRingElem}) = b == a

###############################################################################
#
#   Multivariate Polynomial Ring
#
###############################################################################

function *(a::Generic.MPoly{T}, n::ZZRingElem) where T <: RingElem
   N = size(a.exps, 1)
   r = parent(a)()
   fit!(r, length(a))
   j = 1
   for i = 1:length(a)
      c = a.coeffs[i]*n
      if c != 0
         r.coeffs[j] = c
         monomial_set!(r.exps, j, a.exps, i, N)
         j += 1
      end
   end
   r.length = j - 1
   resize!(r.coeffs, r.length)
   return r
end

*(n::ZZRingElem, a::Generic.MPoly{T}) where T <: RingElem = a*n

function ==(a::Generic.MPoly{T}, n::ZZRingElem) where T <: RingElem
   N = size(a.exps, 1)
   if iszero(n)
      return a.length == 0
   elseif a.length == 1
      return a.coeffs[1] == n && monomial_iszero(a.exps, 1, N)
   end
   return false
end

function evaluate(a::Generic.MPoly{T}, A::Vector{ZZRingElem}) where {T <: RingElement}
   if iszero(a)
      return base_ring(a)()
   end
   N = size(a.exps, 1)
   ord = parent(a).ord
   if ord == :lex
      start_var = N
   else
      start_var = N - 1
   end
   if ord == :degrevlex
      while a.length > 1 || (a.length == 1 && !monomial_iszero(a.exps, a.length, N))
         k = main_variable(a, start_var)
         p = main_variable_extract(a, k)
         a = evaluate(p, A[k])
      end
   else
      while a.length > 1 || (a.length == 1 && !monomial_iszero(a.exps, a.length, N))
         k = main_variable(a, start_var)
         p = main_variable_extract(a, k)
         a = evaluate(p, A[start_var - k + 1])
      end
   end
   if a.length == 0
      return base_ring(a)()
   else
      return a.coeffs[1]
   end
end

###############################################################################
#
#   Sparse Polynomial Ring
#
###############################################################################

function *(a::Generic.SparsePoly{T}, n::ZZRingElem) where T <: RingElem
   r = parent(a)()
   fit!(r, length(a))
   j = 1
   for i = 1:length(a)
      c = a.coeffs[i]*n
      if c != 0
         r.coeffs[j] = c
         r.exps[j] = a.exps[i]
         j += 1
      end
   end
   r.length = j - 1
   return r
end

*(n::ZZRingElem, a::Generic.SparsePoly{T}) where T <: RingElem = a*n

function ==(a::Generic.SparsePoly{T}, b::ZZRingElem) where T <: RingElem
   return length(a) == 0 ? iszero(b) : a.length == 1 &
          a.exps[1] == 0 && a.coeffs[1] == b
end

==(a::ZZRingElem, b::Generic.SparsePoly{T}) where T <: RingElem = b == a

function divexact(a::Generic.SparsePoly{T}, b::ZZRingElem; check::Bool=true) where T <: RingElem
   len = length(a)
   exps = deepcopy(a.exps)
   coeffs = [divexact(a.coeffs[i], b; check=check) for i in 1:len]
   return parent(a)(coeffs, exps)
end

###############################################################################
#
#   Matrix Space
#
###############################################################################

function *(x::ZZRingElem, y::MatElem)
   z = similar(y)
   for i = 1:nrows(y)
      for j = 1:ncols(y)
         z[i, j] = x*y[i, j]
      end
   end
   return z
end

*(x::MatElem, y::ZZRingElem) = y*x

function +(x::ZZRingElem, y::MatElem)
   z = similar(y)
   R = base_ring(y)
   for i = 1:nrows(y)
      for j = 1:ncols(y)
         if i != j
            z[i, j] = deepcopy(y[i, j])
         else
            z[i, j] = y[i, j] + R(x)
         end
      end
   end
   return z
end

+(x::MatElem, y::ZZRingElem) = y + x

function -(x::ZZRingElem, y::MatElem)
   z = similar(y)
   R = base_ring(y)
   for i = 1:nrows(y)
      for j = 1:ncols(y)
         if i != j
            z[i, j] = -y[i, j]
         else
            z[i, j] = x - y[i, j]
         end
      end
   end
   return z
end

function -(x::MatElem, y::ZZRingElem)
   z = similar(x)
   R = base_ring(x)
   for i = 1:nrows(x)
      for j = 1:ncols(x)
         if i != j
            z[i, j] = deepcopy(x[i, j])
         else
            z[i, j] = x[i, j] - y
         end
      end
   end
   return z
end

function ==(x::MatElem, y::ZZRingElem)
   for i = 1:min(nrows(x), ncols(x))
      if x[i, i] != y
         return false
      end
   end
   for i = 1:nrows(x)
      for j = 1:ncols(x)
         if i != j && !iszero(x[i, j])
            return false
         end
      end
   end
   return true
end

==(x::ZZRingElem, y::MatElem) = y == x

function divexact(x::MatElem, y::ZZRingElem; check::Bool=true)
   z = similar(x)
   for i = 1:nrows(x)
      for j = 1:ncols(x)
         z[i, j] = divexact(x[i, j], y; check=check)
      end
   end
   return z
end

function (a::Generic.MatSpace{T})(b::ZZMatrix) where {T <: RingElement}
  if a.nrows != nrows(b) || a.ncols != ncols(b)
    error("incompatible matrix dimensions")
  end
  A = a()
  R = base_ring(a)
  for i=1:a.nrows
    for j=1:a.ncols
      A[i,j] = R(b[i,j])
    end
  end
  return A
end

###############################################################################
#
#   Residue Ring
#
###############################################################################

###############################################################################
#
#   Fraction Field
#
###############################################################################

//(x::T, y::ZZRingElem) where {T <: RingElem} = x//parent(x)(y)

//(x::ZZRingElem, y::T) where {T <: RingElem} = parent(y)(x)//y

function *(a::FracElem, b::ZZRingElem)
   c = base_ring(a)(b)
   g = gcd(denominator(a), c)
   n = numerator(a)*divexact(c, g)
   d = divexact(denominator(a), g)
   return parent(a)(n, d)
end

function *(a::ZZRingElem, b::FracElem)
   c = base_ring(b)(a)
   g = gcd(denominator(b), c)
   n = numerator(b)*divexact(c, g)
   d = divexact(denominator(b), g)
   return parent(b)(n, d)
end

function +(a::FracElem, b::ZZRingElem)
   n = numerator(a) + denominator(a)*b
   d = denominator(a)
   g = gcd(n, d)
   return parent(a)(divexact(n, g), divexact(d, g))
end

function -(a::FracElem, b::ZZRingElem)
   n = numerator(a) - denominator(a)*b
   d = denominator(a)
   g = gcd(n, d)
   return parent(a)(divexact(n, g), divexact(d, g))
end

+(a::ZZRingElem, b::FracElem) = b + a

function -(a::ZZRingElem, b::FracElem)
   n = a*denominator(b) - numerator(b)
   d = denominator(b)
   g = gcd(n, d)
   return parent(b)(divexact(n, g), divexact(d, g))
end

function ==(x::FracElem, y::ZZRingElem)
   return (isone(denominator(x)) && numerator(x) == y) || (numerator(x) == denominator(x)*y)
end

==(x::ZZRingElem, y::FracElem) = y == x

function divexact(a::FracElem, b::ZZRingElem; check::Bool=true)
   iszero(b) && throw(DivideError())
   c = base_ring(a)(b)
   g = gcd(numerator(a), c)
   n = divexact(numerator(a), g)
   d = denominator(a)*divexact(c, g)
   return parent(a)(n, d)
end

function divexact(a::ZZRingElem, b::FracElem; check::Bool=true)
   iszero(b) && throw(DivideError())
   c = base_ring(b)(a)
   g = gcd(numerator(b), c)
   n = denominator(b)*divexact(c, g)
   d = divexact(numerator(b), g)
   return parent(b)(n, d)
end

function (a::Generic.FracField{T})(b::ZZRingElem) where {T <: RingElement}
   z = Generic.FracFieldElem{T}(base_ring(a)(b), one(base_ring(a)))
   z.parent = a
   return z
end
