module atlant.utils.data;

struct Data
{
    static Data fromString(string s)
    {
        return Data(cast(void*) s.ptr, s.length);
    }

    void* pointer;
    size_t length;
}
