```@meta
CurrentModule = Nemo
DocTestSetup = quote
    using Nemo
end
```

# Puiseux series

Nemo allows the creation of Puiseux series over any computable ring $R$. Puiseux series
are series of the form
$a_jx^{j/m} + a_{j+1}x^{(j+1)/m} + \cdots + a_{k-1}x^{(k-1)/m} + O(x^{k/m})$
where $m$ is a positive integer, $a_i \in R$ and the relative precision $k - j$ is at
most equal to some specified precision $n$.

There are two different kinds of implementation: a generic one for
the case where no specific implementation exists (provided by AbstractAlgebra.jl), and
efficient implementations of Puiseux series over numerous specific rings, usually
provided by C/C++ libraries.

The following table shows each of the Puiseux series types available in
Nemo, the base ring $R$, and the Julia/Nemo types for that kind of series (the
type information is mainly of concern to developers).

Base ring         | Library            | Element type                       | Parent type
------------------|--------------------|--------------------------------------------------|----------------------------------------------
Generic ring $R$  | AbstractAlgebra.jl | `Generic.PuiseuxSeriesRingElem{T}                | `Generic.PuiseuxSeriesRing{T}`
Generic field $K$ | AbstractAlgebra.jl | `Generic.PuiseuxSeriesFieldElem{T}               | `Generic.PuiseuxSeriesField{T}`
$\mathbb{Z}$      | Flint              | `FlintPuiseuxSeriesRingElem{ZZLaurentSeriesRingElem}`| `FlintPuiseuxSeriesRing{ZZLaurentSeriesRingElem}`

For convenience, `FlintPuiseuxSeriesRingElem` and `FlintPuiseuxSeriesFieldElem` both
belong to a union type called `FlintPuiseuxSeriesElem`.

The maximum relative precision, the string representation of the variable and
the base ring $R$ of a generic power series are stored in the parent object. 

Note that unlike most other Nemo types, Puiseux series are parameterised by the type of
the underlying Laurent series type (which must exist before Nemo can make use of it),
instead of the type of the coefficients.

## Puiseux power series

Puiseux series have their maximum relative precision capped at
some value `prec_max`. This refers to the maximum precision of the underlying Laurent
series. See the description of the generic Puiseux series in AbstractAlgebra.jl for
details.

There are numerous important things to be aware of when working with Puiseux series, or
series in general. Please refer to the documentation of generic Puiseux series and 
series in general in AbstractAlgebra.jl for details.

## Puiseux series functionality

Puiseux series rings in Nemo implement all the same functionality that is available for
AbstractAlgebra series rings, with the exception of the `pol_length` and `polcoeff`
functions:

<https://nemocas.github.io/AbstractAlgebra.jl/stable/series>

In addition, generic Puiseux series are provided by AbstractAlgebra.jl

We list below only the functionality that differs from that described in AbstractAlgebra,
for specific rings provided by Nemo.

### Special functions

```@docs
Base.sqrt(a::FlintPuiseuxSeriesElem{ZZLaurentSeriesRingElem})
```

```@docs
Base.exp(a::FlintPuiseuxSeriesElem{ZZLaurentSeriesRingElem})
```

```@docs
eta_qexp(x::FlintPuiseuxSeriesElem{ZZLaurentSeriesRingElem})
```

**Examples**

```jldoctest
julia> S, z = puiseux_series_ring(ZZ, 30, "z")
(Puiseux series ring in z over ZZ, z + O(z^31))

julia> a = 1 + z + 3z^2 + O(z^5)
1 + z + 3*z^2 + O(z^5)

julia> h = sqrt(a^2)
1 + z + 3*z^2 + O(z^5)

julia> k = eta_qexp(z)
z^(1//24) - z^(25//24) + O(z^(31//24))
```
