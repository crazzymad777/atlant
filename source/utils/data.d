module atlant.utils.data;

struct Data
{
    void* pointer;
    size_t length;

    static Data fromString(string s)
    {
        return Data(cast(void*) s.ptr, s.length);
    }

    // static Data fromDynamicVoid(immutable(void)[] v)
    // {
    //     return Data(cast(void*) v.ptr, v.length);
    // }
}
