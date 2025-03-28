module atlant.utils.hash;

private uint get32bits()(scope const(ubyte)* x) @nogc nothrow pure @system
{
    version (BigEndian)
    {
        return ((cast(uint) x[0]) << 24) | ((cast(uint) x[1]) << 16) | ((cast(uint) x[2]) << 8) | (cast(uint) x[3]);
    }
    else
    {
        return ((cast(uint) x[3]) << 24) | ((cast(uint) x[2]) << 16) | ((cast(uint) x[1]) << 8) | (cast(uint) x[0]);
    }
}

// uint hashOf(string x)
// {
//     import  std.digest.murmurhash;
//     MurmurHash3!32 hasher;
//     for (int i = 0; i < x.length; i++)
//     {
//         hasher.put(x[i]);
//     }
//     auto hashed = hasher.finish();
//     return get32bits(&hashed[0]);
// }

uint hashOf(bool mandotarySlashTerm = false)(char* szString)
{
    import  std.digest.murmurhash;
    MurmurHash3!32 hasher;
    char* ptr = szString;
    static if (mandotarySlashTerm) char last = '\0';
    while (*ptr != '\0')
    {
        hasher.put(*ptr);
        static if (mandotarySlashTerm) last = *ptr;
        ptr++;
    }

    static if (mandotarySlashTerm)
    {
        if (last != '/')
        {
            hasher.put('/');
        }
    }

    auto hashed = hasher.finish();
    return get32bits(&hashed[0]);
}
