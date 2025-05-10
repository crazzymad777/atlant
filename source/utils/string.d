module atlant.utils.string;

// append
// hashOf
// auto-grow
// equals
// iterating...
// reset, next, take

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

struct String
{
    // import std.digest.murmurhash;
    // MurmurHash3!32 hasher;

    enum Type
    {
        cString,
        cannonic
    };
    bool sealed = false;
    long allocated_length;
    char* data; // one indirection
    long length = -1;
    Type type = Type.cannonic;
    int index;
    int hash;
    bool computed = false;
    bool detached = false;

    void drop()
    {
        if (allocated_length > 0 && !detached)
        {
            import core.stdc.stdlib;
            free(data);
        }
    }

    void detach()
    {
        detached = true;
    }

    static void cString(String* s, char* ptr)
    {
        import core.stdc.string;
        assert(ptr !is null);

        s.sealed = true;
        s.data = ptr;
        s.type = Type.cString;
        s.computed = false;
        s.length = strlen(ptr);
    }

    static String staticCString(char* ptr)
    {
        import core.stdc.string;
        assert(ptr !is null);
        String s;
        s.sealed = true;
        s.data = ptr;
        s.type = Type.cString;
        s.computed = false;
        s.length = strlen(ptr);
        return s;
    }

    static void cStringAlloc(String* s, long stringLength)
    {
        import core.stdc.stdlib;
        //assert(ptr !is null);

        s.sealed = true;
        s.data = cast(char*) malloc(stringLength + 1);
        s.type = Type.cString;
        s.computed = false;
        s.length = stringLength;
        s.allocated_length = stringLength + 1;
    }

    static void cStringDup(String* s, char* origin)
    {
        import core.stdc.string;
        //assert(ptr !is null);

        s.sealed = true;
        s.data = strdup(origin);
        s.type = Type.cString;
        s.computed = false;
        s.length = strlen(s.data);
        s.allocated_length = s.length + 1;
    }

    int put(char x, int alloc_step = 1024)
    {
        assert(sealed == false);
        if (type == Type.cannonic)
        {
            if (index >= allocated_length)
            {
                // reallocate...
                import core.stdc.stdlib;
                long space = allocated_length + alloc_step;
                data = cast(char*) realloc(data, space);
                assert(data !is null);
                allocated_length = space;
            }
            data[index] = x;
            index++;

            // hasher.put(x);
            return index;
        }
        assert(false);
    }

    void seal()
    {
        assert(sealed == false);
        length = index;
        put('\0');
        sealed = true;
    }

    int compute()
    {
        import std.digest.murmurhash;
        MurmurHash3!32 chasher;
        reset();
        while (hasNext())
        {
            chasher.put(take());
            next();
        }
        auto hashed = chasher.finish();
        return get32bits(&hashed[0]);
    }

    int hashOf()
    {
        if (computed)
        {
            return hash;
        }
        hash = compute();
        length = index;
        computed = true;
        return hash;
    }

    void reset()
    {
        index = 0;
    }

    char take()
    {
        return data[index];
    }

    void next()
    {
        index++;
    }

    bool hasNext()
    {
        if (type == Type.cannonic)
        {
            return index < length;
        }

        if (type == Type.cString)
        {
            return take() != '\0';
        }

        assert(false);
    }

    bool equals(String* other, bool unique = false)
    {
        if (other.hashOf() == hashOf())
        {
            if (unique) return true;

            other.reset();
            reset();

            while (hasNext() && other.hasNext())
            {
                if (take() != other.take)
                {
                    return false;
                }

                other.next();
                next();
            }
            return hasNext() == other.hasNext();
        }
        return false;
    }
}

unittest
{
    String s2;
    s2.type = String.Type.cannonic;
    foreach (char x ; "hello world")
    {
        s2.put(x);
    }
    s2.seal();
    assert(s2.hashOf() == 1586663183);
}

unittest
{
    String s1;
    String.cString(&s1, cast(char*) "hello world".ptr);
    assert(s1.hashOf() == 1586663183);
}
