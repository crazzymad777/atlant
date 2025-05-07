module atlant.utils.string;

// append
// hashOf
// auto-grow
// equals
// iterating...
// reset, next, take
// use, release

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
    import std.digest.murmurhash;
    MurmurHash3!32 hasher;

    enum Type
    {
        cString,
        cannonic
    };
    bool finalized = false;
    int allocated_length;
    char* data; // one indirection
    int length;
    Type type;
    int index;
    int hash;
    bool computed = false;
    int used = 0;

    void use()
    {
        used++;
    }

    void release()
    {
        used--;
        if (used <= 0)
        {
            if (allocated_length > 0)
            {
                import core.stdc.stdlib;
                free(data);
            }
        }
    }

    static void cString(String* s, char* ptr)
    {
        s.finalized = true;
        s.data = ptr;
        s.type = Type.cString;
        s.computed = false;
    }

    int put(char x)
    {
        assert(finalized == false);
        if (type == Type.cannonic)
        {
            if (index >= allocated_length)
            {
                // reallocate...
                import core.stdc.stdlib;
                int space = allocated_length + 1024;
                data = cast(char*) realloc(data, space);
                assert(data !is null);
                allocated_length = space;
            }
            data[index] = x;
            index++;

            hasher.put(x);
            return index;
        }
        assert(false);
    }

    void finalize()
    {
        assert(finalized == false);
        finalized = true;
        auto hashed = hasher.finish();
        hash = get32bits(&hashed[0]);
        computed = true;
        length = index;
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
        if (type == Type.cannonic)
        {
            assert(finalized == true);
            return hash;
        }

        if (type == Type.cString)
        {
            if (computed)
            {
                return hash;
            }
            hash = compute();
            computed = true;
            return hash;
        }

        assert(false);
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

    bool equals(String* other)
    {
        if (other.hashOf() == hashOf())
        {
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
    s2.finalize();
    assert(s2.hashOf() == 1586663183);
}
