module atlant.utils.array;

struct Array(T)
{
    this(size_t length)
    {
        import core.stdc.stdlib: malloc;
        this.length = length;
        if (length > 0)
        {
            this.payload = cast(T*) malloc(T.sizeof * length);
            for (int i = 0; i < length; i++) payload[i] = T.init;
            assert(payload !is null);
        }
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

    T* data()
    {
        return payload;
    }

    size_t size()
    {
        return length;
    }

    private size_t length;
    private T* payload;

    void drop()
    {
        import core.stdc.stdlib: free;
        free(payload);
    }
}
