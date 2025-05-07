module atlant.main;

extern(C) void main()
{
    import atlant.utils.string;
    import core.stdc.stdio;
    String s;
    String.cString(&s, cast(char*) "hello world".ptr);
    printf("%d\n", s.hashOf());

    String s2;
    s2.type = String.Type.cannonic;
    foreach (char x ; "hello world")
    {
        s2.put(x);
    }
    s2.finalize();
    printf("%d\n", s2.hashOf());
}
