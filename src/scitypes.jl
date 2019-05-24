nlevels(c::CategoricalValue) = length(levels(c.pool))
nlevels(c::CategoricalString) = length(levels(c.pool))

abstract type Found end
    struct Unknown <: Found end 
    abstract type Known <: Found end
        abstract type Infinite <: Known end
           struct Continuous <: Infinite end
           struct Count <: Infinite end
        abstract type Finite{N} <: Known end
            struct Multiclass{N} <: Finite{N} end
            struct OrderedFactor{N} <: Finite{N} end

# aliases:
const Other = Unknown # TODO: depreciate:
const Binary = Multiclass{2}

"""
    scitype(x)

Return the scientific type that an object `x` can represent, when
appearing as an element of a table or vector used as input or target
in fitting MLJ models.

    julia> scitype(4.5)
    Continous

    julia> scitype("book")
    Unknown

    julia> using CategoricalArrays
    julia> v = categorical([:m, :f, :f])
    julia> scitype(v[1])
    Multiclass{2}

Note that `scitype` "commutes" with the formation of tuples or arrays,
as these examples illustrate:

```julia
scitype((42, float(π), "Julia"))
```

```julia 
Tuple{Count,Continuous,Unknown}
```

```julia
scitype(rand(7,3))
```

```julia
AbstractArray{Continuous,2}
```

For getting the union of the scitypes of all elements of an iterable,
use `scitype_union`.

""" 
scitype(::Any) = Unknown     
scitype(::Missing) = Missing
scitype(::AbstractFloat) = Continuous
scitype(::Integer) = Count
scitype(c::CategoricalValue) =
    c.pool.ordered ? OrderedFactor{nlevels(c)} : Multiclass{nlevels(c)}
scitype(c::CategoricalString) = 
    c.pool.ordered ? OrderedFactor{nlevels(c)} : Multiclass{nlevels(c)}

scitype(t::Tuple) = Tuple{scitype.(t)...}
MLJBase.scitype(A::B) where {T,N,B<:AbstractArray{T,N}} = AbstractArray{scitype(first(A)),N}


"""
    scitype_union(A)

Return the type union, over all elements `x` generated by the iterable
`A`, of `scitype(x)`.

"""
scitype_union(A) = reduce((a,b)->Union{a,b}, (scitype(el) for el in A))

"""
    scitypes(X)

Returns a named tuple keyed on the column names of the table `X` with
values the corresponding scitype unions over a column's entries.

"""
function scitypes(X)
    container_type(X) in [:table, :sparse] ||
        throw(ArgumentError("Container should be a table or sparse table. "))
    names =    schema(X).names
    return NamedTuple{names}(scitype_union(selectcols(X, c)) for c in names)
end




