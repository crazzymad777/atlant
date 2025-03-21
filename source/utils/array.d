module atlant.utils.array;

struct Array(T)
{
    this(size_t length)
    {
        import core.stdc.stdlib: malloc;
        this.length = length;
        this.payload = cast(T*) malloc(T.sizeof * length);
        for (int i = 0; i < length; i++) payload[i] = T.init;
        assert(payload !is null);
    }

    ~this()
    {
        import core.stdc.stdlib: free;
        free(payload);
    }

    T at(long index)
    {
        assert(index >= 0 && index < length);
        return payload[index];
    }

    void put(long index, T value)
    {
        assert(index >= 0 && index < length);
        payload[index] = value;
    }

    private size_t length;
    private T* payload;
}
