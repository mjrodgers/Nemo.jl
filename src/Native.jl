module Native

import ..Nemo: ZZRingElem
import ..Nemo: VarName
import ..Nemo: ZZModPolyRingElem
import ..Nemo: FpPolyRingElem
import ..Nemo: FqPolyRepField
import ..Nemo: Zmodn_poly
import ..Nemo: fpField
import ..Nemo: FpField
import ..Nemo: fqPolyRepField
import ..Nemo: is_prime
import ..Nemo: is_probable_prime
import ..Nemo: gen
import ..Nemo: characteristic
import ..Nemo: similar

function GF(n::Int; cached::Bool=true)
  (n <= 0) && throw(DomainError(n, "Characteristic must be positive"))
  un = UInt(n)
  !is_prime(un) && throw(DomainError(n, "Characteristic must be prime"))
  return fpField(un, cached)
end

function GF(n::UInt; cached::Bool=true)
  un = UInt(n)
  !is_prime(un) && throw(DomainError(n, "Characteristic must be prime"))
  return fpField(un, cached)
end

function GF(n::ZZRingElem; cached::Bool=true)
  (n <= 0) && throw(DomainError(n, "Characteristic must be positive"))
  !is_probable_prime(n) && throw(DomainError(n, "Characteristic must be prime"))
  return FpField(n, cached)
end

function finite_field(char::ZZRingElem, deg::Int, s::VarName = :o; cached = true)
  parent_obj = FqPolyRepField(char, deg, Symbol(s), cached)
  return parent_obj, gen(parent_obj)
end

function finite_field(pol::Union{ZZModPolyRingElem, FpPolyRingElem},
    s::VarName = :o; cached = true, check::Bool=true)
  parent_obj = FqPolyRepField(pol, Symbol(s), cached, check=check)
  return parent_obj, gen(parent_obj)
end

function finite_field(F::FqPolyRepField, deg::Int, s::VarName = :o; cached = true)
  return FqPolyRepField(characteristic(F), deg, Symbol(s), cached)
end

similar(F::FqPolyRepField, deg::Int, s::VarName = :o; cached = true) = finite_field(F, deg, s, cached = cached)

function finite_field(char::Int, deg::Int, s::VarName = :o; cached = true)
   parent_obj = fqPolyRepField(ZZRingElem(char), deg, Symbol(s), cached)
   return parent_obj, gen(parent_obj)
end

function finite_field(pol::Zmodn_poly, s::VarName = :o; cached = true, check::Bool=true)
   parent_obj = fqPolyRepField(pol, Symbol(s), cached, check=check)
   return parent_obj, gen(parent_obj)
end

function finite_field(F::fqPolyRepField, deg::Int, s::VarName = :o; cached = true)
    return fqPolyRepField(characteristic(F), deg, Symbol(s), cached)
end

similar(F::fqPolyRepField, deg::Int, s::VarName = :o; cached = true) = FiniteField(F, deg, s, cached = cached)

# Additional from Hecke
function finite_field(p::Integer; cached::Bool = true)
  @assert is_prime(p)
  k = GF(p, cached=cached)
  return k, k(1)
end

function finite_field(p::ZZRingElem; cached::Bool = true)
  @assert is_prime(p)
  k = GF(p, cached=cached)
  return k, k(1)
end

GF(p::Integer, k::Int, s::VarName = :o; cached::Bool = true) = finite_field(p, k, s, cached = cached)[1]

GF(p::ZZRingElem, k::Int, s::VarName = :o; cached::Bool = true) = finite_field(p, k, s, cached = cached)[1]

import ..Nemo: @alias
@alias FiniteField finite_field # for compatibility with Hecke

end # module

using .Native
