module GetindexArrays

export GetindexArray

struct GetindexArray{T,N,F,Axs<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractArray{T,N}
    getindex::F
    axes::Axs
end
GetindexArray{T}(getindex::F, axes) where {T,F} =
    GetindexArray{T, length(axes), F, typeof(axes)}(getindex, axes)
GetindexArray(getindex::F, axes) where F =
    GetindexArray{Base._return_type(getindex, NTuple{length(axes), Int})}(getindex, axes)

Base.@propagate_inbounds function Base.getindex(A::GetindexArray{T,N}, i::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, i...)
    convert(T, A.getindex(i...))::T
end
Base.size(A::GetindexArray) = map(length, A.axes)
Base.axes(A::GetindexArray) = A.axes

end
